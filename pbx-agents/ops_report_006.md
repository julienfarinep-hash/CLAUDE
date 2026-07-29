# Rapport OPS #006 — Préparation trunk Sewan (firewall + .env + design registration)

**En réponse à** : `ops_task_007.md` (base `reference_trunk_sewan.md`)
**Rédigé par** : OPS — 2026-07-28 21:32
**Cible** : `80.251.100.175`, user `procom`+sudo

---

## STATUT
✅ **Préparation faite, RIEN activé** (conforme : mot de passe Sewan `PENDING`).
Firewall Sewan ajouté + persistant, `.env TRUNK_IP` mis à jour (edge **non rechargé**). Plan
registration détaillé ci-dessous, **à valider par MAIN avant `ops_task_008`**. Zéro régression.
⚠️ **2 points bloquants pour l'activation** relevés (ports inbound + RTP Sewan) — voir §Design et SUITE.

## ACTIONS CONCRÈTES

### 1. Firewall (fait, persistant)
- Sauvegarde : `/etc/nftables.conf.bak.avant-trunk-sewan`.
- Ajouté à `mainchain` (live + persisté, **sans flush de table**) :
  - v4 : `ip saddr 37.97.65.74 udp dport 5070 accept` + `tcp dport 5070 accept`
  - v6 : `ip6 saddr 2a02:c440:1000:608::74 udp dport 5070 accept` + `tcp dport 5070 accept`
- Intégrité vérifiée : `mainchain` 8 règles 5060 intactes, 6 chaînes `DOCKER*`, table `f2b` séparée. Pas d'ouverture mondiale.

### 2. `.env` (fait, edge NON rechargé)
- Sauvegarde : `~/pbx-cloud/.env.bak.avant-trunk-sewan`.
- `TRUNK_IP=0.0.0.0` → **`TRUNK_IP=37.97.65.74`**. Vérifié que l'edge en cours **n'a PAS** rechargé
  (0 occurrence de `37.97.65.74` dans le `kamailio.cfg` du conteneur actif) — conforme à la consigne.

## DESIGN REGISTRATION (proposition — NE PAS activer)

### Recommandation : **uac Kamailio** (côté edge)
Cohérent avec `reference_trunk_sewan.md` : Kamailio porte l'IP publique. **Tous les modules requis
sont DÉJÀ présents** dans l'image `pbxcloud/kamailio` → **aucun rebuild d'image nécessaire** :
`uac.so`, `db_text.so`, `auth.so`, `usrloc.so`, `sqlops.so` vérifiés présents.

**Fichiers à modifier** : `edge/kamailio/kamailio.cfg` (template) uniquement + 1 fichier DB db_text.
Comme la cfg est rendue au démarrage (entrypoint `sed`), il faudra **recréer le conteneur edge**
(pas seulement reload) pour réémettre le template modifié — à faire au cycle d'activation.

**Extrait de conf (placeholder, `PASSWORD=<pending>`)** :
```
# --- Socket dédié au trunk (voir POINT BLOQUANT #1) ---
listen=udp:80.251.100.175:5070 name "trunk"
listen=tcp:80.251.100.175:5070 name "trunktcp"

loadmodule "uac.so"
loadmodule "db_text.so"

modparam("uac", "reg_db_url", "text:///etc/kamailio/uacdb")
modparam("uac", "reg_contact_addr", "80.251.100.175:5070")   # Contact annoncé à Sewan
modparam("uac", "reg_timer_interval", 60)
modparam("uac", "reg_retry_interval", 30)
# Auth des INVITE sortants (challenge 407) :
modparam("uac", "credential", "sbc2:procom-groupesb-7523.tel.voip:PASSWORD=<pending>")
modparam("uac", "reg_keep_callid", 1)
```
**Table db_text** `/etc/kamailio/uacdb/uacreg` (1 ligne, mdp en clair → droits 600, monté en volume) :
```
l_uuid(str) l_username(str) l_domain(str) r_username(str) r_domain(str) realm(str) \
auth_username(str) auth_password(str) auth_ha1(str) auth_proxy(str) expires(int) flags(int) reg_delay(int)
sewan2:sbc2:procom-groupesb-7523.tel.voip:sbc2:procom-groupesb-7523.tel.voip:procom-groupesb-7523.tel.voip:\
sbc2:<pending>::sip:37.97.65.74:5070:600:0:0
```
**Routage** (à ajouter dans `kamailio.cfg`) :
- Entrant : dans `route[TENANT]`, la branche `$si == "@TRUNK_IP@"` (déjà présente, TRUNK_IP=37.97.65.74)
  → `route(DID_LOOKUP)` → remplir `DID_LOOKUP`/`extensions-inbound.conf` avec les SDA (PENDING).
- Sortant : le tenant fait `Dial(PJSIP/<num>@edge-trunk)` → l'INVITE arrive à Kamailio (src 172.28.0.x),
  Kamailio le route vers `$du = sip:37.97.65.74:5070` via la socket `trunk`, et sur **407** un
  `failure_route` appelle `uac_auth()` puis `t_relay()`.

**Extrait failure_route (placeholder)** :
```
t_on_failure("TRUNK_AUTH");
...
failure_route[TRUNK_AUTH] {
    if (t_check_status("401|407")) {
        if (uac_auth()) { t_relay(); }
    }
}
```

### Alternative : registration côté **Asterisk** (PJSIP `[registration]`/`[auth]` sur un tenant)
- Faisable mais **limites** : le Contact serait l'IP conteneur `172.28.0.x` (injoignable de Sewan) ;
  il faudrait que l'edge réécrive Contact + relaie le REGISTER, et gère le NAT — on **réintroduit la
  complexité qu'on voulait mettre dans Kamailio**. De plus le trunk deviendrait mono-tenant.
  → **Non recommandé** ici. uac Kamailio garde le trunk mutualisé et l'IP publique au bon endroit.

## POINTS BLOQUANTS pour l'activation (à trancher par MAIN)
1. **Port inbound / cohérence firewall** : la règle firewall ouvre **notre dport 5070** pour Sewan.
   Pour que les **INVITE entrants** de Sewan soient acceptés, Kamailio doit **écouter sur :5070** et
   **enregistrer son Contact en :5070** (c'est le design proposé ci-dessus). Sinon Sewan enverrait vers
   :5060 (non ouvert pour son IP) → appels entrants droppés. **Le design est aligné sur ce choix de port.**
2. **RTP Sewan non ouvert** : la plage `30000-30999` n'est ouverte QUE pour les 3 IP admin, **pas pour
   les serveurs média Sewan**. En l'état, **le média entrant/sortant du trunk serait droppé**. Il faudra
   ajouter en whitelist la (les) **plage(s) média Sewan** (à demander : souvent un sous-réseau distinct de
   37.97.65.74) pour `udp dport 30000-30999`. **À fournir avant activation.**
3. **Données PENDING** : mot de passe `sbc2`, SDA→tenant, format CLI sortant, et confirmation que
   `80.251.100.175` est bien déclarée côté portail Sewan.

## NON-RÉGRESSION
- Conteneurs `edge`, `rtpengine`, `tenant-acme`, `tenant-beta` **UP** ; jail `kamailio-sip` **ACTIVE**.
- Endpoints acme 201/202 + beta 301/302 présents. Firewall/Docker/jail intacts.
- `PasswordAuthentication` non touché, whitelist maintenue, aucun register émis.

## SUITE → attendu de MAIN (pour `ops_task_008`)
1. Valider le **design uac Kamailio** + le choix **socket :5070 dédié au trunk** (point bloquant #1).
2. Fournir : **mot de passe Sewan**, **plage média Sewan** (point bloquant #2), **SDA→tenant/ext**.
3. À l'activation : je modifierai `kamailio.cfg` (+ db_text uacreg, droits 600), **recréerai l'edge**,
   ouvrirai le RTP Sewan, puis vérifierai `uac_reg` (`kamcmd uac.reg_dump`) = registration active.

**Tâche `ops_task_007.md` : TRAITÉE (préparation + design ; activation en attente MAIN).**
