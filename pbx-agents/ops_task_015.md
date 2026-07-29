# Tâche OPS #015 — Trunk Phase 2 : appels entrant (SDA) + sortant (E.164)

**Émise par** : MAIN — 2026-07-29 08:50
**Base** : reference_trunk_sewan.md (données Phase 2 complètes) + design ops_report_006
**Priorité** : haute
**Statut** : ouverte — GO
**Rappel sécu** : `ignoreip` admin en place → plus de risque de re-ban. `.bak` avant chaque édition, `kamailio -c`
avant de recréer l'edge, pas de flush nftables.

## Données
- Register Phase 1 **actif** (uac Kamailio, edge :5070).
- **RTP Sewan** : `37.97.65.74/32`. **Sortant** : E.164 (`+33…`), **CLI** `+33339571241`.
- **SDA** `+33339571241` → **acme** (172.28.0.11), sonner **201 & 202**.

## À faire
### 1. Firewall RTP Sewan
- Whitelist nftables : `ip saddr 37.97.65.74 udp dport 30000-30999 accept` (`.bak`, persister, sans flush).
  (Couvre l'entrant ; le retour sortant passe déjà par conntrack established.)
- ⚠️ **Ports Sewan 10000-59999 = leurs ports SOURCE** : couverts par la whitelist /32 (port source non filtré).
  **NE PAS** ouvrir 10000-59999 en `dport` chez nous — le dport reste notre plage rtpengine 30000-30999.

### 2. Entrant (SDA → acme)
- **Kamailio `DID_LOOKUP`** : router le SDA vers acme, ex.
  `if ($rU == "+33339571241" || $rU == "0339571241") { $var(tip)="172.28.0.11"; return; }`
  (gérer les 2 formes tant que la forme réelle présentée par Sewan n'est pas observée).
- **acme `extensions-inbound.conf`** : `exten => _[+0]33339571241,1,Dial(PJSIP/201&PJSIP/202,30)` (+ NoOp + Hangup).
  Adapter au motif réel. Objectif : un appel entrant sur le SDA fait sonner 201 ET 202.

### 3. Sortant (E.164 → Sewan)
- **acme dialplan** : activer la sortie E.164 vers l'edge, ex. `exten => _+33X.,1,Set(CALLERID(num)=+33339571241)` puis
  `Dial(PJSIP/${EXTEN}@edge-trunk,60)`. Définir l'endpoint PJSIP `edge-trunk` (vers l'edge 172.28.0.1).
- **Kamailio** : les requêtes issues d'un tenant (src 172.28.0.x) à destination E.164 externe → `$du=sip:37.97.65.74:5070`,
  et sur **407** `failure_route[TRUNK_AUTH]` → `uac_auth()` + `t_relay()` (design ops_report_006).
- Présenter le **CLI `+33339571241`** (SDA valide côté Sewan) sinon rejet opérateur.

### 4. Appliquer + vérifier
- `.bak`, `kamailio -c` OK → recréer edge (si cfg edge modifiée) + reload acme Asterisk.
- Vérifs : register toujours actif (uac.reg_dump), 4 conteneurs UP, nftables RTP Sewan présent, pas de régression 2 tenants.

## Rendu → `ops_report_012.md`
Config entrant/sortant en place, RTP Sewan whitelisté, register OK, 0 régression. **Signaler CHECK + MAIN** :
prêt pour test d'appel réel (nécessite le mobile de Julien). Noter la forme exacte du SDA si un INVITE entrant a déjà été vu.
