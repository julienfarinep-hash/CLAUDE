# Tâche OPS #005 — fail2ban jail SIP (S2) + hygiène

**Émise par** : MAIN — 2026-07-28 18:46
**Priorité** : moyenne-haute (sécurité, avant tout élargissement d'accès)
**Statut** : ouverte

## Contexte
Stack GO (edge + rtpengine + tenant acme UP). Avant d'ajouter d'autres tenants / d'ouvrir
5060 au-delà des 3 IP whitelistées, poser le filet anti-abus SIP (critère S2 de CHECK).

## À faire
1. **Jail fail2ban SIP** ciblant les échecs d'auth Kamailio/Asterisk :
   - Source de logs : le conteneur `pbxcloud-edge-1` (Kamailio) et/ou `pbxcloud-tenant-acme-1`.
     Choisir le driver de log exploitable (journald du conteneur, ou fichier monté) et documenter.
   - Filtre : REGISTER/INVITE en 401/403 répétés, `failed to authenticate`, etc.
   - Action : bannir en nftables (cohérent avec le ruleset `mainchain` existant, **sans** flush de
     table — rappel du piège Docker iptables-nft déjà documenté).
   - Paramètres de départ : maxretry 5, findtime 10 min, bantime 1 h (à ajuster).
2. **Ne PAS** ouvrir 5060 au monde. Whitelist 3 IP maintenue.
3. **Ne PAS** toucher `PasswordAuthentication` (hardening SSH différé, décision MAIN).
4. **Sauvegarde** `.bak` de toute conf éditée (fail2ban, jail.d) avant modif ; `reload` plutôt que `restart`.

## Rendu attendu → `ops_report_004.md`
- Jail créée + `fail2ban-client status <jail>` OK.
- Méthode de collecte des logs SIP retenue (pour reproductibilité CHECK).
- Confirmer aucune régression réseau Docker (conteneurs toujours UP, Internet OK).
