# Rapport CHECK #002b — Passage à blanc complet post-correction OPS
**Timestamp** : 2026-07-28 18:37
**Contexte** : suite à ops_report_002.md (stack déclarée UP). Complète check_report_002.md (état intermédiaire cassé).
**Agent** : CHECK — audit live, lecture seule

---

## STATUT : **GO** — Stack opérationnelle, prêt pour tests SIP A5

---

## Tableau complet attendu / actuel / écart

### A1 — Conteneurs edge

| Invariant | Attendu | Actuel | Écart |
|-----------|---------|--------|-------|
| `rtpengine` UP (host) | Oui | **Up 14 min** ✅ | OK |
| `edge` (Kamailio) UP (host) | Oui | **Up 2 min** ✅ | OK |
| `tenant-acme` UP (172.28.0.11) | Oui | **Up 2 min** ✅ | OK |
| Port 5060 UDP 80.251.100.175 | Oui | **En écoute** ✅ | OK |
| Port 5060 UDP 172.28.0.1 (int) | Oui | **En écoute** ✅ | OK |
| Port 5060 TCP 80.251.100.175 | Oui | **En écoute** ✅ | OK |
| Socket NG 127.0.0.1:22222 | Oui | **En écoute** ✅ | OK |
| Bridge `pbxcloud_pbxnet` 172.28.0.0/24 | Oui | **Présent** ✅ (br-8c68c358889c, gw 172.28.0.1) | OK |

### A2 — Tenant acme (Asterisk)

| Invariant | Attendu | Actuel | Écart |
|-----------|---------|--------|-------|
| Asterisk 21 UP | Oui | **21.12.3** ✅ | OK |
| Endpoint 201 présent | Oui | **Présent, Unavailable** ✅ (normal — aucun UA) | OK |
| Endpoint 202 présent | Oui | **Présent, Unavailable** ✅ (normal — aucun UA) | OK |
| IP conteneur = 172.28.0.11 | Oui | **172.28.0.11** ✅ | OK |

### A3 — Signalisation Kamailio

| Invariant | Attendu | Actuel | Écart |
|-----------|---------|--------|-------|
| `kamctl ul show` (location table) | Vide (0 UA) | **Commande FIFO non dispo** ⚠️ | Limitation outillage |
| Log Kamailio : rtpengine trouvé | Oui | **Confirmé OPS** ✅ | OK |

> **Note A3** : `kamctl ul show` via FIFO échoue dans le contexte `docker exec` (module jsonrpcs / socket FIFO non exposé). Ce n'est pas une anomalie fonctionnelle — la location table sera vérifiable via log Kamailio lors du premier REGISTER. Alternative pour CHECK : `docker logs pbxcloud-edge-1 | grep REGISTER`.

### A4 — Advertise et domaine

| Invariant | Attendu | Actuel | Écart |
|-----------|---------|--------|-------|
| Kamailio listen pub = 80.251.100.175 | Oui | **80.251.100.175:5060** udp+tcp ✅ | OK |
| Kamailio listen int = 172.28.0.1 | Oui | **172.28.0.1:5060** udp ✅ | OK |
| Alias = pbx1-procom.dyndns.org | Oui | **pbx1-procom.dyndns.org** ✅ | OK |
| Pas d'ancienne IP (178.170.25.68) | Oui | **Absente** ✅ | OK |
| DNS pbx1-procom.dyndns.org → 80.251.100.175 | Oui | **Confirmé** ✅ | OK |

### S6 — Firewall nftables

| Critère | Attendu | Actuel | Écart |
|---------|---------|--------|-------|
| 5060 UDP+TCP — whitelist 3 IP | Oui | **Présent** ✅ (86.219/217.181/195.135) | OK |
| RTP 30000-30999 — whitelist 3 IP | Oui | **Présent** ✅ | OK |
| Bridge 172.28.0.0/24 → host (S6) | Oui | **Présent** ✅ 5060+RTP | OK |
| Ouverture mondiale 5060 | Non | **Absente** ✅ | OK |

---

## ANOMALIES / POINTS D'ATTENTION

### Anomalie mineure — A3 : `kamctl ul show` non fonctionnel en conteneur
**Impact** : zéro sur le fonctionnel SIP. Limitation de vérification seulement.
**Contournement CHECK** : surveiller les logs edge lors d'un REGISTER test :
```bash
docker logs -f pbxcloud-edge-1 | grep -E "(REGISTER|200 OK|location)"
```

### Point vigilance — S3 : PasswordAuthentication SSH encore `yes`
**État** : 2 clés dans `authorized_keys` de `procom`. Recommandation non bloquante : passer à `no` dès validation accès par toutes les parties.
**Impact actuel** : accès brute-force SSH possible (atténué par nftables whitelist 3 IP + fail2ban sshd).

### Point vigilance — S2 : jail fail2ban SIP absente
**État** : normal à ce stade (différé, conforme plan OPS). À créer avant toute ouverture 5060 au-delà des 3 IPs.

### Piège nouveau documenté par OPS (#1) — nftables + Docker iptables-nft
Sur cette VM, Docker utilise **iptables-nft** : ses chaînes (`FORWARD`, `DOCKER`, `DOCKER-USER`) vivent dans `table ip filter`. Un `flush ruleset` ou `delete table ip filter` les efface → conteneurs sans Internet. La persistance nftables doit ne gérer QUE `chain mainchain` (`flush chain` uniquement, jamais la table entière). `/etc/nftables.conf` correctement réécrit, reboot-safe.

---

## VERDICT FINAL

| Zone | Verdict |
|------|---------|
| Infrastructure conteneurs (A1) | ✅ **GO** |
| Tenant Asterisk acme (A2) | ✅ **GO** |
| Signalisation Kamailio (A3) | ⚠️ **GO avec réserve** (kamctl FIFO indispo, fonctionnel non impacté) |
| Advertise / DNS (A4) | ✅ **GO** |
| Sécurité firewall (S6) | ✅ **GO** |

**→ VERDICT GLOBAL : GO pour tests SIP A5 (REGISTER + INVITE depuis un UA dans la whitelist)**

---

## SUITE — Tests A5 à déclencher

Pour valider complètement, depuis une IP whitelistée (86.219.153.123, 217.181.224.153 ou 195.135.34.181) :
1. **REGISTER** extension 201 ou 202 vers `pbx1-procom.dyndns.org:5060` → vérifier 200 OK + endpoint passe `Unavailable` → `Available`
2. **INVITE** 201 → 202 → vérifier établissement appel + flux RTP via rtpengine
3. **Autoprovisioning Yealink** (si nginx/serveur prov déployé) — différé, hors périmètre actuel

Commandes CHECK post-REGISTER :
```bash
docker exec pbxcloud-tenant-acme-1 asterisk -rx "pjsip show endpoints"
docker logs pbxcloud-edge-1 --tail 20 | grep -E "(REGISTER|200|location)"
```

MAIN à décider : cadrage tests A5 (softphone depuis 217.181.224.153 ?) ou passage direct à l'étape suivante (beta tenant, trunk, jail SIP).
