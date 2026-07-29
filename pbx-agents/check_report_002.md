# Rapport CHECK #002 — Passage à blanc post-déploiement partiel
**Timestamp** : 2026-07-28 18:29
**Tâche** : check_task_002.md
**Agent** : CHECK
**Note** : ops_report_002.md absent au moment du passage à blanc — audit déclenché sur état VM réel (déploiement partiel constaté)

---

## STATUT : **NO-GO** — ANOMALIE BLOQUANTE (edge Kamailio crash-loop)

---

## RÉSULTATS — Tableau attendu / actuel / écart

### A1 — Conteneurs edge

| Invariant | Attendu | Actuel | Écart |
|-----------|---------|--------|-------|
| `rtpengine` UP en mode host | Oui | **UP** (8 min) ✅ | OK |
| `edge` (Kamailio) UP en mode host | Oui | **Restarting (255)** ❌ | BLOQUANT |
| Port 5060 UDP/TCP en écoute | Oui | **Non en écoute** ❌ | BLOQUANT |
| Socket NG 127.0.0.1:22222 | Oui | **Présent** ✅ | OK |

### A2 — Tenant acme

| Invariant | Attendu | Actuel | Écart |
|-----------|---------|--------|-------|
| Conteneur `tenant-acme` UP | Oui | **Absent** ❌ | Non démarré |
| Asterisk répond | Oui | **N/A** | Non démarré |

### A4 — Advertise Kamailio

| Invariant | Attendu | Actuel | Écart |
|-----------|---------|--------|-------|
| PUBLIC_IP = 80.251.100.175 | Oui | **.env : 80.251.100.175** ✅ | OK |
| Alias Kamailio = pbx1-procom.dyndns.org | Oui | **Visible dans logs** ✅ | OK |

### S6 — Règles bridge nftables (172.28.0.0/24)

| Invariant | Attendu | Actuel | Écart |
|-----------|---------|--------|-------|
| Règles 172.28.0.0/24 → host présentes | Oui | **Présentes** ✅ | OK |
| Règles SIP/RTP whitelist 3 IPs | Oui | **Présentes** ✅ (86.219/217.181/195.135) | OK |
| Ouverture mondiale (non souhaitée) | Non | **Absente** ✅ | OK |

---

## ANOMALIE PRINCIPALE — BLOQUANTE

### Kamailio crash-loop : `bind 172.28.0.1: Cannot assign requested address`

**Message d'erreur exact** (logs `pbxcloud-edge-1`) :
```
ERROR: <core> [core/udp_server.c:607]: udp_init():
  bind(6, ...) on 172.28.0.1: Cannot assign requested address
```

**Cause racine** : le bridge Docker `pbxcloud_pbxnet` (subnet 172.28.0.0/24, gateway 172.28.0.1) **n'a pas été créé**. Docker crée ce bridge et assigne 172.28.0.1 à l'interface `br-xxx` de l'hôte uniquement quand un conteneur connecté à ce réseau démarre. Comme seuls `rtpengine` et `edge` ont été lancés (tous deux en `network_mode: host`), aucun conteneur ne rejoint `pbxnet` → le bridge n'existe pas → 172.28.0.1 n'est pas assigné → Kamailio ne peut pas binder son socket "int" → exit 255.

**État réseau Docker actuel** :
```
bridge    (172.17.0.1 — docker0, défaut)
host
none
← pbxcloud_pbxnet : ABSENT
```

**Conséquence** : port 5060 non ouvert, aucun enregistrement SIP possible, edge inutilisable.

---

## AUTRES OBSERVATIONS

| Point | État |
|-------|------|
| `.env` PUBLIC_IP | ✅ 80.251.100.175 (correct) |
| `.env` SIP_DOMAIN | ✅ pbx1-procom.dyndns.org |
| `.env` TRUNK_IP | ✅ 0.0.0.0 (voulu) |
| nftables SIP/RTP whitelist | ✅ 3 IP whitelistées, pas d'ouverture mondiale |
| Règles bridge S6 | ✅ 172.28.0.0/24 autorisé vers host |
| rtpengine | ✅ UP, socket NG 22222 actif |
| PasswordAuthentication SSH | ⚠️ encore `yes` (clé déployée → à passer à `no`) |

---

## CORRECTION À APPLIQUER PAR OPS (lecture seule ici)

**Option A — Démarrer un tenant** (approche recommandée — crée le bridge automatiquement) :
```bash
cd ~/pbx-cloud
docker compose -f docker-compose.yml -f docker-compose.tenants.yml up -d tenant-acme
# Le bridge pbxcloud_pbxnet est créé → 172.28.0.1 assigné → relancer edge :
docker compose restart edge
```

**Option B — Créer le réseau manuellement** (si on ne veut pas de tenant tout de suite) :
```bash
docker network create \
  --driver bridge \
  --subnet 172.28.0.0/24 \
  --gateway 172.28.0.1 \
  pbxcloud_pbxnet
docker compose restart edge
```

> **Note CHECK** : l'option A est préférable car elle valide simultanément l'invariant A2 (tenant acme) et assure la cohérence du réseau avec la configuration docker-compose.

---

## SUITE

**Verdict** : **NO-GO** — Kamailio hors service, aucun test SIP possible.

Dès que OPS corrige et relance edge :
- CHECK re-vérifiera : `docker ps`, `ss -tulnp | grep 5060`, `docker exec edge-1 kamctl ul show`
- Si edge stable 2 min → passage aux tests A2 (tenant acme) puis test enregistrement SIP

**Tâche check_task_002.md : TRAITÉE**
