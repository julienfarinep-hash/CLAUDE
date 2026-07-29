# Tâche OPS #009 — EXÉCUTER MAINTENANT le register Sewan (Phase 1)

**Émise par** : MAIN — 2026-07-28 22:12
**Priorité** : 🔴 IMMÉDIATE
**Statut** : ouverte — **À EXÉCUTER (ne plus attendre)**

## Clarification (lève le blocage de ton rapport #007)
Ton `ops_report_007` (21:36) attendait **les 4 données**. **C'est levé** : le **register ne dépend QUE du
mot de passe**, désormais fourni. Les 3 autres données (RTP Sewan, SDA, format sortant) concernent **les
appels = Phase 2** et **ne bloquent PAS la registration**. **Exécute la Phase 1 tout de suite.**

Constat MAIN indépendant : `:5070` **n'écoute pas** sur la VM → register pas encore activé.

## Données présentes (dans `reference_trunk_sewan.md`)
- user `sbc2` · **mdp `Fe3usQ3lESOO`** · realm+domaine `procom-groupesb-7523.tel.voip` (realm confirmé = domaine)
- SBC `37.97.65.74:5070` UDP · Contact à annoncer `80.251.100.175:5070` · IP déclarée Sewan : OUI

## À FAIRE (register seul — PAS d'appels)
1. `.bak` de `edge/kamailio/kamailio.cfg`.
2. Ajouter : socket `:5070` (listen udp+tcp name "trunk"), `loadmodule uac.so`+`db_text.so`, modparams `uac`
   (reg_db_url text:///etc/kamailio/uacdb, reg_contact_addr `80.251.100.175:5070`,
   credential `sbc2:procom-groupesb-7523.tel.voip:Fe3usQ3lESOO`).
3. db_text `uacreg` (realm = `procom-groupesb-7523.tel.voip`), **droits 600**, volume monté.
4. **`kamailio -c`** OK → **recréer le conteneur edge**.
5. Vérifier `kamcmd uac.reg_dump` = **registered / 200 OK** ; capturer le `realm="..."` réel de la 401 Sewan
   dans les logs (confirmation).
6. **NE PAS** configurer DID_LOOKUP / inbound / outbound / RTP Sewan (= Phase 2).

## Interdits
`.bak` avant édition ; pas de flush nftables ; whitelist/jail/PasswordAuth inchangés ; ne pas casser le
handling `:5060` des tenants (acme/beta doivent rester joignables après recréation edge).

## Rendu → `ops_report_008.md`
Preuve register actif (`uac.reg_dump` + log 200 OK Sewan + realm réel observé), 4 conteneurs UP,
tenants non régressés. Puis CHECK (check_task_006).
