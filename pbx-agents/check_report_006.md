# Rapport CHECK #006 — Trunk Sewan + non-régression

**Timestamp** : 2026-07-28 21:55
**Tâche** : check_task_006.md
**Agent** : CHECK
**Cible** : 80.251.100.175 (pbx1-procom.dyndns.org)

---

## STATUT

⛔ **NO-GO — SSH inaccessible : impossible d'exécuter les tests.**

Deux constats distincts :
1. **Trunk Sewan** : non activé (conforme — données PENDING selon `ops_report_007.md`)
2. **SSH port 22** : `Connection refused` depuis 217.181.224.153 — **accès VM perdu**

---

## RÉSULTATS

### 1. Trunk Sewan — Statut attendu

Conformément à `ops_report_007.md`, aucun REGISTER vers Sewan n'a été émis.
Les 4 données bloquantes restent PENDING (mot de passe sbc2, plage RTP, SDA, format CLI).
Le design uac Kamailio est prêt (ops_report_006.md) mais l'activation est en attente de MAIN.

→ **Registration trunk : N/A** (non activée, état normal à ce stade).

### 2. Connectivité SSH

| Test | Résultat |
|------|----------|
| Ping 80.251.100.175 | ✓ 3/3 paquets, RTT ~15 ms — VM UP |
| SSH port 22 (clé id_pbxcloud) | ✗ **Connection refused** |
| SSH port 22 (sshpass procom) | ✗ **Connection refused** |
| SSH port 2222, 8022, 1022, 22222 | ✗ Timeout (nftables drop) |

**Interprétation** : `Connection refused` (TCP RST actif) ≠ timeout nftables.
Deux hypothèses :
- a) **sshd est arrêté** (crash ou arrêt volontaire)
- b) **nftables utilise `reject` plutôt que `drop`** pour SSH hors-whitelist,
  et notre IP 217.181.224.153 a été retirée de la whitelist lors des opérations OPS cycle 6/7

La VM est joignable (ping OK) — il ne s'agit pas d'un problème réseau général.

### 3. Non-régression tenants / sécurité

**Non exécutés** — accès SSH requis pour `kamcmd`, logs, nftables. Tests SIP locaux
possibles en théorie mais non significatifs sans pouvoir lire les logs VM.

---

## ANOMALIES

### A1 — CRITIQUE : SSH port 22 Connection refused (BLOQUANT)

**Impact** : CHECK ne peut plus valider quoi que ce soit sur la VM. Toutes les tâches
futures (activation trunk, tests appels, sécurité) sont bloquées.

**Cause probable** : soit sshd arrêté, soit IP 217.181.224.153 retirée de la whitelist
nftables lors des opérations de cycle 6 (ajout règles 5070). Le rapport ops_006 ne
mentionne pas explicitement que la whitelist SSH a été vérifiée après modification.

**Action requise → OPS + MAIN** :
1. Accéder à la VM via console Sewan (hors-bande) pour diagnostiquer
2. Vérifier `systemctl status sshd` et `nft list ruleset | grep -A2 dport.*22`
3. Si nftables : vérifier que `217.181.224.153` est toujours dans la whitelist SSH
4. Si sshd arrêté : `systemctl start sshd`
5. Signaler CHECK dès rétablissement pour exécuter check_task_006 complète

---

## SUITE

**CHECK #006 : EN ATTENTE rétablissement SSH.**

Dès accès rétabli, re-exécution de :
- `kamcmd uac.reg_dump` (ou logs edge) — état registration trunk
- REGISTER 201 + 301 + INVITE 600 acme + beta (non-régression)
- `nft list ruleset` — vérification whitelist 5070 + absence ouverture mondiale
- `fail2ban-client status` — jails actives

**→ MAIN / OPS** : accès console Sewan requis pour débloquer.
