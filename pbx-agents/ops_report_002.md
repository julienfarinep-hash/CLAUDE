# Rapport OPS #002 — Déploiement stack conteneurisée (edge + tenant acme)

**En réponse à** : `ops_task_002.md`
**Rédigé par** : OPS — 2026-07-28 18:35
**Cible** : `80.251.100.175` (`pbx1-procom.dyndns.org`), Debian 13, user `procom`+sudo

---

## STATUT
✅ **DÉPLOIEMENT RÉUSSI. Stack edge + 1 tenant (acme) opérationnelle.**
Les 3 conteneurs tournent, Kamailio écoute sur l'IP publique, Asterisk 21 répond, rtpengine
est relié. **Prêt pour le passage à blanc complet de CHECK (invariants A1→A4).**
2 incidents rencontrés en cours de route (dont 1 auto-infligé), **tous deux résolus** — détaillés
en PROBLEMES car pertinents pour la reproductibilité et le boot.

## ACTIONS
1. **`.env` corrigé** : `PUBLIC_IP=80.251.100.175` (confirmé côté VM), `SIP_DOMAIN=pbx1-procom.dyndns.org`,
   `TRUNK_IP=0.0.0.0` conservé (aucun entrant tant qu'aucun trunk). Transféré par tar-pipe
   (rsync absent sur la VM) → `~procom/pbx-cloud`.
2. **Sauvegarde firewall** : `/etc/nftables.conf.bak.avant-pbx` créée avant toute modif.
3. **Bootstrap** `tools/bootstrap-vm.sh` en root avec `OPEN_SIP=1` +
   `SIP_ALLOW="86.219.153.123 217.181.224.153 195.135.34.181"` :
   - Docker **29.6.2** + compose plugin installés.
   - Règles nftables ajoutées : 5060 udp/tcp + RTP 30000-30999 udp pour les **3 IP whitelistées**,
     **PAS d'ouverture mondiale**.
   - **Règles bridge S6** `172.28.0.0/24 → host` (5060 + RTP) ajoutées — critère CHECK S6 satisfait.
4. **Persistance nftables** dans `/etc/nftables.conf` (voir PROBLEMES #1 pour la méthode finale, sûre).
5. **Build + up edge** : images `pbxcloud/rtpengine` (compilée depuis git, 150 MB) et
   `pbxcloud/kamailio` (5.8 depuis dépôt Kamailio, 245 MB). `docker compose up -d --build rtpengine edge`.
6. **Build + up tenant acme** : image partagée `pbxcloud/asterisk` (Asterisk **21.12.3** compilée, 471 MB),
   conteneur `pbxcloud-tenant-acme-1` sur `172.28.0.11`. (beta NON démarré, conforme à la demande « 1 tenant ».)
7. **Vérifications** ci-dessous.

## ÉTAT VÉRIFIÉ (rendu attendu)

### docker ps
```
pbxcloud-tenant-acme-1 | pbxcloud/asterisk | Up
pbxcloud-edge-1        | pbxcloud/kamailio | Up
pbxcloud-rtpengine-1   | pbxcloud/rtpengine| Up
```

### Ports en écoute (hôte)
| Socket | Service | Rôle |
|--------|---------|------|
| `80.251.100.175:5060` udp+tcp | kamailio | signalisation publique |
| `172.28.0.1:5060` udp | kamailio | interface interne vers tenants |
| `127.0.0.1:22222` udp | rtpengine | socket de contrôle NG |
| RTP 30000-30999 udp | rtpengine | média (ouvert firewall pour 3 IP) |

### Tenant Asterisk
- `pbxcloud-tenant-acme-1` @ **172.28.0.11**, Asterisk **21.12.3**, transport-udp `0.0.0.0:5060`.
- Endpoints PJSIP **201, 202** présents, état `Unavailable` (**normal** : aucun UA enregistré encore).
- Log Kamailio : `rtpengine instance <udp:127.0.0.1:22222> found, support for it enabled`.

### DNS / réseau
- `pbx1-procom.dyndns.org` → **80.251.100.175** ✅
- Réseau `pbxcloud_pbxnet` **172.28.0.0/24**, gw **172.28.0.1** (bridge `br-8c68c358889c` sur l'hôte).

### Firewall (persisté, reboot-safe)
- 18 règles `accept` dans `mainchain` (établi/lo/icmp + 3 SSH + 9 SIP/RTP + 3 bridge).
- Docker et nftables cohabitent proprement (voir PROBLEMES #1).

### Sécurité
- fail2ban actif, 1 jail (`sshd`). **Jail SIP non encore posée** (différée, conforme au plan CHECK S2 — à faire quand on exposera plus largement).
- `PasswordAuthentication` laissé à `yes` (interdit S3 respecté : pas de hardening ce cycle).
- Disque : 5,3 G utilisés / 59 G libres.

## PROBLEMES (2 incidents, résolus)

### #1 — [AUTO-INFLIGÉ, résolu] Persistance nftables a cassé le réseau Docker
- **Cause** : ma 1ʳᵉ tentative de persistance a fait `flush ruleset` / `delete table ip filter`.
  Or sur cette VM Docker utilise **`iptables-nft`** : ses chaînes (`FORWARD`, `DOCKER`, `DOCKER-USER`…)
  vivent **dans la même `table ip filter`** que notre `mainchain`. Le flush a donc effacé les règles
  Docker → les conteneurs ont perdu Internet → **le 1ᵉʳ build edge a échoué** (apt ne résolvait plus rien).
- **Correctif** : (a) `systemctl restart docker` pour que Docker réinstalle ses chaînes ;
  (b) `/etc/nftables.conf` **réécrit pour ne gérer QUE `mainchain`** (`add table`/`add chain` idempotents
  + `flush chain mainchain` uniquement), sans jamais toucher la table entière. Validé `nft -c`, appliqué (rc=0),
  Docker + conteneurs OK après coup. **Reboot-safe quel que soit l'ordre** nftables/docker.
- **À retenir (piège nouveau, absent de la maquette 90.178)** : ne jamais `flush ruleset` ni
  `delete table ip filter` sur une VM où Docker est en iptables-nft. Backup d'origine conservé.

### #2 — [résolu] Kamailio ne démarrait pas (bind 172.28.0.1 impossible)
- **Cause** : `docker compose up rtpengine edge` (services en `network_mode: host`) **ne crée pas**
  le réseau `pbxnet` — donc l'interface `172.28.0.1` n'existait pas, et Kamailio bouclait en
  `Restarting (255)` sur `bind(172.28.0.1:5060): Cannot assign requested address`.
- **Correctif** : démarrage du tenant acme via `-f docker-compose.yml -f docker-compose.tenants.yml`
  → création de `pbxnet` (gw 172.28.0.1 sur l'hôte) → `docker restart pbxcloud-edge-1` → Kamailio
  bind OK sur pub + int. **Recommandation** : au prochain déploiement, créer le tenant (ou le réseau)
  **avant** l'edge, ou ajouter `docker network create` en amont.

> Note bénigne : log Kamailio `could not get TCP protocol number` (getprotobyname en conteneur) —
> sans impact, le TCP 5060 public est bien en écoute.

## SUITE
- **→ CHECK** : l'état est **prêt pour le passage à blanc complet** (A1 conteneurs, A2 tenant,
  A3 signalisation, A4 DNS). Les tests A5 (REGISTER/INVITE depuis un UA externe) nécessitent un
  softphone depuis l'une des 3 IP whitelistées — à cadrer avec MAIN si on veut les jouer.
- **Différé (non demandé ce cycle)** : jail fail2ban SIP (S2), éventuel 2ᵉ tenant (beta), branchement trunk.
- **Point de vigilance boot** : `/etc/nftables.conf` est désormais non destructif ; au reboot,
  vérifier tout de même que `pbxnet` remonte et que Kamailio bind (dépend de l'ordre docker/réseau).
  Les conteneurs sont en `restart: unless-stopped`.

**Tâche `ops_task_002.md` : TRAITÉE.**
