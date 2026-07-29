# PROTOCOLE D'ÉCHANGE — MAIN / OPS / CHECK (via GitHub)

**En vigueur : 2026-07-29.** Décision Julien : **tout l'échange passe par GitHub**, plus par le dossier local.

## Canal unique
- Dépôt **`julienfarinep-hash/CLAUDE`**, dossier **`pbx-agents/`** (branche par défaut `claude/ios-app-web-check-2s6og3`).
- Le dossier local `/home/julien/discussion` n'est plus le canal : c'est au mieux une **copie de travail** que
  chaque agent **synchronise** avec GitHub (pas de `git` sur le poste → **API GitHub**).

## Règle pour chaque agent (à chaque cycle)
1. **PULL** le dossier `pbx-agents/` (récupérer les tâches/rapports des autres) AVANT de lire.
2. Lire, agir.
3. Écrire SON fichier (rapport/tâche/status) en local, puis **PUSH** vers `pbx-agents/`.
- Ne pas éditer le fichier d'un autre agent (chacun ses fichiers → pas de conflit).

## Convention de fichiers (inchangée)
- `pilote_status.md` : synthèse MAIN (source de vérité de l'avancement).
- `ops_task_NNN.md` (MAIN→OPS) / `ops_report_NNN.md` (OPS→MAIN).
- `check_task_NNN.md` (MAIN→CHECK) / `check_report_NNN.md` (CHECK→MAIN).
- `reference_*.md` : références partagées.
- Numérotation incrémentale conservée ; statut en tête de tâche (ouverte / TRAITÉE / …).

## Outillage (sans git)
- Accès via API GitHub avec un PAT (permission **Contents: Read and write** sur `CLAUDE`).
- MAIN utilise `~/.pbx_gh.py` (`ls` / `pull` / `push <fichiers>` / `get <nom>`).
- OPS et CHECK : même principe côté leurs sessions (token + helper API).

## Reprise projet (trunk) — où on en est
Register Sewan actif (Phase 1 close). Sortant : fix `force_send_socket :5070` appliqué (ops_task_017) à
**vérifier** (viser 200 OK), puis vrai appel mobile + **entrant** (SDA +33339571241 → acme 201&202). 2 canaux max.
