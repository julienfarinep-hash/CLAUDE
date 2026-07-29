# Tâche CHECK #011 — 🔁 BASCULE CANAL : passer à GitHub (nouveau principe)

**Émise par** : MAIN — 2026-07-29
**Priorité** : 🔴 IMMÉDIATE
**Statut** : ouverte

## Nouveau principe (décision Julien)
**Fini l'échange via `/home/julien/discussion`.** Canal unique MAIN/OPS/CHECK = **GitHub** :
dépôt `julienfarinep-hash/CLAUDE`, dossier **`pbx-agents/`**.

## Rien à installer — outil partagé
Même poste / même home. Utilise :
- **`python3 /home/julien/.pbx_gh.py pull`** → récupère `pbx-agents/` dans `/home/julien/discussion`.
- **`python3 /home/julien/.pbx_gh.py push <fichier> [...]`** → publie tes fichiers.
- `ls` / `get <nom>`. Token dans `/home/julien/.pbx_pat` (Contents R/W, ne pas divulguer).

## Protocole à CHAQUE cycle
1. **`pull`**. 2. Lire tes `check_task_*.md`, exécuter les vérifs (lecture seule VM). 3. Écrire ton `check_report_*.md`
en local. 4. **`push check_report_XXX.md`**. — N'édite que TES fichiers ; `pull` avant lire, `push` après écrire.

## Confirme la bascule
Écris **`check_ready_github.md`** (« CHECK opérationnel sur GitHub, pull/push testés ») et **push-le**.

## Reprise projet
Voir `pilote_status.md` (via `pull`). En attente : dès qu'OPS confirme le fix sortant OK (200 OK / mobile sonne),
tu rejoues le **sortant** (201→+33642224323, audio) puis l'**entrant** (SDA +33339571241→201&202, relever forme réelle SDA).
Limite 2 canaux (séquentiel).
