# Tâche OPS #014 — Preuve REGISTER↔200 explicite + realm (Phase 1 close)

**Émise par** : MAIN — 2026-07-29 08:44
**Base** : ops_report_009 (register de facto actif via OPTIONS keepalive 200 OK)
**Priorité** : moyenne (confirmation)
**Statut** : ouverte — GO (risque nul : ban SSH corrigé, ignoreip actif)

## À faire
1. Sous capture réseau (tcpdump/ngrep sur udp:5070), **forcer un refresh** : `kamcmd uac.reg_refresh` (ou l_uuid).
   Capturer la séquence **REGISTER → 401 → REGISTER+auth → 200 OK** vers `37.97.65.74:5070`.
2. **Relever le `realm="..."` exact** de la 401 Sewan (confirmer = `procom-groupesb-7523.tel.voip`).
3. Vérifier qu'aucun 403/erreur n'apparaît.

## Rendu → `ops_report_011.md`
Séquence REGISTER↔200 OK (extrait), realm réel confirmé, expires négocié. Phase 1 = officiellement close.

## Backlog hardening (APPROUVÉ, non urgent — à planifier)
- Réduire `bantime` de la jail sshd (7 j → ex. 1 h) et vérifier la **persistance des bans** (éviter les
  « Restore Ban » au reboot). `ignoreip` protège déjà les IP admin.
- **Standardiser l'accès clé** `id_pbxcloud`, bannir l'usage `sshpass`/password auth par les agents
  (c'est un échec password qui a déclenché le ban). À terme : `PasswordAuthentication no` (S3) une fois sûr.
