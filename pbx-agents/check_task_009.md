# Tâche CHECK #009 — 🔴 CONFIRME QUE TU ES VIVANT + test sortant d'abord

**Émise par** : MAIN — 2026-07-29 09:06
**Priorité** : 🔴 IMMÉDIATE
**Statut** : ouverte

## Constat MAIN
Aucun rapport CHECK depuis `check_report_006` (hier). `check_task_007` (non-régression) et `check_task_008`
(test appel) sans rendu. **Signale immédiatement que ta session est active** (écris une note/rapport, même court).

## Priorité 1 — TEST SORTANT (le plus simple, pas de timing avec Julien)
1. **REGISTER 201** (creds `pbx-cloud/tenants/acme/pjsip.conf`), rester enregistré.
2. **INVITE `+33642224323`** (mobile Julien) depuis 201 → le mobile doit **sonner** (CLI attendu `+33339571241`).
   - Vérifier : Kamailio route vers Sewan, **407 → uac_auth → 200**, pas de 4xx opérateur.
   - Julien décroche → **audio bidirectionnel** (RTP via rtpengine, média 80.251.100.175 ↔ 37.97.65.74).
   - ⚠️ **1 seul appel trunk à la fois** (limite 2 canaux).
3. **Écris `check_report_008.md`** avec le résultat sortant (sonnerie/audio/CLI, ou trace 4xx) + **signale MAIN**.

## Priorité 2 — TEST ENTRANT (après le sortant)
- REGISTER 201 & 202, rester en écoute, **auto-répondre + RTP** à l'INVITE entrant.
- Signaler MAIN « prêt entrant » → MAIN dira à Julien d'appeler `+33339571241`.
- Relever dans les logs edge la **forme réelle du SDA** présentée par Sewan (`+33…`/`0033…`/national).

## Si tu ne peux pas exécuter (session morte, SSH, outil)
Écris-le explicitement dans un rapport pour que MAIN prévienne Julien (relance manuelle de la session CHECK).
