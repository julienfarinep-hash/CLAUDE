# Rapport OPS #010 — ignoreip fail2ban + post-mortem + état register

**En réponse à** : `ops_task_013.md` (`ops_task_012` = CADUQUE, incident résolu)
**Rédigé par** : OPS — 2026-07-29 08:48
**Cible** : `80.251.100.175`

---

## STATUT
✅ Les 3 étapes de la tâche 013 sont **faites** (l'étape 1 ignoreip avait déjà été appliquée en
cycle #9, cf. ops_report_009). Récapitulatif avec preuves ci-dessous.

## 1. PRÉVENTION — ignoreip (fait)
- `/etc/fail2ban/jail.d/00-ignoreip-admin.local` → `[DEFAULT] ignoreip = 127.0.0.1/8 ::1
  86.219.153.123 217.181.224.153 195.135.34.181` (s'applique à **toutes** les jails).
- `fail2ban-client reload` (pas restart). Vérifs :
  - `fail2ban-client get sshd ignoreip` → contient les **3 IP admin** (+ loopback).
  - `fail2ban-client status sshd` → **0 banned**, IP admin débannie.
  - Jails **`sshd` + `kamailio-sip` toujours ACTIVES** (protection conservée, seules nos IP ignorées).

## 2. POST-MORTEM (preuve `/var/log/fail2ban.log`)
```
22:15:43  [sshd] Ban 217.181.224.153          <- après 2 "Failed password for procom" à 22:15:35/40
22:25:23  [sshd] Unban        (reboot #1)
22:25:36  [sshd] Restore Ban  (fail2ban rebannit au démarrage — ban persistant)
22:31:44  [sshd] Unban        (reboot #2)
22:31:57  [sshd] Restore Ban
08:28:42  [sshd] Unban        (déban manuel Julien ce matin)
```
- **Déclencheur** : échecs d'auth **par mot de passe** depuis `217.181.224.153` (maxretry=5 sur findtime=1 j,
  cumulant les tentatives échouées de la journée : mauvaises clés / login root / `sshpass` mdp erroné).
- **Jail responsable** : `sshd` (action reject → RST → « connection refused »), **bantime 7 j persistant**.
- **sshd n'a jamais planté** (SIGTERM au reboot uniquement), aucun OOM. Détails complets en ops_report_009.

## 3. ÉTAT REGISTER Sewan (lecture)
- `kamcmd uac.reg_dump` : enregistrement chargé (sbc2 / `procom-groupesb-7523.tel.voip`,
  `auth_proxy=sip:37.97.65.74:5070`, `contact_addr=80.251.100.175:5070`, timers actifs).
- **Registration CONFIRMÉE 200 OK** (séquence complète capturée — détail + realm dans `ops_report_011`).
- Aucun 401/403 résiduel, aucune erreur.

## SUITE
- Backlog hardening (approuvé MAIN, non urgent) : réduire `bantime` sshd (7 j → 1 h), régler la
  **persistance des bans**, standardiser l'accès clé `id_pbxcloud` (proscrire password/`sshpass`).
- → CHECK non-régression (check_task_007) : 4 conteneurs UP, jails actives, ignoreip en place.

**Tâche `ops_task_013.md` : TRAITÉE.**
