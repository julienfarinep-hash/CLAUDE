# Rapport CHECK #009 — Test sortant (statut intermédiaire)

**Timestamp** : 2026-07-29 15:1x
**Tâches** : check_task_009.md + check_task_010.md
**Agent** : CHECK
**Cible** : 80.251.100.175 — sortant 201 → +33642224323

---

## STATUT

🟠 **BLOQUÉ — sortant toujours KO (482 Request Merged, nouvelle cause confirmée par OPS).**

CHECK est en ligne (bascule GitHub confirmée — check_ready_github.md).
Non-régression complète (check_report_007 : GO).
Le test sortant réel est en attente du correctif OPS (Option B — auth Asterisk side).

---

## SITUATION

Voir `ops_report_014.md` pour la trace complète. En résumé :

1. **Fix socket `:5070`** (ops_task_017) : appliqué et **EFFICACE** — Via/source de l'INVITE sort désormais
   depuis `80.251.100.175:5070` ✓. Ce point n'est plus la cause.

2. **Nouvelle cause confirmée (capture OPS)** : `uac_auth()` en `failure_route[TRUNK_AUTH]` envoie le
   ré-INVITE authentifié avec le **même CSeq** que l'INVITE original (nouvelle branche, CSeq identique).
   Sewan interprète cela comme une requête mergée → **482 Request Merged** persiste.

3. **Option B recommandée par OPS** (auth côté Asterisk) : ajouter `type=auth` + `outbound_auth` sur
   l'endpoint `edge-trunk` dans `acme/pjsip.conf`. Asterisk gère nativement l'incrémentation du CSeq lors
   du retry 407 → plus de 482. **En attente de validation MAIN.**

---

## CE QUE CHECK A VÉRIFIÉ

- Session SSH active ✓
- 4 conteneurs UP ✓
- Register Sewan flags=20 (actif) ✓
- Non-régression acme + beta ✓
- Fix socket `:5070` visible dans kamailio.cfg (lignes `$fs = "udp:80.251.100.175:5070"`) ✓

CHECK **n'a pas rejoué l'INVITE sortant** (inutile avant le fix CSeq — même résultat 482 attendu ;
priorité = ne pas brûler les 2 canaux trunk pour rien).

---

## SUITE

Dès que MAIN valide Option B et qu'OPS livre `ops_report_015` (fix appliqué, `originate` → **200 OK**) :
1. CHECK REGISTER 201 → reste enregistré.
2. CHECK INVITE `+33642224323` depuis 201 → relève code SIP reçu côté 201 (183/200 = sonnerie ; 4xx = erreur).
3. Julien décroche → vérification audio bidirectionnel (RTP rtpengine).
4. Rapport `check_report_010.md` (résultat sortant réel).
5. Puis test entrant (SDA → 201&202).

Limite 2 canaux respectée. Tests séquentiels.

**check_task_009 + check_task_010 : EN ATTENTE fix CSeq (MAIN/OPS).**
