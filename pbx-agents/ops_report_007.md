# Rapport OPS #007 — Trunk Sewan PHASE 1 (register) : config posée MAIS ACCÈS SSH PERDU

**En réponse à** : `ops_task_008.md` (Phase 1 register)
**Rédigé par** : OPS — 2026-07-28 22:20
**Cible** : `80.251.100.175`

---

## STATUT
🟠 **PHASE 1 quasi terminée côté config, mais INCIDENT D'ACCÈS en cours** : **le SSH (port 22)
de la VM ne répond plus** (`Connection refused`) depuis ~22:16, m'empêchant de fournir la **preuve
finale du 200 OK Sewan** et de poursuivre. **La VM et les services téléphonie sont UP** (ping OK,
TCP 5060 kamailio OPEN depuis mon IP) — c'est **sshd uniquement** qui est injoignable.

## CE QUI A ÉTÉ FAIT (avant la perte d'accès) — Phase 1 register
1. `.bak` de `edge/kamailio/kamailio.cfg` (→ `.bak.avant-uac`).
2. `kamailio.cfg` (template) modifié : **socket dédiée `:5070`** (listen udp+tcp name "trunk"),
   `loadmodule uac.so` + `db_text.so`, modparams uac (`reg_db_url text:///etc/kamailio/uacdb`,
   `reg_contact_addr @PUBLIC_IP@:5070`, `reg_timer_interval 60`, `credential` sbc2:realm:<mdp>).
   **Aucun routage inbound/outbound touché** (Phase 2 respectée).
3. `docker-compose.yml` : ajout volume `./edge/kamailio/uacdb:/etc/kamailio/uacdb:ro`.
4. Base **db_text `uacreg`** créée (schéma kamailio officiel, **version table = 5**, colonnes
   `auth_ha1`/`contact_addr` marquées `null`, colons des URI échappés `\:`), **droits 600**, mdp en place.
5. **`kamailio -c` = "config file ok"** (validé avant recréation). Image edge **rebuild** (le template
   est baké dans l'image, pas seulement monté) puis conteneur recréé.
6. **`kamcmd uac.reg_dump` = enregistrement CHARGÉ correctement** :
   `l_username=sbc2`, `r_domain=procom-groupesb-7523.tel.voip`, `auth_proxy=sip:37.97.65.74:5070`
   (colons déséchappés OK), `contact_addr=80.251.100.175:5070`, `socket=udp:80.251.100.175:5070`,
   `expires=600`, `diff_expires=588` (⇒ un expires a été négocié, cohérent avec un 200 OK).

➡️ **La registration est configurée et la table chargée.** Il me restait à **capturer le
REGISTER↔200 OK réseau** comme preuve formelle — c'est à ce moment que le SSH a coupé.

## INCIDENT — perte d'accès SSH (diagnostic)
- **Constat** : `nc 80.251.100.175 22` → **Connection refused** (RST, immédiat) ; ping OK ;
  **TCP 5060 OPEN** depuis mon IP ; TCP 22 refusé.
- **Ce n'est PAS le firewall PBX ni un ban global** : mon IP atteint toujours 5060 → `mainchain`
  intacte, IP non bloquée globalement. Le média/signalisation SIP fonctionnent.
- **Hypothèse #1 (la plus probable) — ban fail2ban jail `sshd` sur le port 22** avec action
  **reject** (⇒ RST = "refused", et seul le port 22 est visé, d'où 5060 encore ouvert). Déclencheur
  probable : les **tentatives d'auth SSH échouées antérieures depuis l'IP d'admin partagée**
  (essais de clés id_sewan/id_tunnel/id_esxi et login **root** par MAIN/CHECK, tous refusés — cf.
  ops_task_001/pilote) qui ont atteint `maxretry`. Le bantime sshd serait long (CHECK évoquait 7 j).
- **Hypothèse #2** — sshd tombé/planté (moins probable : systemd l'aurait relancé ; ~5 min sans retour).

## IMPACT
- **Aucun impact sur les services** : 4 conteneurs présumés UP (5060 répond), trunk registration
  chargée. Les tenants/appels internes ne sont pas affectés.
- **Impact OPS** : je ne peux plus opérer la VM (mon seul canal = SSH). Je ne peux ni prouver le
  200 OK, ni finaliser, ni corriger — **jusqu'à restauration de l'accès**.

## ACTION REQUISE (out-of-band — Julien / MAIN via console cloud)
Depuis la **console du fournisseur** (ou une **autre des 3 IP whitelistées** non bannie) :
1. Diagnostiquer : `systemctl status ssh` · `fail2ban-client status sshd` (voir si mon IP est bannie).
2. **Débannir** : `fail2ban-client set sshd unbanip <IP_admin>` (et/ou `fail2ban-client unban --all`).
3. **Prévenir la récidive** : ajouter l'IP d'admin dans `ignoreip` du jail sshd
   (`/etc/fail2ban/jail.d/…` ou `jail.local`) puis `fail2ban-client reload`.
4. Si sshd réellement down : `systemctl restart ssh`.
> ⚠️ **Ne PAS `flush` les tables nftables** (piège Docker iptables-nft déjà documenté) — le ban SSH
> est géré par fail2ban dans sa propre table, pas par `mainchain`.

## SUITE (dès accès rétabli — je reprends automatiquement)
1. Capturer le REGISTER↔**200 OK** vers `37.97.65.74:5070` (tcpdump) = preuve Phase 1.
2. Confirmer `uac.reg_dump` flags = online, zéro régression tenants (4 conteneurs UP, jail active).
3. Ajouter l'IP admin en `ignoreip` fail2ban (durci) pour éviter que ça se reproduise.
4. Mettre à jour ce rapport avec la preuve → puis CHECK (check_task_006).

- Mon watcher local continue de surveiller `ops_task_*` et `reference_trunk_sewan.md`. Un poll de
  reconnexion (port 22) tourne aussi : je détecte le retour de l'accès automatiquement.

**Tâche `ops_task_008.md` : PHASE 1 configurée (uacreg chargée) — FINALISATION BLOQUÉE par perte d'accès SSH. Escalade console requise.**
