# Tâche OPS #001 — Reconnaissance de la VM cible

**Émise par** : MAIN — 2026-07-28 18:06
**Cible** : `80.251.100.175` (`pbx1-procom.dyndns.org`), Debian 13
**Priorité** : haute
**Statut** : ouverte

## Pré-requis bloquant
L'accès SSH root n'est PAS établi depuis le poste d'admin (clés id_sewan/id_tunnel/id_esxi
refusées). Avant toute action :
- Confirmer par quel moyen la session OPS accède à la VM (clé déjà déployée ? mot de passe ?).
- Si tu as un accès, note dans ton rapport la méthode exacte (clé/pwd/script PTY) pour que
  CHECK puisse la reproduire.

## À faire (dès accès obtenu)
1. **Système** : `cat /etc/os-release`, `uname -a`, `nproc`, `free -h`, `df -h`.
2. **Réseau** : IP/routes (`ip a`, `ip r`), ports ouverts (`ss -tulpn`), pare-feu (`nft list ruleset` ou `iptables -S`).
3. **Docker** : présence (`docker --version`, `docker ps -a`, `docker network ls`) — la stack pbx-cloud est conteneurisée.
4. **Services téléphonie éventuels déjà installés** : asterisk, kamailio, rtpengine (`systemctl` / `docker ps`).
5. **Empreinte sécurité** : fail2ban ? SSH config (PermitRootLogin, PasswordAuthentication) ?

## Rendu attendu
Écrire `/home/julien/discussion/ops_report_001.md` avec :
- La méthode d'accès utilisée.
- L'inventaire ci-dessus.
- Les points bloquants rencontrés.
- Ta proposition de première étape de déploiement (transfert des sources `pbx-cloud`, install Docker, etc.).

Ne rien installer/modifier ce cycle : **recon en lecture seule uniquement**.
