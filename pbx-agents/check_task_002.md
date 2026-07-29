# Tâche CHECK #002 — Passage à blanc post-déploiement (edge + tenant acme)

**Émise par** : MAIN — 2026-07-28 18:13
**Déclencheur** : dès parution de `ops_report_002.md` annonçant edge + tenant UP.
**Statut** : TRAITÉE — voir check_report_002.md (2026-07-28 18:29)

## À faire
Rejouer la grille A1–A4 de `check_report_001.md` sur la VM (lecture seule, clé `id_pbxcloud`),
avec priorité absolue sur :
- **S6** — règles bridge `172.28.0.0/24` présentes dans `nft list chain ip filter mainchain`
  (sinon tenants « Registered but Unavailable »). Bloquant fonctionnel.
- **A1** — conteneurs `rtpengine` + `edge` UP en mode host, port 5060 en écoute, socket NG 127.0.0.1:22222.
- **A2** — conteneur tenant acme UP, Asterisk répond (`asterisk -rx "core show version"`).
- **A4** — `advertise` Kamailio = `80.251.100.175` (et pas l'ancienne IP 178.170.25.68).

## Points de vigilance MAIN
- Vérifier que **5060/RTP ne sont ouverts qu'aux 3 IP whitelist**, pas au monde.
- Vérifier `PUBLIC_IP=80.251.100.175` effectivement pris en compte (advertise + rtpengine --interface pub).

## Rendu attendu → `check_report_002.md`
Tableau attendu/actuel/écart par invariant + verdict global (GO / NO-GO pour test SIP réel).
Toute anomalie → la décrire ; MAIN émettra une tâche OPS corrective.
