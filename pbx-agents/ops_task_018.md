# Tâche OPS #018 — 🔁 BASCULE CANAL : passer à GitHub (nouveau principe)

**Émise par** : MAIN — 2026-07-29
**Priorité** : 🔴 IMMÉDIATE (change ta façon d'échanger)
**Statut** : ouverte

## Nouveau principe (décision Julien)
**On ne s'échange plus rien via le dossier local `/home/julien/discussion`.**
Le canal unique MAIN/OPS/CHECK est désormais **GitHub** : dépôt `julienfarinep-hash/CLAUDE`, dossier **`pbx-agents/`**.

## Rien à installer — outil partagé déjà en place
Ta session tourne sur le même poste (home `/home/julien`). Utilise directement :
- **`python3 /home/julien/.pbx_gh.py pull`** → télécharge tout `pbx-agents/` dans `/home/julien/discussion` (copie de travail).
- **`python3 /home/julien/.pbx_gh.py push <fichier> [...]`** → envoie tes fichiers vers GitHub.
- `ls` (liste distante) / `get <nom>` (affiche un fichier distant).
- Le token est dans `/home/julien/.pbx_pat` (permission Contents R/W). Ne le divulgue pas.

## Protocole à CHAQUE cycle
1. **`pull`** (récupérer les tâches/rapports à jour des autres).
2. Lire tes `ops_task_*.md`, agir sur la VM.
3. Écrire ton `ops_report_*.md` en local.
4. **`push ops_report_XXX.md`** (et tout fichier que tu modifies).
- N'édite que TES fichiers. Toujours `pull` avant de lire, `push` après écrire.

## Confirme la bascule
Écris un court **`ops_ready_github.md`** (« OPS opérationnel sur le canal GitHub, pull/push testés ») et **push-le**.

## Reprise projet
Voir `pilote_status.md` (sur GitHub après `pull`). En cours : vérifier le fix sortant `force_send_socket :5070`
(ops_task_017 : viser 200 OK Sewan au lieu de 482), puis vrai appel mobile + test entrant. Limite 2 canaux.
