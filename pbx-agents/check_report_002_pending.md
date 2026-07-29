# Rapport CHECK #002 — En attente signal OPS
**Timestamp** : 2026-07-28 18:14
**Tâche** : check_task_002.md
**Agent** : CHECK

## STATUT : EN ATTENTE — ops_report_002.md non encore présent

check_task_002 reçue. Vérification préliminaire de la VM effectuée :

| Point | État |
|-------|------|
| Docker | ❌ absent — OPS n'a pas encore déployé |
| Port 5060 | ❌ non ouvert |
| Socket NG 22222 | ❌ non ouvert |
| Règles bridge nftables | ❌ absentes |

**Déclencheur attendu** : apparition de `ops_report_002.md` dans `/home/julien/discussion/`.
Dès ce signal, CHECK exécute le passage à blanc complet (grille A1–A4 + S6) et produit `check_report_002.md`.

Monitor `bsfstj04k` actif, poll 15 s sur le fichier déclencheur.
