# Tâche OPS #013 — Prévenir le re-ban fail2ban (ignoreip) + vérifier le register

**Émise par** : MAIN — 2026-07-29 (reprise après incident)
**Priorité** : 🔴 HAUTE (faire l'étape 1 AVANT toute activité SSH intensive)
**Statut** : ouverte — GO

## Contexte
Incident SSH résolu par Julien : la jail **fail2ban `sshd`** avait **banni l'IP admin `217.181.224.153`**
(port 22, action reject → RST → « connection refused »). Nos 3 IP admin n'étaient donc **pas en `ignoreip`**.
Risque de récidive dès qu'OPS/CHECK multiplient les connexions/échecs SSH.

## À faire (ordre strict)
### 1. PRÉVENTION — ignoreip (AVANT tout le reste)
- `.bak` de la conf fail2ban concernée. Ajouter en `[DEFAULT]` (jail.local) :
  `ignoreip = 127.0.0.1/8 ::1 86.219.153.123 217.181.224.153 195.135.34.181`
  (les 3 IP admin whitelistées nftables). S'applique à **toutes** les jails (sshd + kamailio-sip).
- `fail2ban-client reload` (pas restart). Vérifier :
  `fail2ban-client get sshd ignoreip` (ou `status sshd`) contient les 3 IP ;
  `fail2ban-client status sshd` → **0 banned** pour notre IP (unban si encore listée : `fail2ban-client set sshd unbanip 217.181.224.153`).
- Confirmer que la jail `sshd` reste **active** (on garde la protection, on ignore juste nos IP admin).

### 2. Post-mortem (preuve)
- `grep 217.181.224.153 /var/log/fail2ban.log | tail -20` → confirmer Ban/heure + jail responsable.
- Noter le déclencheur probable (nb d'échecs auth, source).

### 3. Vérifier le register Sewan (l'edge écoute déjà :5070)
- `kamcmd uac.reg_dump` → état registration (registered / 200 OK) vers `procom-groupesb-7523.tel.voip` (sbc2).
- Logs edge : `docker logs pbxcloud-edge-1 --tail 40 | grep -iE "register|401|403|200|realm"` → capturer le realm
  réel de la 401 Sewan + le résultat (200 = OK, 401/403 = auth à revoir).
- **NE PAS** toucher au trunk/appels au-delà de cette lecture.

## Rendu → `ops_report_010.md`
ignoreip actif (3 IP), notre IP non bannie, jails actives ; post-mortem fail2ban ; **état register** (200 OK ?
sinon trace 401/403 + realm). Puis CHECK non-régression (check_task_007).
