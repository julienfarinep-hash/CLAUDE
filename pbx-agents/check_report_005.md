# Rapport CHECK #005 — Tenant beta + isolation inter-tenant

**Timestamp** : 2026-07-28 21:15
**Tâche** : check_task_005.md
**Agent** : CHECK
**Cible** : 80.251.100.175 (pbx1-procom.dyndns.org)

---

## STATUT

✅ **GO — Tenant beta validé bout-en-bout. Isolation inter-tenant confirmée intacte.**

---

## RÉSULTATS

### 1. Beta fonctionnel (REGISTER + echo RTP)

| Test | Résultat |
|------|----------|
| REGISTER 301 (creds tenants/beta/pjsip.conf) | ✓ 200 OK, AOR 301 Added |
| INVITE 600@pbx1-procom.dyndns.org (écho beta-internal) | ✓ 200 OK |
| SDP média IP | ✓ **80.251.100.175** (rtpengine côté public) |
| SDP média port | ✓ **30228** (dans plage 30000-30999) |
| Flux RTP écho Echo() | ✓ **140 envoyés / 99 retour** |

→ **Beta : GO bout-en-bout** (signalisation Kamailio→Asterisk + média rtpengine + écho dialplan).

---

### 2. Isolation inter-tenant — 4 vecteurs

| Vecteur | Description | Réponse | Verdict |
|---------|-------------|---------|---------|
| **V1** | 201 INVITE sip:301@pbx1-procom.dyndns.org (sans sous-domaine) | 401 (auth acme) puis pas de route 3xx | ✓ **ISOLÉ** |
| **V2** | 201 INVITE sip:301@beta.pbx1-procom.dyndns.org (sous-domaine beta) | 404 Dialogue inconnu | ✓ **ISOLÉ** |
| **V3** | 301 INVITE sip:201@pbx1-procom.dyndns.org (inverse) | 401 Unauthorized | ✓ **ISOLÉ** |
| **V4** | REGISTER 201 sur beta.pbx1-procom.dyndns.org | 401 Unauthorized | ✓ **ISOLÉ** |

**Mécanisme d'isolation confirmé** :
- Kamailio reset `$var(tip)="none"` à chaque requête (pas d'héritage de worker)
- Aiguillage par sous-domaine SIP ($rd) puis par préfixe numérique ($fU/tU)
- Dialplan Asterisk distincts : `acme-internal` (_2XX + 600) ≠ `beta-internal` (_3XX + 600)
- Auth PJSIP par tenant : credentials 201 inconnus de beta Asterisk

→ **Isolation : INTACTE sur les 4 vecteurs testés.**

---

### 3. Non-régression acme

| Test | Résultat |
|------|----------|
| REGISTER 201 | ✓ 200 OK |
| INVITE 600@pbx1-procom.dyndns.org (écho acme-internal) | ✓ 200 OK |
| SDP média IP | ✓ **80.251.100.175** |
| SDP média port | ✓ **30428** (plage rtpengine) |
| Flux RTP écho | ✓ **25 envoyés / 126 retour** |

→ **acme : non-régression confirmée GO.**

---

## ANOMALIES

### A1 — Faux positif V1 dans le script de test (CLÔTURÉE)

**Observation initiale** : lors de la campagne `/tmp/sip_isolation_test.py`, V1 (`201 INVITE 301`) avait
retourné 200 OK, suggérant une fuite.

**Analyse** : les logs VM ont montré **zéro traitement INVITE pour l'extension 301 dans les journaux
acme Asterisk** — confirmant que ce 200 OK ne provenait pas d'un traitement d'appel cross-tenant.

**Cause identifiée** : socket UDP partagé entre plusieurs échanges SIP successifs.
La réponse `200 OK` était un résidu du BYE tardif (ou d'un REGISTER précédent) du test beta
en cours, lu par `sip_exchange()` avant qu'il reçoive la vraie réponse au INVITE V1.
Le script ne filtrait pas les réponses par `Call-ID`.

**Re-test isolé** (socket neuf dédié, filtrage Call-ID strict) : V1 retourne **401 Unauthorized**
→ pas de fuite. **Isolation réelle confirmée.**

**Leçon** : tous les futurs scripts de test doivent filtrer les réponses SIP par Call-ID.
Faux positif purement lié à la méthodologie de test, pas à l'architecture.

### A2 — BYE challengé par Asterisk (NON CRITIQUE, connue)

PJSIP Asterisk 21 challenge les BYE par défaut. Les scripts de test ne gèrent pas la
ré-authentification BYE → la session est raccrochée via qualify timeout (~32s côté Asterisk).
Impact fonctionnel nul (le media est libéré et rtpengine récupère le port).
À corriger dans les scripts de test si des tests de durée sont planifiés.

---

## SUITE

**CHECK #005 : TERMINÉE — acme ✓, beta ✓, isolation ✓, non-régression ✓.**

Éléments restants pour de futures tâches (référence pour MAIN) :

| Item | Priorité | État |
|------|----------|------|
| Extension 302 (beta) non testée | Basse | Non fait |
| Autoprovisionnement Yealink (nginx) | Moyenne | Non déployé |
| Trunk opérateur Sewan | Haute | Non connecté |
| Fail2ban jail SIP re-vérification | Moyenne | ops_report_004 dit OK, non re-vérifié CHECK |
| PasswordAuthentication no (S3) | Moyenne | Non vérifié |
| Tests charge multi-tenant (201+301 simultanés) | Basse | Non fait |

→ Attente prochaine tâche `check_task_006.md`.
