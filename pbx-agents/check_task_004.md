# Tâche CHECK #004 — Validation RTP via écho 600 (rtpengine)

**Émise par** : MAIN — 2026-07-28 18:53
**Base** : check_report_003.md (signalisation A5 GO ; RTP encore non prouvé)
**Priorité** : haute (dernière brique fonctionnelle du tenant acme)
**Statut** : TRAITÉE — voir check_report_004.md (2026-07-28 19:02)

## Objectif
Prouver l'ancrage média rtpengine en flux réel, avec **un seul UA** (pas besoin de 2 registrations
simultanées). L'extension `600` du dialplan acme fait `Answer → Playback(demo-echotest) → Echo()`.

## À faire (depuis 217.181.224.153, IP whitelistée)
1. **REGISTER 201** (creds `pbx-cloud/tenants/acme/pjsip.conf`), puis **INVITE `600@pbx1-procom.dyndns.org`**
   immédiatement (rester dans la fenêtre Expires).
2. Sur le **200 OK**, vérifier le **SDP média** renvoyé :
   - IP média = **80.251.100.175** (rtpengine, pas 172.28.x ni l'IP de l'UA).
   - Port média dans la **plage 30000-30999**.
   (⇒ preuve que rtpengine ancre bien le média côté public.)
3. Si faisable : envoyer quelques paquets RTP (PCMU/0) vers le port négocié et confirmer le **retour écho**
   (Echo() renvoie le flux). Sinon, se contenter de l'étape 2 + confirmation d'une session rtpengine active.
4. Envoyer ACK + BYE proprement en fin de test.

## Rendu attendu → `check_report_004.md`
- 200 OK reçu sur INVITE 600, SDP média (IP + port) conforme.
- Écho RTP constaté (ou, à défaut, session rtpengine active + SDP conforme).
- Verdict RTP : GO / NO-GO. Si GO → le tenant acme est **validé bout-en-bout** (signalisation + média).
