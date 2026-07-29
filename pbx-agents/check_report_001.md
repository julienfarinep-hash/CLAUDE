# Rapport CHECK #001 — Grille de validation déploiement cloud
**Timestamp** : 2026-07-28 18:12
**Tâche** : check_task_001.md
**Agent** : CHECK
**Sources consultées** : PDF récapitulatif PBX01, /home/julien/pbx-cloud (docker-compose.yml, docker-compose.tenants.yml, bootstrap-vm.sh, .env.example)

---

## STATUT : GRILLE DÉFINIE — PREMIER PASSAGE À BLANC EFFECTUÉ

---

## RÉSULTATS — Grille de validation

### A. Invariants attendus une fois déployé

#### A1. Infrastructure conteneurs (edge)

| # | Invariant | Commande de contrôle (lecture seule) |
|---|-----------|--------------------------------------|
| 1 | Conteneur `rtpengine` (edge) UP en mode host | `docker ps --filter name=pbxcloud-rtpengine --format '{{.Status}}'` |
| 2 | Conteneur `edge` (Kamailio) UP en mode host | `docker ps --filter name=pbxcloud-edge --format '{{.Status}}'` |
| 3 | Réseau bridge `pbxnet` (172.28.0.0/24) existant | `docker network inspect pbxcloud_pbxnet \| grep -A2 Subnet` |
| 4 | Port 5060 UDP/TCP en écoute sur 0.0.0.0 | `ss -tulnp \| grep 5060` |
| 5 | Plage RTP 30000-30999 UDP accessible (rtpengine) | `ss -tulnp \| grep -E "3[0-9]{4}"` |
| 6 | Socket NG rtpengine sur 127.0.0.1:22222 | `ss -tulnp \| grep 22222` |

#### A2. Tenants Asterisk

| # | Invariant | Commande de contrôle |
|---|-----------|----------------------|
| 7 | Au moins 1 conteneur `tenant-*` UP | `docker ps --filter name=pbxcloud-tenant --format '{{.Names}} {{.Status}}'` |
| 8 | Tenant acme UP, IP 172.28.0.11 | `docker inspect pbxcloud-tenant-acme-1 \| grep -A2 IPv4` |
| 9 | Tenant beta UP, IP 172.28.0.12 | `docker inspect pbxcloud-tenant-beta-1 \| grep -A2 IPv4` |
| 10 | Asterisk interne répond (AMI ou CLI) | `docker exec pbxcloud-tenant-acme-1 asterisk -rx "core show version"` |
| 11 | Extension SIP enregistrée côté Asterisk | `docker exec pbxcloud-tenant-acme-1 asterisk -rx "pjsip show registrations"` |

#### A3. Signalisation SIP (Kamailio → Asterisk)

| # | Invariant | Commande de contrôle |
|---|-----------|----------------------|
| 12 | Kamailio voit les tenants dans sa table location | `docker exec pbxcloud-edge-1 kamctl ul show` |
| 13 | Kamailio route vers Asterisk acme (172.28.0.11) | `docker logs pbxcloud-edge-1 --tail 50 \| grep -E "(REGISTER\|INVITE\|200 OK)"` |

#### A4. DNS et domaine

| # | Invariant | Commande de contrôle |
|---|-----------|----------------------|
| 14 | `pbx1-procom.dyndns.org` → 80.251.100.175 | `dig +short pbx1-procom.dyndns.org` |
| 15 | Kamailio advertise PUBLIC_IP correct | `docker exec pbxcloud-edge-1 cat /etc/kamailio/kamailio.cfg \| grep advertise` |

#### A5. Test fonctionnel SIP (depuis un UA SIP externe)

| # | Test | Critère de succès |
|---|------|-------------------|
| 16 | REGISTER ext depuis UA SIP externe | 200 OK reçu, extension visible dans `kamctl ul show` |
| 17 | INVITE ext A → ext B (intra-tenant) | Appel établi, médias via rtpengine |
| 18 | Autoprovisioning Yealink (si nginx déployé) | GET `http://80.251.100.175:8888/<MAC>.cfg` → 200 + contenu `Config.Account1.*` |

---

### B. Critères sécurité minimaux (avant ouverture mondiale)

| # | Critère | Commande de contrôle | Requis avant ouverture |
|---|---------|----------------------|------------------------|
| S1 | fail2ban actif + jail sshd | `fail2ban-client status` | Oui |
| S2 | jail sip-kamailio (ou équivalent) active | `fail2ban-client status sip-kamailio` | **Oui — bloquant** |
| S3 | PasswordAuthentication SSH = no (si clé déployée) | `sshd -T \| grep passwordauthentication` | Oui si clés en place |
| S4 | PermitRootLogin = no | `sshd -T \| grep permitrootlogin` | Oui (déjà OK) |
| S5 | nftables : 5060 + RTP non exposés au monde sans filtre | `nft list chain ip filter mainchain \| grep 5060` | À vérifier avant ouverture |
| S6 | Règles bridge interne en place (172.28.0.0/24 → host) | `nft list chain ip filter mainchain \| grep 172.28` | **Obligatoire** — sans ça les conteneurs ne parlent pas à l'hôte |
| S7 | Pas de service non nécessaire exposé | `ss -tulnp \| grep -vE "(22\|5060\|30[0-9]{3})"` | Oui |

> **Point critique (bootstrap-vm.sh ligne 54-59)** : les paquets issus du bridge 172.28.0.0/24 vers 172.28.0.1 (l'hôte) traversent le hook INPUT nftables (policy DROP). Sans les règles permettant ce trafic, les postes s'enregistrent mais Asterisk ne reçoit pas les qualify → statut "Registered but Unavailable" + aucun appel entrant. Ce critère S6 est un **bloquant fonctionnel** à vérifier avant tout test d'appel.

---

## PREMIER PASSAGE À BLANC — État actuel vs attendu

### A. Infrastructure conteneurs

| Invariant | Attendu | Actuel | Écart |
|-----------|---------|--------|-------|
| Docker installé | Oui | **NON** | ❌ Non déployé |
| Conteneur rtpengine UP | Oui | **NON** | ❌ |
| Conteneur edge (Kamailio) UP | Oui | **NON** | ❌ |
| Bridge pbxnet 172.28.0.0/24 | Oui | **NON** | ❌ |
| Port 5060 en écoute | Oui | **NON** | ❌ |
| Plage RTP 30000-30999 | Oui | **NON** | ❌ |

### B. Sécurité

| Critère | Attendu | Actuel | Écart |
|---------|---------|--------|-------|
| S1 — fail2ban actif | Oui | **OUI** ✅ | OK |
| S1 — jail sshd | Oui | **OUI** ✅ bantime 7j, maxretry 5 |OK |
| S2 — jail sip-kamailio | Oui | **NON** ❌ | Kamailio absent |
| S3 — PasswordAuthentication no | Souhaitable | **PasswordAuthentication yes** ⚠️ | 2 clés en place → à passer à `no` |
| S4 — PermitRootLogin no | Oui | **OUI** ✅ | OK |
| S5 — 5060/RTP non exposés | Oui (pré-déploiement) | **OUI** ✅ ports fermés | OK |
| S6 — règles bridge 172.28 | Après déploiement | Non applicable | ⏳ à faire lors du bootstrap |
| nftables policy default DROP | Oui | **OUI** ✅ | OK |
| SSH whitelist 3 IPs | Oui | **OUI** ✅ | OK |

### C. DNS / réseau

| Point | Attendu | Actuel |
|-------|---------|--------|
| pbx1-procom.dyndns.org → 80.251.100.175 | Oui | **OUI** ✅ (confirmé pilote) |
| IP publique ens192 | 80.251.100.175 | **OUI** ✅ |
| Gateway | 80.251.100.1 | **OUI** ✅ |

---

## ANOMALIES

1. **Docker absent** — OPS doit exécuter `bootstrap-vm.sh` (ou équivalent) avant tout déploiement. La stack entière est conteneurisée.
2. **PasswordAuthentication yes** — 2 clés SSH sont déjà en place dans `authorized_keys` du compte `procom`. Recommandation à OPS : passer `PasswordAuthentication no` dans `/etc/ssh/sshd_config` + `systemctl reload sshd` dès que les accès par clé sont validés côté tous les intervenants.
3. **Règles bridge nftables (S6) manquantes** — à intégrer dans le bootstrap. Sans elles, les tenants Asterisk sont sourds malgré un enregistrement apparent.
4. **fail2ban sans jail SIP** — normal à ce stade, mais à configurer lors du déploiement de Kamailio. La jail devra filtrer les logs du conteneur edge (logdriver journald ou fichier).

---

## SUITE

- Attente rapport `ops_report_001.md` (reconnaissance + plan de déploiement OPS).
- Dès que Docker + conteneurs déployés : CHECK effectuera le passage à blanc complet (invariants A1-A5).
- Points à vérifier en priorité lors du premier déploiement : **S6** (règles bridge) et **S2** (jail SIP) avant tout test fonctionnel.
- Monitoring actif — prochain check_task traité dans la minute.

**Tâche check_task_001.md : TRAITÉE**
