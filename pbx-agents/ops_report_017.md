# Rapport OPS #017 — Média trunk : diagnostic (IP Sewan whitelistée, rtpengine ancre)

**En réponse à** : `ops_task_021.md` (canal GitHub) — suite de ops_report_016
**Rédigé par** : OPS — 2026-07-29 16:0x
**Cible** : `80.251.100.175` — sortant `→ +33642224323`

---

## STATUT
🔎 **Diagnostic média fait. Les 2 hypothèses de la tâche sont DISPROUVÉES pour la jambe trunk :**
l'**IP média Sewan est whitelistée** et **rtpengine ancre bien** le flux. Le média trunk **entrant fonctionne**
(757 paquets Sewan reçus, relayés à acme). Je **n'applique pas de correctif à l'aveugle** sur un chemin média
qui teste OK ; il faut un **appel réel décroché** (coordonné) pour isoler le maillon restant. Register + 0 régression.

## PREUVES (captures via originate `@edge-trunk`)

### 1. IP média Sewan (c= du 200 OK) — HYPOTHÈSE #1 DISPROUVÉE
```
SDP 183 Session Progress :  c=IN IP4 37.97.65.74   m=audio 24298 RTP/AVP 8 101
SDP 200 OK               :  c=IN IP4 37.97.65.74   m=audio 27990 RTP/AVP 8 101
```
→ Média Sewan = **`37.97.65.74`**, qui est **DÉJÀ dans la whitelist RTP** (`saddr 37.97.65.74 udp dport 30000-30999`).
Confirmé par le flux : **757 paquets `37.97.65.74 → 80.251.100.175`** ont bien traversé le firewall.

### 2. Ancrage rtpengine jambe trunk — HYPOTHÈSE #2 DISPROUVÉE
- INVITE sortant vers Sewan : **`c=IN IP4 80.251.100.175`** (rtpengine a réécrit vers l'IP publique) ✓.
- `route(MEDIA)` (rtpengine_manage) EST appelé sur l'INVITE sortant + `onreply_route` sur les réponses SDP.
- Flux RTP observés : `Sewan → rtpengine` 757 pqts ; `rtpengine → acme` 1512 pqts. → le média **est ancré et relayé**.

### 3. Codec — pas de mismatch
Sewan négocie **PCMA (8) + telephone-event (101)** ; on offre PCMA/PCMU/telephone-event. OK.

## OBSERVATION (piste de raffinement, pas une panne prouvée)
rtpengine utilise l'**interface `pub` (80.251.100.175) pour les DEUX jambes** (pas de flags `direction`) :
la jambe interne acme transite par l'IP publique (`80.251.100.175 ↔ 172.28.0.11`) au lieu de l'int `172.28.0.1`.
**Ça fonctionne** dans mes tests, mais ce n'est pas optimal ; c'est le candidat le plus plausible si l'audio
bout-en-bout casse avec le vrai poste (NAT réel).

## LIMITE DU DIAGNOSTIC SOLO
Mes tests `originate` **n'aboutissent pas à un décroché réel** (le mobile ne répond pas) → je ne peux pas
valider le **sens sortant (nous→Sewan)** ni la jambe **201 ↔ acme** en conditions réelles. Le sens **entrant
(Sewan→nous) fonctionne**. La coupure ~6 s côté Julien = très probablement un **timeout RTP sur une jambe non
observable en solo** (201 réel, ou sens retour). **J'arrête les appels solo vers le mobile de Julien** (respect
limite 2 canaux + son téléphone).

## CORRECTIF — en attente de confirmation par test réel
- **Ne pas** toucher au firewall RTP : l'IP média Sewan (37.97.65.74) est déjà whitelistée (hypothèse #1 écartée).
- **Candidat** (si le test réel montre un souci d'ancrage interne) : ajouter les flags `direction=int/pub` à
  `rtpengine_manage` **spécifiquement sur la jambe trunk** (offer nous→Sewan = `direction=int direction=pub`,
  reply = inverse), pour que la jambe acme utilise l'int. Je l'appliquerai **après** confirmation (risque de
  toucher au média intra-tenant qui marche).

## SUITE — test réel COORDONNÉ requis (Julien décroche)
Protocole proposé (1 seul appel, 2 canaux max) :
1. Julien appelle (ou est appelé) et **décroche + parle**, moi je capture **les 2 jambes** :
   `tcpdump 'host 37.97.65.74 or net 172.28.0.0/24' and udp` → je mesure le RTP **dans les 2 sens** sur chaque jambe.
2. Test miroir simple pour isoler la jambe 201 : **appel `201 → 600`** (écho interne acme) — si 201 s'entend, la
   jambe interne/poste est saine et le souci est le pont trunk↔interne.
3. Selon le sens RTP manquant → j'applique les flags rtpengine `direction` ciblés et on re-teste.

**Tâche `ops_task_021.md` : TRAITÉE (diagnostic : média trunk sain, IP Sewan whitelistée ; cause résiduelle à isoler en appel réel décroché).**
