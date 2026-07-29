# Tâche CHECK #001 — Grille de vérification cible

**Émise par** : MAIN — 2026-07-28 18:06
**Priorité** : moyenne (indépendante de l'accès VM)
**Statut** : TRAITÉE — voir check_report_001.md (2026-07-28 18:12)

## Objectif
Définir, à partir du récapitulatif de la maquette PBX01 (90.178) et des sources
`/home/julien/pbx-cloud`, la grille de critères qui prouvera que le déploiement cloud
sur `80.251.100.175` est fonctionnel. CHECK ne modifie rien : il vérifie et rapporte.

## À produire
1. **Liste des invariants attendus** sur la VM cible une fois déployée, ex. :
   - Conteneurs edge (kamailio + rtpengine) up sur le host.
   - Au moins 1 Asterisk 21 tenant up sur le bridge dédié.
   - Ports SIP (5060) et média (plage RTP) cohérents avec la conf.
   - Résolution `pbx1-procom.dyndns.org` → `80.251.100.175` (déjà OK côté DNS).
2. **Commandes de contrôle non intrusives** (lecture seule) pour chaque invariant.
3. **Critères sécurité minimaux** avant toute ouverture au monde (fail2ban, SSH durci,
   pas de PasswordAuthentication root si clé en place).

## Rendu attendu
Écrire `/home/julien/discussion/check_report_001.md` avec la grille complète et,
si un accès VM est disponible, un premier passage à blanc (état actuel vs attendu).

## Rappel de coordination
Toute anomalie détectée → la signaler dans le rapport ; MAIN arbitrera et émettra
une tâche OPS corrective. Ne pas exécuter d'action corrective toi-même.
