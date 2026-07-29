# Rapport OPS #013 — Diagnostic appel sortant (mobile ne sonne pas)

**En réponse à** : `ops_task_016.md`
**Rédigé par** : OPS — 2026-07-29 09:25
**Cible** : `80.251.100.175` — appel `201 → +33642224323`

---

## STATUT
🔎 **Localisé. L'appel MEURT en couche B, côté opérateur : Sewan répond `482 Request Merged`**
à l'INVITE authentifié. Couche A (Asterisk) et le routage/auth Kamailio fonctionnent.
**Diagnostic rendu — aucun correctif appliqué** (conforme). Hypothèse de fix ci-dessous, à valider MAIN.

> Méthode : au lieu de remobiliser CHECK/le mobile, j'ai **auto-originé** l'appel depuis acme
> (`channel originate PJSIP/+33642224323@edge-trunk ...`) sous `tcpdump` — même chemin sortant,
> trace complète obtenue sans téléphone.

## TRACE (capture bridge + trunk)
```
acme 172.28.0.11:5060 → edge 172.28.0.1:5060   INVITE sip:+33642224323@172.28.0.1     (A→B OK)
edge → acme                                    100 Trying
edge 80.251.100.175:5060 → Sewan 37.97.65.74:5070  INVITE sip:+33642224323@procom-groupesb-7523.tel.voip
Sewan → edge                                   407 Proxy Authentication Required        (challenge OK)
edge → Sewan                                   ACK
edge → Sewan                                   INVITE (avec Proxy-Authorization)         (uac_auth OK)
Sewan → edge                                   482 Request Merged                        ← ÉCHEC ICI
edge → Sewan                                   ACK
edge → acme                                    482 Request Merged
acme                                           « Everyone is busy/congested » → Hangup
```
Couche A confirmée OK : dialplan `_+33X.` matche, `Set(CALLERID(num)=+33339571241)`, `Dial(...@edge-trunk)` part.

## CAUSE PROBABLE (à valider)
**L'INVITE sortant vers Sewan n'utilise PAS la socket trunk enregistrée `80.251.100.175:5070`.**
Preuves dans la capture de l'INVITE sortant :
- **Top `Via: SIP/2.0/UDP 172.28.0.1`** → adresse **privée du bridge**, pas l'adresse publique du trunk.
- Le paquet **égresse depuis `:5060` (socket pub)**, alors que la **registration a un Contact `80.251.100.175:5070`**.
- Incohérence source/Via/Contact ≠ binding enregistré (`:5070`) ⇒ Sewan corrèle mal la requête
  authentifiée et renvoie **482 Request Merged** (requête vue comme dupliquée/forkée).

En clair : Kamailio relaie l'INVITE trunk **par la mauvaise patte** (celle par laquelle l'INVITE est
entré depuis le tenant, 172.28.0.1), au lieu de forcer la patte publique du trunk `:5070`.

## CORRECTIF PROPOSÉ (NE PAS appliquer sans feu vert MAIN)
Dans la branche `trunk` de `request_route` (kamailio.cfg), **forcer la socket d'émission trunk** avant `t_relay` :
```
if ($var(tip) == "trunk") {
    $fs = "udp:80.251.100.175:5070";          # force_send_socket -> Via/Contact/src = :5070
    $ru = "sip:" + $rU + "@procom-groupesb-7523.tel.voip";
    $du = "sip:37.97.65.74:5070";
    t_on_failure("TRUNK_AUTH");
}
```
(équivalent `force_send_socket(udp:80.251.100.175:5070)`.) But: Via + source + Contact cohérents avec la
registration `:5070` → supprime le 482.
- **Vérif complémentaire à faire au test** : le `Contact:` de l'INVITE (doit annoncer `:5070`) ; si Kamailio
  laisse un Contact tenant, ajouter une réécriture Contact.
- **Si le 482 persiste après la socket** : investiguer le CSeq/branche de l'INVITE ré-authentifié
  (uac_auth doit incrémenter le CSeq ; sinon Sewan voit un merge). À confirmer par capture ciblée.

## NOTES
- Le `From:` observé était `Anonymous` **uniquement** parce que mon `originate` court-circuite le dialplan ;
  un vrai appel via `_+33X.` pose bien `CALLERID(num)=+33339571241`. Ce n'est pas la cause du 482.
- Aucune régression introduite (diagnostic en lecture + originate de test ; configs inchangées).
  Register trunk toujours actif, 4 conteneurs UP.

## SUITE
- **→ MAIN** : valider le correctif `force_send_socket :5070`. Sur accord, je l'applique (`.bak`, `kamailio -c`,
  recréation edge), puis re-test sortant sous capture (viser `200 OK` / ring mobile) + noter la forme SDA
  entrante au passage.

**Tâche `ops_task_016.md` : TRAITÉE (diagnostic rendu, correctif en attente de validation).**
