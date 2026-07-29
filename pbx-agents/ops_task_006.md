# Tâche OPS #006 — Déployer le tenant beta

**Émise par** : MAIN — 2026-07-28 20:42
**Base** : tenant acme validé bout-en-bout (check_report_004) + jail SIP posée (ops_report_004)
**Priorité** : haute (scaling multi-tenant)
**Statut** : ouverte

## Objectif
Démarrer le 2ᵉ tenant `beta` (ext 3xx, IP 172.28.0.12) sur la stack existante, sans régression acme.

## À faire
1. `cd ~/pbx-cloud` puis démarrer beta via le flux prévu :
   `docker compose -f docker-compose.yml -f docker-compose.tenants.yml up -d --build tenant-beta`
   (et/ou `tools/new-tenant.sh` si c'est le mécanisme officiel — suivre le README).
2. Vérifier que le mapping Kamailio (`tenants.cfg`) route bien le préfixe **3xx → 172.28.0.12**
   (regénéré par `new-tenant.sh` selon `registry.txt`). Recharger edge si nécessaire (`reload`, pas restart).
3. Contrôles OPS :
   - `docker ps` : `tenant-beta` UP (172.28.0.12), acme + edge + rtpengine toujours UP.
   - `docker exec pbxcloud-tenant-beta-1 asterisk -rx "pjsip show endpoints"` : 301/302 présents.
   - Pas de régression réseau/nftables (mainchain + chaînes Docker intactes, jail SIP toujours active).

## Interdits (inchangés)
- Pas d'ouverture 5060 au monde (whitelist 3 IP), TRUNK_IP=0.0.0.0, ne pas toucher PasswordAuthentication.
- Sauvegarde `.bak` de toute conf éditée ; `reload` plutôt que `restart`.

## Rendu attendu → `ops_report_005.md`
`docker ps` (beta UP), endpoints 301/302, état mapping Kamailio 3xx, confirmation zéro régression acme.
Puis signaler à CHECK pour validation beta + test d'isolation inter-tenant.
