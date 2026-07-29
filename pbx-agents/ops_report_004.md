# Rapport OPS #004 — Jail fail2ban SIP (S2) posée

**En réponse à** : `ops_task_005.md`
**Rédigé par** : OPS — 2026-07-28 18:58
**Cible** : `80.251.100.175`, user `procom`+sudo

---

## STATUT
✅ **Jail SIP `kamailio-sip` active et validée end-to-end** (ban/unban testés). Critère CHECK **S2
satisfait**. Aucune régression : les 3 conteneurs UP, 5060 (pub+int) en écoute, Internet conteneur OK,
mainchain PBX + chaînes Docker intactes.

## Décision d'architecture (importante pour CHECK)
**Kamailio ne fait PAS registrar/auth** (cf. `kamailio.cfg` : « Kamailio ne fait PAS registrar : il
relaie »). Conséquence : l'Asterisk d'un tenant ne voit comme source que le **bridge `172.28.0.1`**,
jamais l'IP réelle de l'attaquant → **bannir sur les logs Asterisk banirait le bridge** (inutile/dangereux).
La seule brique qui voit l'**IP réelle du client (`$si`)** est **Kamailio**. La jail lit donc les logs
**du conteneur edge (Kamailio)**.

## ACTIONS
1. **Collecte des logs** (méthode retenue, reproductible) :
   - Conteneur `pbxcloud-edge-1` basculé sur le driver **journald** (ajout `logging: driver: journald`
     dans `docker-compose.yml`, **`.bak` créé** : `docker-compose.yml.bak.avant-journald`, conteneur recréé).
   - fail2ban lit le journal en **backend `systemd`** avec `journalmatch = CONTAINER_NAME=pbxcloud-edge-1`
     → **stable après recréation** du conteneur (contrairement au fichier json-file dont le chemin
     contient l'ID de conteneur).
2. **Filtre** `/etc/fail2ban/filter.d/kamailio-sip.conf` ciblant les 2 signaux Kamailio qui portent
   l'IP réelle **et ne se déclenchent jamais pour un poste correctement configuré** (zéro faux positif) :
   - `aucun tenant pour <méthode> <ruri> (src <IP>)` → énumération / scanners (sipvicious & co).
   - `sanity: <méthode> de <IP> rejete` → SIP malformé / scan.
   - Validé par `fail2ban-regex` : **2 lignes échantillon, 2 matched, 0 missed**.
3. **Jail** `/etc/fail2ban/jail.d/kamailio-sip.conf` :
   - `maxretry=5`, `findtime=600` (10 min), `bantime=3600` (1 h) — conforme à la consigne.
   - `banaction = nftables-allports`.
   - Prise en compte par **`fail2ban-client reload`** (pas de restart, conforme).
4. **Test end-to-end** : `banip 198.51.100.77` → IP insérée dans la table **dédiée `inet f2b-table`**
   (`elements = { 198.51.100.77 }`) ; `unbanip` → set vidé. OK.

## POINT DE SÉCURITÉ CLÉ — piège Docker respecté
L'action `nftables-allports` bannit dans une **table nftables séparée `inet f2b-table`**, elle **ne
touche NI `table ip filter` (mainchain PBX) NI les chaînes Docker** (iptables-nft). Vérifié pendant
un ban actif : `mainchain` = 8 règles 5060 intactes, 6 chaînes `DOCKER*` présentes. **Aucun flush** —
le piège documenté au cycle #2 est évité.

## ÉTAT VÉRIFIÉ
```
fail2ban-client status  ->  jails: kamailio-sip, sshd
kamailio-sip            ->  backend systemd, journalmatch CONTAINER_NAME=pbxcloud-edge-1,
                            0 failed / 0 banned (aucun trafic hostile whitelisté pour l'instant)
```
- Conteneurs : `pbxcloud-edge-1`, `pbxcloud-tenant-acme-1`, `pbxcloud-rtpengine-1` **UP**.
- Écoute : `80.251.100.175:5060` udp+tcp (pub) + `172.28.0.1:5060` udp (int) — routage intra-tenant OK.
- `fail2ban` `enabled` au boot ; jail + filtre dans `/etc/fail2ban/{jail.d,filter.d}/` → persistants.
- `.env`, whitelist 3 IP, `TRUNK_IP=0.0.0.0`, `PasswordAuthentication=yes` : **inchangés** (interdits respectés).

## PROBLEMES
- **Aucun blocage.** RAS.

## SUITE — limite connue + proposition
- **Non couvert** par cette jail : le **brute-force de mot de passe** contre une extension **valide**
  (REGISTER 401→403 répétés). Raison : ce trafic est relayé vers Asterisk qui répond 401/403, mais
  l'IP réelle n'apparaît pas côté Asterisk (bridge), et Kamailio ne loggue pas aujourd'hui ces rejets
  avec `$si`.
- **Proposition (à valider par MAIN avant exécution)** : ajouter dans `kamailio.cfg` un
  `failure_route` qui, sur `t_check_status("403")` (échec d'auth **confirmé**, pas le simple challenge
  401 qui arrive à chaque REGISTER légitime), logge `SIP-AUTH-FAIL src $avp(realsrc)`. Un 2ᵉ failregex
  banni alors les vrais brute-forcers **sans** risquer de bannir un poste qui se ré-enregistre (le 401
  initial est normal). Modif additive + `.bak` + `kamailio -c` avant reload. **Non faite ce cycle**
  (édition de la conf Kamailio hors périmètre explicite de la tâche 005).
- **→ CHECK** : S2 posé, prêt pour re-vérif. La jail se déclenchera réellement dès qu'un scanner
  atteindra 5060 depuis une IP whitelistée (ou après ouverture plus large — non faite).

**Tâche `ops_task_005.md` : TRAITÉE.**
