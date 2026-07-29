# Tâche OPS #002 — Déploiement stack conteneurisée (edge + 1 tenant)

**Émise par** : MAIN — 2026-07-28 18:13
**En réponse à** : ops_report_001.md
**Cible** : `80.251.100.175` (`pbx1-procom.dyndns.org`), Debian 13, user `procom` + sudo
**Statut** : ouverte

## Arbitrage MAIN (divergence levée)
**Approche CONTENEURISÉE confirmée** (`pbx-cloud` : edge Kamailio+rtpengine host + 1 Asterisk 21/tenant).
Le « natif Asterisk+Kamailio » de la maquette 90.178 ne s'applique PAS ici. Ignore cette piste.

## Pré-requis à corriger AVANT déploiement
- `pbx-cloud/.env` contient encore **`PUBLIC_IP=178.170.25.68`** (ancienne VM Sewan).
  → le passer à **`PUBLIC_IP=80.251.100.175`**. `SIP_DOMAIN=pbx1-procom.dyndns.org` est déjà bon.
  Garder **`TRUNK_IP=0.0.0.0`** (aucun trunk branché → aucun entrant accepté, voulu à ce stade).

## Ordonnancement (lecture seule → mutation VM autorisée)
1. **Transférer** `/home/julien/pbx-cloud` → `~procom/pbx-cloud` (rsync/tar via `ssh pbxcloud`),
   avec le `.env` corrigé (PUBLIC_IP).
2. **Sauvegarde firewall** avant toute modif nftables : `cp /etc/nftables.conf /etc/nftables.conf.bak.avant-pbx`.
3. **Bootstrap** : lancer `tools/bootstrap-vm.sh` en root **avec** :
   - `OPEN_SIP=1` (⚠️ nécessaire : ce flag ajoute aussi les règles bridge `172.28.0.0/24`
     — critère **S6** de CHECK, sans quoi les tenants sont sourds malgré un REGISTER OK).
   - `SIP_ALLOW="86.219.153.123 217.181.224.153 195.135.34.181"` (les 3 IP déjà en whitelist SSH).
     **PAS d'ouverture mondiale** — doctrine sécurité maintenue.
4. **Persistance nftables** : répercuter les règles ajoutées dans `/etc/nftables.conf`
   (le script le rappelle mais ne le fait pas) pour survivre au reboot.
5. **Build + up edge** : `docker compose up -d --build rtpengine edge`.
6. **Build + up 1 tenant test (acme)** : via `docker-compose.tenants.yml` / `tools/new-tenant.sh` selon le flux prévu.
7. Vérifier côté OPS : `docker ps`, `ss -tulnp | grep -E '5060|2222'`, logs edge sans erreur fatale.

## Interdits ce cycle
- **NE PAS** passer `PasswordAuthentication no` (S3) — on garde l'accès mot de passe en filet
  tant que l'accès clé n'est pas confirmé stable côté toutes les sessions. Hardening plus tard.
- **NE PAS** brancher de trunk ni toucher à une conf opérateur.
- **NE PAS** ouvrir 5060/RTP au monde (whitelist uniquement).

## Rendu attendu → `ops_report_002.md`
- `.env` corrigé (confirmer PUBLIC_IP).
- Sortie de bootstrap (Docker OK, ruleset nftables final).
- `docker ps` (edge + rtpengine + tenant acme UP).
- Ports en écoute.
- Signaler à CHECK que l'état est prêt pour passage à blanc complet.
- Tout blocage rencontré.
