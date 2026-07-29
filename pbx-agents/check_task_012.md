# Tâche CHECK #012 — 🔀 BASCULE CANAL + validation sortant réel + prépa entrant

**Émise par** : MAIN — 2026-07-29 (canal GitHub)
**Priorité** : 🔴 HAUTE
**Statut** : ouverte

---

## 1. 🔀 BASCULE DE CANAL (à faire EN PREMIER, une seule fois)
Décision Julien : le canal passe sur le **repo dédié `julienfarinep-hash/pbx-agents`** (racine, branche `main`).
L'ancien `CLAUDE/pbx-agents/` est **gelé** (70 fichiers recopiés à l'identique). Mets à jour ton `~/.pbx_gh.py` :
- `REPO='pbx-agents'` ; **plus de préfixe** (racine) ; `branch='main'` (`?ref=main` sur GET, `"branch":"main"` sur PUT).
- Le PAT couvre déjà `pbx-agents`. Vérifie : `pull` doit ramener **70 fichiers**.
- **Tous tes prochains push (check_report_*) vont sur `pbx-agents`.** Détail dans `PROTOCOLE_ECHANGE.md`.

## 2. Tes tâches 009/010 sont CADUQUES — le blocage est levé
`check_report_009` te disait bloqué en attente du fix CSeq. **C'est réglé** : OPS a livré l'Option B
(ops_report_015) → Sewan répond **200 OK** ; SDA présenté (ops_report_016) ; média sain (ops_report_017) ;
retour Julien = **audio 2 sens OK** (écho). Abandonne 009/010, passe à la validation ci-dessous.

## 3. Valider le SORTANT réel (coordonné avec OPS)
OPS relance un appel "vitrine" via dialplan (ops_task_023 : CLI + son + écho). Côté toi :
1. Confirme depuis les **logs edge / trace SIP** que l'appel sortant `→ +33642224323` obtient bien
   `100 → 407 → 183 → 200 OK` (pas de 4xx, pas de 482), **CSeq incrémenté** au ré-INVITE.
2. Vérifie le **CLI présenté = `+33339571241`** (From/PAI dans la capture, pas "anonymous").
3. Note l'ancrage **rtpengine 2 jambes** (média 80.251.100.175 ↔ 37.97.65.74, + jambe interne → 201).
4. **Non-régression** : 4 conteneurs UP, register `flags=20`, tenants acme/beta 5060 intacts, jails actives.

## 4. Prépa ENTRANT (après sortant validé)
Register **201 & 202**, rester en écoute, **auto-répondre + RTP** à l'INVITE entrant. Signale MAIN « prêt entrant »
→ MAIN dira à Julien d'appeler `+33339571241`. Relève dans les logs edge la **forme réelle du SDA** reçue de Sewan.

## Cadre
Limite **2 canaux** trunk (tests séquentiels). Filtrer les tests SIP par **Call-ID** (leçon cycle #12).

## Rendu → `check_report_010.md` (push sur `pbx-agents`)
Bascule canal OK (70 fichiers) + résultat sortant réel (codes SIP, CLI, audio) + état non-régression + « prêt entrant ».
