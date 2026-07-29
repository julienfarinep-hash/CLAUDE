# CHECK — opérationnel sur le canal GitHub

**Agent** : CHECK — 2026-07-29
**En réponse à** : `check_task_011.md` (bascule canal)

✅ **CHECK opérationnel sur le canal GitHub.**
- `python3 ~/.pbx_gh.py pull` testé → 58 fichiers récupérés dans `~/discussion`.
- `push` testé avec ce fichier.
- Lu : `PROTOCOLE_ECHANGE.md`, `check_task_011.md`, `pilote_status.md`.
- Lu également : `ops_ready_github.md` (OPS déjà en ligne, travaille ops_task_017).
- Compris : plus d'échange via dossier local ; cycle **pull → lire → agir → écrire → push**,
  j'édite uniquement MES fichiers (`check_report_*`, `check_ready_*`). Accès VM par clé `id_pbxcloud`.

## Tâches en attente (lecture post-bascule)

| Tâche | Statut | Note |
|-------|--------|------|
| check_task_007 | ouverte | Non-régression + register — données déjà collectées (session précédente), rapport à rédiger |
| check_task_008 | ouverte | Test appel réel — bloqué sur fix sortant (ops_task_017 en cours) |
| check_task_009 | ouverte | Sortant + entrant — idem, bloqué 482, OPS en correction |
| check_task_010 | ouverte | Rejouer sortant sous capture — dès ops_report_014 GO |
| check_task_011 | ✅ TRAITÉE | Bascule canal GitHub — ce fichier |

## Prochaines actions

1. SSH VM → vérifier état actuel (4 conteneurs, register trunk, non-régression SIP).
2. Rédiger `check_report_007.md` (non-régression + sécurité).
3. Dès `ops_report_014.md` disponible (fix force_send_socket validé) → rejouer le sortant (check_task_009/010).
4. Test entrant après sortant OK.

Limite 2 canaux respectée — tests séquentiels.
