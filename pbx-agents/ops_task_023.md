# Tâche OPS #023 — 🔀 BASCULE CANAL + test sortant "vitrine" (CLI + son + écho)

**Émise par** : MAIN — 2026-07-29 (canal GitHub)
**Priorité** : 🔴 HAUTE
**Statut** : ouverte

---

## 1. 🔀 BASCULE DE CANAL (à faire EN PREMIER, une seule fois)
Décision Julien : le canal passe sur le **repo dédié `julienfarinep-hash/pbx-agents`** (racine, branche `main`).
L'ancien `CLAUDE/pbx-agents/` est **gelé** (70 fichiers recopiés à l'identique). Mets à jour ton `~/.pbx_gh.py` :
- `REPO='pbx-agents'` ; **plus de préfixe** (fichiers à la racine) ; `branch='main'`
  (`?ref=main` sur les GET, `"branch":"main"` dans le payload PUT).
- Le PAT couvre déjà `pbx-agents` (même owner). Vérifie : `pull` doit ramener **70 fichiers**.
- **Tous tes prochains push (ops_report_*) vont sur `pbx-agents`.** Détail dans `PROTOCOLE_ECHANGE.md`.

## 2. Test sortant "vitrine" (reprend ops_task_022, non encore rapporté)
Contexte confirmé (ops_report_015/016/017 + retour Julien) : SORTANT **200 OK**, **audio 2 sens OK** (écho),
média trunk ancré. Reste un artefact : en `originate` brut le **CLI s'affiche "inconnu"** car le dialplan qui
pose le CALLERID est court-circuité.

À faire — un seul appel coordonné (2 canaux max), **routé par le dialplan** pour que le CLI soit présenté :
1. Contexte de test acme qui **pose le CLI, joue un son, puis écho** :
   ```
   exten => 601,1,Answer()
    same => n,Playback(demo-congrats)   ; son audible
    same => n,Echo()
    same => n,Hangup()
   ```
2. Appel vers le mobile `+33642224323` en **présentant le SDA `+33339571241`** (via le dialplan / `Set(CALLERID(num)=+33339571241)`
   avant le Dial edge-trunk), mobile décroché connecté à `601`.
3. Capture : confirmer **From/PAI = +33339571241** sur CET appel (pas "anonymous"/"inconnu").

**Attendu Julien** : mobile sonne, **affiche `+33339571241`**, décroche → entend le son puis s'entend (écho).
**Signale à MAIN quand l'appel part** (pour prévenir Julien).

## 3. Ensuite → ENTRANT
Préparer le test entrant : SDA `+33339571241` → sonner **acme 201 & 202**. Relever la **forme réelle du SDA**
présentée par Sewan (E.164 `+33…` / national / `0033…`) pour nettoyer `DID_LOOKUP`.

## Cadre
`.bak` avant toute édition, `kamailio -c` OK, jamais de flush nftables, register + non-régression préservés.

## Rendu → `ops_report_018.md` (push sur `pbx-agents`)
Confirme la bascule canal OK (70 fichiers) + CLI `+33339571241` présenté (extrait From/PAI) + son/écho OK.
