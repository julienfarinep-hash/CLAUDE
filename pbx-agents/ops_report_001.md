# Rapport OPS #001 — Reconnaissance VM cible

**En réponse à** : `ops_task_001.md`
**Rédigé par** : OPS — 2026-07-28 18:10
**Cible** : `80.251.100.175` (`pbx1-procom.dyndns.org`)

---

## STATUT
✅ **Recon terminée. Accès VM établi et stable.** Le blocage « accès SSH » signalé par MAIN
est **levé** : la cause était un essai de login **root** (désactivé par politique), pas un
problème de clé/mot de passe. L'accès se fait par l'utilisateur **`procom`** (membre du groupe
`sudo`), et non par root.

## Méthode d'accès (reproductible pour CHECK)
- **Utilisateur** : `procom` (PAS `root` — `PermitRootLogin no` sur la VM).
- **Auth initiale** : mot de passe (connu de la session, non retranscrit ici) via `sshpass`
  — **`sshpass` fonctionne** sur cette VM cloud (contrairement au contexte ESXi/90.178 où le
  script PTY Python était requis ; ne pas généraliser l'ancien piège à cette cible).
- **Auth pérenne mise en place** : clé dédiée générée `~/.ssh/id_pbxcloud` (ed25519) et
  déposée dans `~procom/.ssh/authorized_keys`. Alias SSH ajouté → `ssh pbxcloud`.
- **sudo** : disponible pour `procom` **avec mot de passe** (pas de NOPASSWD). Utiliser
  `echo <pwd> | sudo -S <cmd>`.
- CHECK peut reproduire soit avec le mot de passe + `procom`, soit en réutilisant
  `~/.ssh/id_pbxcloud` (même poste d'admin).

> Le poste d'admin (IP publique de Julien) fait partie de la liste blanche nftables SSH de la
> VM — c'est pourquoi la connexion passe. Depuis une autre IP, le port 22 est injoignable.

## ACTIONS (ce cycle — recon lecture seule + mise en place accès)
1. Vérifié joignabilité : ping ~15 ms, port 22 ouvert.
2. Établi et stabilisé l'accès `procom` (clé `id_pbxcloud` + alias `pbxcloud`).
3. Inventaire complet réalisé (ci-dessous).

## INVENTAIRE

### Système
| Élément | Valeur |
|---------|--------|
| OS | Debian GNU/Linux 13 (trixie) |
| Kernel | 6.12.90+deb13-amd64 |
| CPU | 4 vCPU |
| RAM | 7,8 Gi (420 Mi utilisés) |
| Disque `/` | 67 G total, 2 G utilisés, 63 G libres (LVM `debian--vg-root`) |

### Réseau
- Interface `ens192` : `80.251.100.175/24`
- Route par défaut : `via 80.251.100.1 dev ens192`
- **Ports en écoute** : **uniquement `sshd` (22)** en TCP (IPv4 + IPv6). Rien d'autre.

### Pare-feu (nftables — DÉJÀ CONFIGURÉ)
- `table ip filter` / chain `mainchain` hook input **policy DROP**.
- Accepte : `ct state established,related`, `lo`, `icmp`.
- SSH (`tcp dport 22`) **autorisé depuis 3 IP seulement** :
  `86.219.153.123`, `217.181.224.153`, `195.135.34.181`.
- `table ip6 filter` : policy DROP, lo + established + icm6 uniquement.
- **Aucun port SIP/RTP ouvert.** Il faudra ajouter des règles (idéalement IP-whitelist,
  conformément à la doctrine sécurité de la maquette 90.178).

### Docker
- **Absent** (`docker: command not found`). À installer pour la stack `pbx-cloud`
  (tenants Asterisk conteneurisés).

### Services téléphonie
- **Aucun** : ni asterisk, ni kamailio, ni rtpengine, ni mariadb (paquets absents, aucun binaire).

### Sécurité / empreinte
| Point | État |
|-------|------|
| `fail2ban` | actif — 1 jail : `sshd` |
| `ntpsec` | actif — **`NTPSynchronized=yes`** (NTP déjà fonctionnel, TZ Europe/Paris) |
| `nftables` | actif, ruleset restrictif (voir ci-dessus) |
| SSH `PermitRootLogin` | **no** |
| SSH `PasswordAuthentication` | yes |
| SSH `PubkeyAuthentication` | yes |
| SSH `KbdInteractiveAuthentication` | no |

## PROBLEMES
- **Aucun blocage résiduel.** Le « blocage accès root » de MAIN était un faux positif :
  root est volontairement désactivé, l'accès normal est `procom`+sudo.
- Point d'attention : le pare-feu étant en **default-drop avec whitelist SSH par IP**,
  toute ouverture future de ports (SIP 5060, RTP, provisioning) devra être faite
  explicitement en nftables, et l'IP du poste d'admin/des postes SIP ajoutée à la whitelist
  (rappel du piège fail2ban/whitelist de la maquette 90.178).

## SUITE — proposition de première étape de déploiement
La stack locale `/home/julien/pbx-cloud` est **conteneurisée** (docker-compose) :
- `edge/` : Kamailio + rtpengine (compose `docker-compose.yml`) — front de la VM.
- `tenant/` : `Dockerfile` (Asterisk 21, compilé) + `tenants/{acme,beta}` (1 conteneur/client).
- `.env`, `README.md`, `tools/`.

Proposition d'ordonnancement (à valider par MAIN via `ops_task_002.md`) :
1. **Installer Docker CE + compose plugin** sur la VM (base du déploiement).
2. **Transférer les sources** `pbx-cloud` (rsync/tar via `ssh pbxcloud`) vers `~procom/pbx-cloud`.
3. **NTP** : déjà OK (ntpsec synchronisé) — juste valider les serveurs/`timedatectl`, rien à compiler.
4. **Pare-feu** : préparer le jeu de règles nftables pour Kamailio (5060 UDP/TCP) + plage RTP
   rtpengine, en **whitelist IP** au départ (pas d'ouverture mondiale — cf. doctrine sécurité).
5. **Build/up edge** (Kamailio+rtpengine host/conteneur) puis **1 tenant** de test (acme).
6. `fail2ban` : ajouter jails SIP une fois Kamailio exposé.

> Divergence à trancher côté MAIN : mon rôle mentionne « compilation Asterisk+Kamailio »
> (approche native façon 90.178) alors que les sources `pbx-cloud` sont **conteneurisées**
> (Asterisk compilé DANS le Dockerfile). Je pars par défaut sur l'approche conteneurisée
> `pbx-cloud` (edge + tenants) sauf consigne contraire.

**En attente de `ops_task_002.md`.** Rien installé/modifié côté services ce cycle
(seule modif : dépôt de ma clé publique dans `authorized_keys` de `procom` pour stabiliser l'accès).
