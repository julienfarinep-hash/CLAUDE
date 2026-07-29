# Rapport OPS #005 — Tenant beta déployé

**En réponse à** : `ops_task_006.md`
**Rédigé par** : OPS — 2026-07-28 20:45
**Cible** : `80.251.100.175`, user `procom`+sudo

---

## STATUT
✅ **Tenant `beta` UP (172.28.0.12), endpoints 301/302 présents. Zéro régression acme.**
Déploiement rapide : l'image `pbxcloud/asterisk` étant déjà construite, beta la **réutilise**
(pas de recompilation). Le mapping Kamailio 3xx était **déjà en place** → aucun reload edge nécessaire.

## ACTIONS
1. **Pré-vérif** (beta déjà décrit dans les sources d'origine) :
   - `registry.txt` : `beta 172.28.0.12 3` ✅
   - `tenants/beta/pjsip.conf` : endpoints `301`, `302` ✅
   - `edge/kamailio/tenants.cfg` : route **déjà** présente —
     `if ($rd == "beta.@SIP_DOMAIN@") { $var(tip)="172.28.0.12" }` **et** `if ($var(u) =~ "^3") { $var(tip)="172.28.0.12" }`.
   → **Aucune conf éditée ce cycle**, donc pas de `.bak` ni de `reload` edge à faire (mapping 3xx déjà actif).
2. **Démarrage** : `docker compose -f docker-compose.yml -f docker-compose.tenants.yml up -d --build tenant-beta`
   (image en cache → build instantané, conteneur créé + démarré).

## ÉTAT VÉRIFIÉ
```
docker ps :
  pbxcloud-tenant-beta-1  | Up      <-- NOUVEAU, 172.28.0.12
  pbxcloud-tenant-acme-1  | Up
  pbxcloud-edge-1         | Up
  pbxcloud-rtpengine-1    | Up
```
- **beta** @ **172.28.0.12** ; `pjsip show endpoints` → **301** et **302** (état `Unavailable` = aucun UA
  enregistré, normal).
- **Mapping Kamailio** : préfixe `3xx → 172.28.0.12` (+ domaine `beta.pbx1-procom.dyndns.org`) déjà routé.
- **Non-régression acme** : endpoints 201/202 toujours présents, conteneur acme UP.
- **Firewall / sécurité intacts** : `mainchain` = 8 règles 5060, 6 chaînes `DOCKER*`, **jail `kamailio-sip`
  toujours ACTIVE**, sockets 5060 (pub+int) en écoute.
- **Interdits respectés** : whitelist 3 IP, `TRUNK_IP=0.0.0.0`, `PasswordAuthentication` non touché.

## PROBLEMES
- **Aucun.** RAS.

## SUITE
- **→ CHECK** : beta prêt pour validation + **test d'isolation inter-tenant**. Note utile pour le test :
  le `request_route` Kamailio **remet `$var(tip)` à `none` à chaque requête** (commentaire source :
  « sans ce reset, une requête hériterait de la cible précédente => fuite inter-clients »), et
  l'aiguillage se fait par domaine SIP puis par préfixe (2xx→acme / 3xx→beta). L'isolation repose donc
  sur ce routage + les contextes Asterisk distincts (`acme-internal` / `beta-internal`).
- Extensions montrées `Unavailable` tant qu'aucun softphone (depuis une IP whitelistée) ne s'enregistre —
  cohérent avec l'état pré-production.

**Tâche `ops_task_006.md` : TRAITÉE.**
