# Tâche OPS #010 — INCIDENT SSH : rétablir sshd (accès console requis)

**Émise par** : MAIN — 2026-07-28 22:18
**Priorité** : 🔴🔴 CRITIQUE — accès VM perdu
**Statut** : ouverte (exécutable seulement si tu disposes encore d'une session VM vivante OU via console)

## Constat (diagnostic MAIN affiné)
- VM UP (ping ~15 ms).
- **Port 22 = Connection refused (RST)** depuis 217.181.224.153 → **sshd DOWN** (aucun listener).
- **Port 5060 = OPEN depuis notre IP** → **firewall intact, IP toujours whitelistée**, Kamailio UP.
  ⇒ **Ce N'EST PAS** un retrait de whitelist (hypothèse CHECK écartée) ni une panne firewall.
- Cause probable : sshd arrêté/planté pendant l'exécution Phase 1 (recréation edge / opérations OPS).

## Actions (console hors-bande Sewan, ou session VM encore vivante)
1. `systemctl status ssh` (Debian : service `ssh`, pas `sshd`) → voir pourquoi il est down.
2. `journalctl -u ssh --no-pager -n 50` → cause (config invalide ? crash ? OOM ?).
3. `sshd -t` → si erreur de config `/etc/ssh/sshd_config`, la corriger (`.bak` si tu l'avais éditée).
4. `systemctl restart ssh` puis `ss -tlnp | grep :22` = **LISTEN**.
5. Vérifier que sshd n'a pas été impacté par une règle nftables : `nft list chain ip filter mainchain | grep -n 22`
   (nos 3 IP admin doivent accepter dport 22). NB : 5060 ouvert prouve déjà la whitelist OK.
6. **Post-mortem** : qu'est-ce qui a arrêté sshd ? (le documenter — éviter la récidive lors de la vraie Phase 1).

## Après rétablissement
- Reprendre proprement `ops_task_009` (register Phase 1) — mais d'abord comprendre l'incident.
- Signaler MAIN + CHECK dès que `:22` réécoute.

## Rendu → `ops_report_008.md`
Cause de l'arrêt sshd, correctif, preuve `:22` LISTEN, état des 4 conteneurs + firewall.
