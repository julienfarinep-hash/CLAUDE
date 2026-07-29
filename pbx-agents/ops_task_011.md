# Tâche OPS #011 — Post-reboot : vérifier l'état + post-mortem sshd (NE PAS retrycler le trunk)

**Émise par** : MAIN — 2026-07-28 22:22
**Déclencheur** : retour SSH après reboot Sewan (déclenché par Julien).
**Priorité** : haute
**Statut** : ❌ CADUQUE (pas de reboot ; incident = ban fail2ban résolu par Julien). Voir ops_task_013.

## Contexte
Julien reboote la VM via le portail Sewan pour rétablir sshd (down après l'exécution Phase 1 trunk).
Au retour, on **valide d'abord l'état sain**, on **cherche la cause** de l'arrêt sshd, et on **NE relance
PAS le register** tant que la cause n'est pas comprise (sinon on risque de re-casser l'accès).

## À faire dès que `:22` réécoute
1. **Post-mortem sshd (PRIORITAIRE, avant que les logs ne tournent)** :
   - `journalctl -u ssh --boot=-1 --no-pager | tail -80` (journal du boot PRÉCÉDENT — si journald persistant).
   - Chercher : arrêt volontaire (`Stopped OpenBSD Secure Shell`), crash, OOM (`journalctl -k --boot=-1 | grep -i oom`),
     ou une commande OPS ayant restart/stoppé ssh/networking pendant la Phase 1.
   - **Conclure** : qu'est-ce qui a tué sshd ? (indispensable avant de rejouer le trunk.)
2. **État sain** :
   - `ss -tlnp | grep :22` = LISTEN ; `systemctl is-enabled ssh` = enabled.
   - `docker ps` : edge + rtpengine + tenant-acme + tenant-beta **UP** (restart policy).
   - `nft list chain ip filter mainchain` : whitelist SSH (3 IP) + 5060 + 5070 Sewan + bridge 172.28 intacts,
     chaînes Docker présentes. `fail2ban-client status` : jails `sshd` + `kamailio-sip` actives.
   - `.env` : TRUNK_IP=37.97.65.74 (inchangé) ; edge tourne SANS le trunk (config d'origine, pas recréé).
3. **NE PAS** relancer le register/trunk ce cycle.

## Rendu → `ops_report_009.md`
Cause de l'arrêt sshd (post-mortem), preuve `:22` LISTEN, 4 conteneurs UP, firewall/jails OK, 2 tenants sains.
→ Ensuite MAIN décidera d'une reprise Phase 1 **sécurisée** (en évitant l'étape fautive) + CHECK non-régression.
