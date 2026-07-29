# Tâche CHECK #008 — Test d'appel réel via trunk Sewan (entrant + sortant)

**Émise par** : MAIN — 2026-07-29 08:50
**Déclencheur** : `ops_report_012.md` (config Phase 2 en place).
**Priorité** : haute — **nécessite coordination humaine (mobile de Julien)**
**Statut** : en attente signal OPS + dispo Julien

## Pré-requis
- Un softphone/UA sur 201 (acme) — CHECK peut l'enregistrer via son script SIP (IP whitelistée, ignoreip actif).
- Le **mobile de Julien** pour : (a) appeler le SDA `+33339571241` (test entrant), (b) recevoir l'appel sortant.

## 🟢 GO — config Phase 2 en place (ops_report_012). Protocole live ci-dessous.

### Préparer AVANT que Julien appelle
- **Enregistrer 201 (et si possible 202)** via le script SIP et **rester enregistré** (re-REGISTER < expires)
  pendant toute la fenêtre de test. Le script doit **auto-répondre** à un INVITE entrant et **boucler du RTP**
  (comme le test echo 600) pour valider l'audio entrant.
- Se mettre en écoute des logs edge : `docker logs -f pbxcloud-edge-1 | grep -iE "INVITE|37.97.65.74|DID|200"`.
- Signaler à MAIN « CHECK prêt » (fichier) pour que MAIN dise à Julien de lancer l'appel entrant.

### Cible sortante
- **`+33642224323`** (mobile Julien) — à composer depuis 201 en E.164.
- ⚠️ **Trunk limité à 2 canaux Sewan** : tester **entrant PUIS sortant séquentiellement**, jamais >2 appels
  trunk simultanés (un INVITE entrant forké 201&202 = 1 seul canal trunk).

## À faire (coordonné avec MAIN/Julien)
1. **Entrant** : Julien appelle `+33339571241` depuis son mobile → doit faire **sonner 201 & 202** (acme).
   - Vérifier côté edge : INVITE reçu de `37.97.65.74`, `DID_LOOKUP` route vers 172.28.0.11.
   - **Relever la forme exacte du numéro** présentée par Sewan (`+33339571241` vs `0339571241`) — ajuster si besoin.
   - Décrocher sur 201 → **vérifier l'audio bidirectionnel** (RTP via rtpengine, média 80.251.100.175 ↔ 37.97.65.74).
2. **Sortant** : depuis 201, appeler un **numéro mobile réel** (E.164, ex. celui de Julien) →
   - Kamailio route vers Sewan, auth 407→uac_auth→200, le mobile sonne, **audio bidirectionnel** confirmé.
   - CLI présenté = `+33339571241`.
3. **Sécurité/non-régression** : appels internes 201↔202 + echo 600 toujours OK ; register toujours actif.

## Rendu → `check_report_008.md`
Entrant (sonnerie + audio), sortant (sonnerie + audio + CLI), forme réelle du SDA, verdict GO/NO-GO trunk complet.
Toute anomalie (pas de sonnerie / audio unidirectionnel / rejet CLI) → trace + MAIN émet un correctif ciblé.
