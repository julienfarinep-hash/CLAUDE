# Rapport OPS #014 — Fix socket :5070 appliqué ; 482 persiste = CSeq non incrémenté (auth retry)

**En réponse à** : `ops_task_017.md` (via canal **GitHub**)
**Rédigé par** : OPS — 2026-07-29 15:0x
**Cible** : `80.251.100.175` — appel sortant `→ +33642224323`

---

## STATUT
🟠 **Fix socket appliqué et EFFICACE sur son point (Via/source = `:5070`), MAIS le `482 Request Merged`
PERSISTE.** Cause désormais **confirmée par capture** : `uac_auth()` renvoie l'INVITE authentifié **avec le
MÊME CSeq** que l'original (nouveau branch seulement) ⇒ Sewan le voit comme requête *mergée*. **Aucun
correctif supplémentaire appliqué** (je rends le diag à MAIN avant, comme convenu). Register OK, 0 régression.

## CE QUI A ÉTÉ FAIT (ops_task_017)
- `.bak.avant-fix482` de `kamailio.cfg`.
- Ajout `force_send_socket` : `$fs = "udp:80.251.100.175:5070"` dans la branche `trunk` de `request_route`
  **et** dans `failure_route[TRUNK_AUTH]` (après `uac_auth()`).
- **`kamailio -c` = "config file ok"** → rebuild image edge + recréation. Register re-actif (`uac.reg_dump`,
  diff_expires frais), 4 conteneurs UP.

## RÉSULTAT — le fix socket marche, mais insuffisant
Re-test `channel originate PJSIP/+33642224323@edge-trunk` sous tcpdump :
- ✅ **Via top = `SIP/2.0/UDP 80.251.100.175:5070`** (avant : `172.28.0.1` privé) ; **source = `:5070`**,
  Sewan répond sur `:5070`. Le point diagnostiqué au cycle précédent est corrigé.
- ❌ Séquence : `INVITE → 407 → INVITE(auth) → **482 Request merged**`.

## CAUSE RACINE CONFIRMÉE (capture)
Les DEUX INVITE sortants portent le **même `CSeq: 9534 INVITE`** :
```
INVITE #1  Via ...branch=z9hG4bKc278.<x>.0     CSeq: 9534 INVITE
   <- 407 Proxy Authentication Required
INVITE #2  Via ...branch=z9hG4bKc278.<x>.1     CSeq: 9534 INVITE   + Proxy-Authorization: Digest username="sbc2" ...
   <- 482 Request merged
```
`uac_auth()` + `t_relay()` en `failure_route` **ajoute une nouvelle branche à la MÊME transaction** (suffixe
`.0`→`.1`) **sans incrémenter le CSeq**. Or RFC 3261 §8.2.2.2 : même Call-ID + From-tag + **CSeq**, branch
différent ⇒ le UAS (Sewan) déclare **482 Merged Request**. C'est exactement notre cas.

## CORRECTIFS PROPOSÉS (à valider MAIN — je n'applique pas à l'aveugle)
**Option B — RECOMMANDÉE (fiable, standard)** : déplacer l'auth du trunk **côté Asterisk**.
- Sur acme, ajouter un `type=auth` (sbc2 / mdp Sewan) et `outbound_auth` sur l'endpoint `edge-trunk`.
- Kamailio **ne fait plus** `uac_auth` sur l'INVITE : il **relaie le 407 vers Asterisk**, qui ré-INVITE
  **avec un CSeq correctement incrémenté** (Asterisk gère ça nativement en UAC). → plus de 482.
- Contrepartie : le mdp Sewan est aussi dans acme (par tenant utilisant le trunk). Acceptable ici.

**Option A — Kamailio incrémente le CSeq** avant la ré-émission (garde les creds centralisés côté edge).
- Nécessite de forcer un **nouveau CSeq** sur le ré-INVITE (Kamailio ne le fait pas via `t_relay` en
  failure_route). Plus délicat (manip d'en-tête CSeq / envoi en nouvelle transaction). À creuser si on veut
  garder l'auth 100 % côté edge (mutualisation multi-tenant).

> Le `force_send_socket :5070` reste **nécessaire et correct** quelle que soit l'option retenue : je le laisse en place.

## NON-RÉGRESSION
- 4 conteneurs UP, register Sewan actif, jails `sshd`+`kamailio-sip` actives, tenants acme/beta intacts.
- Limite 2 canaux respectée (originate unique à la fois). Diagnostic en lecture + originate de test.

## SUITE
- **→ MAIN** : trancher Option B (reco) vs A. Sur accord :
  - B : j'ajoute `auth`+`outbound_auth` sur `edge-trunk` (acme), je retire/neutralise le `uac_auth` INVITE
    dans Kamailio (garde le register uac + le socket :5070), rebuild/reload, re-test → viser **200 OK**.
- Ensuite : vrai appel mobile `201 → +33642224323` (sonnerie + audio), puis test **entrant** (SDA → 201&202).

**Tâche `ops_task_017.md` : socket appliqué ; 482 diagnostiqué (CSeq) — correctif final en attente d'arbitrage MAIN.**
