# Rapport OPS #018 — Reprise après reboot : contexte récupéré, BLOQUÉ sur sudo

**En réponse à** : reprise de session OPS (dossier local perdu au reboot) — suite de ops_report_017
**Rédigé par** : OPS — 2026-07-29 ~17:20Z
**Cible** : `80.251.100.175` (user `procom`, clé `id_pbxcloud`)

---

## STATUT
🟡 **Contexte entièrement récupéré, mais reprise BLOQUÉE.** Le canal GitHub fonctionne (pull OK, 69 fichiers),
l'accès SSH par clé fonctionne, et les process `asterisk`/`kamailio`/`rtpengine` **tournent** sur la VM.
**Mais je n'ai PAS le mot de passe sudo de `procom`** (pas de NOPASSWD ; le mdp vivait uniquement en mémoire de
la session OPS précédente, jamais persisté dans les fichiers). Sans sudo → **aucune** commande privilégiée
possible (asterisk -rx, kamctl, ss, tcpdump, nftables, fail2ban, édition de config). La tâche ouverte
`ops_task_022` (test vitrine sortant CLI+son+écho) est de toute façon bloquée sur une **coordination live**
avec Julien (mobile décroché).

## ACTIONS
- Sync canal : `python3 ~/.pbx_gh.py pull` → **PULLED 69**. (NB : pas de `git` sur le poste ; canal = API GitHub
  sur `julienfarinep-hash/CLAUDE` dossier `pbx-agents/`. L'URL "pbx-agents.git / [TON_USER]" du brief n'existe pas
  telle quelle — c'est ce helper qui est le canal réel.)
- Relu l'état : `ops_report_017` (dernier rapport), `ops_task_022` (seule tâche ouverte), `PROTOCOLE_ECHANGE`,
  `ops_ready_github`, `pilote_status`.
- SSH VM par clé : **OK** (`ssh pbxcloud` → CONNECTED debian, 17:17Z).
- Runtime VM (sans sudo) : `ps` montre **asterisk + kamailio + rtpengine actifs** (process présents).
  `systemctl is-active` renvoie "inactive" car ces daemons ne sont **pas** gérés par des units systemd de ces noms
  (démarrage hors systemd). Pas de Docker visible côté `docker ps` sans sudo.

## PROBLEMES
1. 🔴 **Mot de passe sudo `procom` indisponible.** `echo <pwd> | sudo -S <cmd>` est la méthode documentée
   (ops_report_001, pilote_status l.103) mais le mdp n'est dans aucun fichier (volontairement). Sans lui,
   0 diagnostic/correctif privilégié possible. **Bloquant dur.**
2. 🟠 **`ops_task_022` nécessite Julien en ligne** (mobile qui sonne, décroche, entend Playback+Echo, CLI
   `+33339571241`). Test coordonné 1 appel / 2 canaux max — pas d'exécution solo (cf. décision ops_report_017 :
   arrêt des appels solo vers le mobile de Julien).
3. 🟡 Le brief de reprise décrivait un `git clone/pull` d'un repo `pbx-agents.git` inexistant ; corrigé en
   utilisant le vrai canal (`~/.pbx_gh.py`). Aucune donnée perdue (les fichiers étaient présents en local).

## SUITE
1. **Julien fournit le mot de passe sudo `procom`** (ou exécute lui-même les cmds privilégiées) → je débloque
   immédiatement le diagnostic et la prépa de `ops_task_022` (contexte de test `601` Answer/Playback/Echo +
   vérif routage CLI `+33339571241` via dialplan, sans passer l'appel).
2. Une fois sudo OK : je vérifie register Sewan, listeners UDP 5060/5070, état rtpengine, puis je **prépare**
   le test 022 (config 601) et je signale à MAIN "prêt".
3. **Test 022 = coordonné** : dès que Julien est dispo au mobile, on lance 1 appel (CLI + son + écho), je capture
   les 2 jambes, je confirme From/PAI `+33339571241`. Puis on enchaîne sur l'**entrant** (SDA → 201/202).

**Tâche `ops_task_022` : NON TRAITÉE ce cycle — bloquée (sudo manquant + coordination live requise).**
