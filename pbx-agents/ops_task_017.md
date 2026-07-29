# Tâche OPS #017 — Correctif sortant : forcer la socket trunk :5070 (fix 482)

**Émise par** : MAIN — 2026-07-29 09:26
**Base** : ops_report_013 (Sewan 482 Request Merged — INVITE sort par :5060/Via 172.28.0.1 ≠ registration :5070)
**Priorité** : 🔴 HAUTE
**Statut** : ouverte — **GO (correctif VALIDÉ par MAIN)**

## Correctif à appliquer
Dans la branche `$var(tip)=="trunk"` de `request_route` (kamailio.cfg), **forcer la socket d'émission publique
:5070** avant `t_relay`, pour que Via/source/Contact soient cohérents avec la registration :
```
$fs = "udp:80.251.100.175:5070";                       # ou force_send_socket(udp:80.251.100.175:5070)
$ru = "sip:" + $rU + "@procom-groupesb-7523.tel.voip";
$du = "sip:37.97.65.74:5070";
t_on_failure("TRUNK_AUTH");
```
- **Vérifier le `Contact:`** de l'INVITE sortant → doit annoncer `80.251.100.175:5070` (réécrire si Kamailio
  laisse un Contact tenant/`:5060`).
- Idem sur le ré-INVITE authentifié (failure_route uac_auth) : la socket forcée doit rester `:5070`.

## Application
- `.bak.avant-fix482` de kamailio.cfg. **`kamailio -c` OK** → rebuild/recréer edge. Register doit rester actif
  (`uac.reg_dump`), 4 conteneurs UP, non-régression tenants.

## Re-test sortant (méthode originate, sans mobile d'abord)
- Rejouer `channel originate PJSIP/+33642224323@edge-trunk` sous `tcpdump host 37.97.65.74`.
- **Cible : Sewan répond `200 OK` (plus de 482)**, l'appel s'établit. Vérifier Via/source/Contact = `:5070`.
- **Si 200 OK** → refaire un **vrai appel 201 → +33642224323** (mobile Julien) pour valider **sonnerie + audio bidirectionnel**.
- **Si 482 persiste** → vérifier CSeq/branche du ré-INVITE authentifié (uac_auth doit incrémenter le CSeq) + capturer.

## Rendu → `ops_report_014.md`
Réponse Sewan après fix (200 OK ?), extrait Via/Contact/source = :5070, état appel, register OK, 0 régression.
Puis coordonner avec MAIN/CHECK le test mobile réel (sonnerie+audio) + enchaîner l'ENTRANT.
