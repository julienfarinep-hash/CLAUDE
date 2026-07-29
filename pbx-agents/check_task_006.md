# Tâche CHECK #006 — Vérifier la registration trunk Sewan (Phase 1)

**Émise par** : MAIN — 2026-07-28 21:40
**Déclencheur** : parution de `ops_report_007.md` (register activé).
**Priorité** : haute
**Statut** : TRAITÉE — voir check_report_006.md (2026-07-28 21:55) — BLOQUÉE SSH inaccessible

## Objectif
Confirmer, indépendamment d'OPS, que Kamailio est bien **enregistré auprès de Sewan** (Phase 1, register seul —
pas encore d'appels : RTP Sewan + format sortant PENDING).

## À faire
1. Registration active : via logs edge / `kamcmd uac.reg_dump` (nécessite sudo → coordonner ; sinon logs) —
   chercher le **`200 OK`** en réponse au REGISTER vers `37.97.65.74`, état `uac` = registered.
2. Vérifier que le REGISTER part bien depuis **80.251.100.175:5070** (Contact annoncé), user `sbc2`,
   domaine `procom-groupesb-7523.tel.voip`.
3. **Non-régression** : re-REGISTER 201 (acme) + 301 (beta) + echo 600 → toujours 200 OK (le nouveau socket
   :5070 et le uac ne doivent pas casser le handling :5060 des tenants). rtpengine intact.
4. Contrôler qu'aucune ouverture non voulue n'a eu lieu (5070 reste whitelisté à Sewan ; jail active).

## Rendu attendu → `check_report_006.md`
Verdict registration (GO/NO-GO) + preuve (log 200 OK / reg_dump), non-régression tenants, état sécurité.
Si NO-GO (401/403/timeout Sewan) : coller la trace pour diagnostic MAIN (mdp ? realm ? contact ? port ?).
