# Synthèse pilote — projet PBX cloud

**Cible** : VM Debian 13, IP `80.251.100.175`, domaine `pbx1-procom.dyndns.org`
**Approche** : stack **conteneurisée** `pbx-cloud` (edge Kamailio+rtpengine en host + 1 Asterisk 21/tenant, bridge 172.28.0.0/24)
**Pilote (MAIN)** : orchestration OPS + CHECK via `/home/julien/discussion`
**CANAL = GitHub `CLAUDE/pbx-agents/`** (depuis 2026-07-29 — voir PROTOCOLE_ECHANGE.md). Le dossier local n'est plus le canal.
**Dernière mise à jour** : 2026-07-29 — SORTANT: 200 OK + CLI SDA OK ; reste AUDIO (coupure ~6s = timeout RTP)

## Bascule canal
- ✅ **OPS opérationnel sur GitHub** (ops_ready_github.md) — pull/push OK, reprend **ops_task_017** (fix sortant
  `force_send_socket :5070` pour le 482) → rapport attendu `ops_report_014.md` (cible 200 OK Sewan).
- ✅ **CHECK opérationnel sur GitHub** (check_ready_github.md). Les 3 agents sont sur le canal GitHub.
- MAIN : opère via `~/.pbx_gh.py` (pull avant lire / push après écrire).
- **3 agents sur GitHub, alignés.** CHECK a validé la non-régression (check_report_007 = GO).

## SORTANT — état (cycle GitHub)
- Fix socket `:5070` (ops_task_017) : **appliqué et efficace** (Via/source = :5070). Mais **482 persiste**.
- Cause finale (capture OPS, confirmée CHECK) : `uac_auth()` en failure_route ré-émet l'INVITE avec le **même CSeq**
  → Sewan = 482 Request Merged.
- **Correctif = Option B (ops_task_019, VALIDÉ)** : auth trunk **côté Asterisk** (`outbound_auth` sur edge-trunk) →
  CSeq incrémenté nativement. Kamailio garde register uac + socket :5070, ne fait plus l'uac_auth INVITE.
  Rendu attendu `ops_report_015.md` (viser 200 OK). Puis appel mobile réel + entrant.

## ⏸ PAUSE ORCHESTRATION (Julien) — reprise après redéfinition du mode MAIN/OPS/CHECK
MAIN ne pilote plus de nouvelle étape tant que le nouveau fonctionnement n'est pas défini.
**Point de reprise trunk (à ne pas perdre)** :
- Register Sewan **actif** (Phase 1 close). 2 tenants acme/beta OK. ignoreip fail2ban posé.
- **Sortant** : cause du non-fonctionnement = Sewan `482 Request Merged` (INVITE via :5060/Via 172.28.0.1 ≠
  registration :5070). **Correctif validé** = `force_send_socket udp:80.251.100.175:5070` (ops_task_017, était en application).
  → à la reprise : vérifier ops_report_014 (Sewan 200 OK ?), puis vrai appel mobile + test ENTRANT (SDA +33339571241→acme 201&202).
- Données trunk : reference_trunk_sewan.md (sbc2 / realm=domaine / 37.97.65.74:5070 / RTP 37.97.65.74/32 / mobile +33642224323 / 2 canaux).

---
(historique ci-dessous)

---

## Avancement global
```
[✓] Recon VM + accès établi        [✓] Grille de validation définie (CHECK)
[✓] Déploiement edge+rtpengine+tenant acme UP   [✓] Passage à blanc CHECK = GO (18:37)
[✓] Tenant acme VALIDÉ bout-en-bout (signalisation + RTP écho, port 30818)   [✓] Jail fail2ban SIP S2 posée
[✓] Tenant beta VALIDÉ bout-en-bout   [✓] Isolation inter-tenant INTACTE (4 vecteurs → 4xx)   [✓] Non-régression acme
[✓] Trunk : firewall Sewan ouvert, .env TRUNK_IP, design uac VALIDÉ, mdp sbc2 reçu, IP déclarée Sewan, SDA reçu
[✅] PHASE 1 TRUNK **CLOSE & PROUVÉE** : capture REGISTER→401→200 OK, expires=600, realm=domaine confirmé, 0 erreur.
[✅] INCIDENT ÉLUCIDÉ (post-mortem OPS, journaux) : ban fail2ban jail `sshd` de l'IP admin (échec auth PASSWORD à
     22:15, bantime 7 j persistant → RST port 22, sshd jamais tombé). Fix racine = `ignoreip` 3 IP admin (toutes jails).
[⚠️ CORRECTION MAIN] Mon diag « sshd down » était FAUX (ban par-port = 22 refusé mais 5060 ouvert). CHECK avait raison.
[✅] État sain : 4 conteneurs UP, jails actives, nftables persisté (SSH+5060+5070 Sewan+bridge), tenants endpoints OK.

## Cycle #22 (08:50) — PHASE 2 lancée (toutes données reçues)
Données Julien : **RTP Sewan `37.97.65.74/32`**, **sortant E.164** (CLI `+33339571241`), **SDA `+33339571241`→acme 201&202**.
- **ops_task_015** (GO) : whitelist RTP 37.97.65.74/32 ; entrant DID_LOOKUP SDA→acme + extensions-inbound Dial(201&202) ;
  sortant E.164→edge-trunk + failure_route uac_auth + CLI ; `.bak`+`kamailio -c`+recréer edge ; 0 régression.
- **check_task_008** (armée) : **test appel réel** — nécessite le **mobile de Julien** (appeler le SDA + recevoir un sortant).
- En parallèle : ops_task_014 (preuve REGISTER↔200) + check_task_007 (non-régression) encore en cours.
- **Backlog hardening approuvé** : bantime sshd 7j→1h + persistance bans ; accès clé only (bannir sshpass) ; S3.

## 📞 TEST APPEL RÉEL — MAINTENANT (cycle #24)
Config Phase 2 en place (ops_report_012), register actif, 0 régression. **CHECK #008** : enregistre 201/202,
auto-répond+RTP, écoute logs edge. **Attendu de Julien** : (1) appeler `+33339571241` depuis son mobile
(entrant → doit sonner 201/202 + audio), (2) fournir un **n° mobile cible** pour le test sortant depuis 201 (CLI +33339571241).
Points à relever en live : forme réelle du SDA, RURI/From acceptés par Sewan, audio bidirectionnel rtpengine.
Caveat : DID_LOOKUP édité à la main dans tenants.cfg (render.sh l'écraserait → porter dans registry.txt plus tard).

## ⚠️ Cycle #25 (09:06) — CHECK silencieux
CHECK sans rapport depuis check_report_006 (hier, incident). check_task_007/008 sans rendu → **check_task_009**
(relance immédiate) : confirmer session active + faire le **test SORTANT d'abord** (201 → +33642224323, CLI +33339571241)
puis entrant. Mobile Julien = `+33642224323`. Limite **2 canaux** (tests séquentiels).
Si CHECK ne répond pas au prochain cycle → possible session CHECK morte → prévenir Julien (relance manuelle).

## Cycle #26 (09:10) — CHECK repris (avait pausé sa boucle pour tokens)
CHECK a déposé `check_alive_20260729.md` : session active, exécute check_task_009 (test SORTANT).

## 🔴 Cycle #27 (09:15) — SORTANT KO : mobile ne sonne pas
Retour Julien : appel sortant 201→+33642224323 **ne fait pas sonner** le mobile. CHECK en debug.
Diagnostic lancé (capture, seul OPS a docker/sudo) :
- **ops_task_016** : tcpdump trunk (host 37.97.65.74) + logs Asterisk acme, pendant que CHECK rejoue l'appel.
  Distinguer couche **A (Asterisk : dialplan `_+33X.` matche ? edge-trunk ?)** vs **B (Kamailio→Sewan : 407/auth/403/404/488)**.
- **check_task_010** : CHECK rejoue le sortant sous capture + reporte le **code SIP reçu par 201** (404 immédiat=couche A ;
  sonnerie puis échec=couche B) + teste variantes numéro (+33642224323 / 0642224323 / 33642224323).
Entrant en pause tant que le sortant n'est pas compris. Register + non-régression restent OK.

## Cycle #28 (09:26) — Cause sortant identifiée + correctif validé
Trace OPS (ops_report_013) : couche A (Asterisk) OK ; **Sewan renvoie `482 Request Merged`** à l'INVITE authentifié.
Cause : l'INVITE sort par **:5060 / Via 172.28.0.1** (bridge privé) ≠ registration **Contact :5070** → Sewan merge.
**Correctif VALIDÉ (ops_task_017)** : `force_send_socket udp:80.251.100.175:5070` sur la branche trunk + Contact :5070.
Re-test via `originate` sous capture (viser 200 OK), puis vrai appel mobile (sonnerie+audio), puis ENTRANT.
[⏸] Trunk PHASE 2 (appels) — manque : plage RTP Sewan + format sortant + confirmer SDA→tenant
[ ] Hardening SSH (PasswordAuth no)   [ ] failure_route Kamailio anti-bruteforce (backlog approuvé)   [ ] Autoprov nginx
[ ] Tests SIP réels (REGISTER / appel interne)   [ ] Multi-tenant   [ ] Trunk opérateur
```

## Sessions
| Agent | État | Dernier livrable |
|-------|------|------------------|
| OPS   | 🟢 en ligne | ops_report_001.md (recon) — travaille sur task #002 (déploiement) |
| CHECK | 🟢 en ligne | check_report_001.md (grille) + audit — attend signal OPS pour task #002 |

## État VM (recon convergente OPS + CHECK)
- Debian 13 trixie, kernel 6.12, 4 vCPU, 7,8 Gio RAM, 67 Gio disque (2 Gio utilisés) — **vierge côté PBX**.
- Accès : user **`procom`** (clé `id_pbxcloud` + mot de passe ; `sshpass` OK sur cette VM ; root désactivé).
- sudo : **avec mot de passe** (pas de NOPASSWD) — détenu par la session OPS.
- Sécurité de base **bonne** : nftables policy DROP, SSH whitelist 3 IP (86.219.153.123 / 217.181.224.153 / 195.135.34.181), fail2ban sshd actif, NTP synchronisé, `PermitRootLogin no`.
- Docker : absent (à installer via `tools/bootstrap-vm.sh`).

## Décisions du pilote ce cycle
1. **Architecture conteneurisée confirmée** — la divergence « natif vs conteneurs » soulevée par OPS est tranchée (conteneurs).
2. **Correctif `.env`** imposé à OPS : `PUBLIC_IP` doit passer de `178.170.25.68` (ancienne VM) → `80.251.100.175`.
3. **Bootstrap avec `OPEN_SIP=1` + whitelist IP** (pas d'ouverture mondiale) — indispensable car ce flag pose aussi les règles bridge **S6** (sans quoi tenants sourds).
4. **Hardening différé** : on NE passe PAS `PasswordAuthentication no` maintenant (filet de sécurité tant que la clé n'est pas confirmée stable partout).

## ⚠ Anomalie détectée (vérif indépendante MAIN, 18:23)
Base OK : Docker 29.6.2 installé, sources transférées, `.env` PUBLIC_IP=80.251.100.175. **Mais** :
- Le build `docker compose up --build rtpengine edge` (actif à 18:18) **ne tourne plus** et
  **n'a produit AUCUNE image** (`docker images` vide, cache buildx vide, 0 conteneur).
- Aucune session OPS connectée à la VM au constat ; `~/.bash_history` montre des commandes
  hors-sujet (`mkdir /home/discussion` sur la VM, `ssh-copy-id` malformé) → possible détour.
- Interprétation : **build probablement échoué/interrompu**. → `ops_task_003.md` (probe) émise pour
  obtenir le diagnostic/erreur avant tout correctif.

## ⚑ Correction du cycle #5 — FAUX POSITIF levé
Mon alarme « build calé / 0 image » était **fausse** : `procom` n'est PAS dans le groupe `docker`,
mes lectures `docker … 2>/dev/null` masquaient l'erreur *permission denied* → j'ai cru voir « vide ».
**Réalité (CHECK, autoritaire, 18:29)** : les images sont buildées, `rtpengine` **UP**, `edge` build et
tourne mais **crash-loop**. → MAIN ne peut PAS inspecter Docker sans sudo (pas le mot de passe) :
**CHECK/OPS = source de vérité** sur les conteneurs. Plan « MAIN build diagnostic » annulé (infaisable + inutile).

## État réel du déploiement (CHECK #002, 18:29)
| Élément | État |
|---------|------|
| rtpengine | ✅ UP, socket NG 22222 OK |
| edge (Kamailio) | ❌ **crash-loop exit 255** : `bind 172.28.0.1: Cannot assign requested address` |
| tenant acme | ❌ non démarré |
| Cause | réseau `pbxcloud_pbxnet` jamais créé (edge+rtpengine en host → rien ne rejoint le bridge → gw 172.28.0.1 non assignée) |
| `.env` / S6 bridge / whitelist / advertise | ✅ tous corrects |

## Cycle #7 (18:47) — STACK GO
CHECK #002b (18:37) = **GO** : rtpengine + edge + tenant-acme (Asterisk 21.12.3) UP, bridge pbxnet OK,
5060 en écoute (pub+int), advertise/DNS/whitelist/S6 tous corrects. Endpoints 201/202 présents.
- edge crash-loop **résolu** (Option A appliquée par OPS à 18:35, avant même ops_task_004).
- Élément clé appris : la 1ʳᵉ panne build venait d'un `nft flush ruleset` d'OPS qui effaçait les
  chaînes Docker (iptables-nft) → corrigé, `/etc/nftables.conf` ne gère plus que `mainchain`, reboot-safe.
- Les commandes bizarres du bash_history (mkdir /home/discussion, ssh-copy-id) = **tentatives humaines
  antérieures**, pas OPS. Sujet clos.

## Cycle #9 (20:43) — TENANT ACME 100% VALIDÉ + SÉCU S2
- **CHECK #004 (RTP)** : INVITE echo 600 → 200 OK, SDP média **80.251.100.175:30818** (rtpengine), écho
  confirmé (148 paquets envoyés / 201 reçus), rtpengine ancre bidirectionnel (client↔rtpengine↔172.28.0.11).
  **Tenant acme validé bout-en-bout : réseau + conteneurs + signalisation + dialplan + média.**
- **OPS #004 (jail S2)** : jail `kamailio-sip` active (backend systemd/journald sur logs edge = seul point
  qui voit l'IP réelle `$si`), ban dans table dédiée `inet f2b-table` (mainchain + Docker intacts),
  filtre anti-scanner 0 faux positif, ban/unban testés.

## Cycle #10 (20:46) — beta déployé, validation en cours
- **OPS #005** : tenant **beta UP** @172.28.0.12 (ext 301/302), image réutilisée (build instantané),
  mapping Kamailio 3xx déjà présent, **0 régression acme**, jail SIP toujours active. RAS.
- **CHECK #005** (en cours) : va exécuter 4 vecteurs d'isolation (V1 préfixe / V2 sous-domaine beta /
  V3 inverse / V4 REGISTER cross-tenant) — attendu 4xx sur tous ; + REGISTER 301 + echo beta + non-régression acme.
  Mécanisme d'isolation = routage Kamailio (domaine puis préfixe, `$var(tip)` remis à `none` par requête) +
  contextes Asterisk distincts + auth par endpoint.

## Cycle #12 (21:16) — MULTI-TENANT VALIDÉ
CHECK #005 = **GO** : beta bout-en-bout (REGISTER 301 + écho RTP port 30228), **isolation intacte 4/4
vecteurs** (V1-V4 → 4xx), non-régression acme OK. Le retard venait d'un faux positif V1 dû au script
CHECK (socket UDP partagé, réponse non filtrée par Call-ID) — re-testé proprement = 401, isolation réelle.
Leçon : tout script de test SIP doit filtrer par Call-ID.

## ⏸ BLOCAGE HUMAIN — trunk Sewan
Prochaine grande étape = brancher le trunk opérateur. **Nécessite les infos Sewan de Julien** (SDA/n° tête,
IP/FQDN du SBC, mode register vs IP statique + identifiants, TLS/ports). Demande posée à Julien ce cycle.
Rappel mémoire : sur l'ancienne VM, le trunk sbc2 était bloqué côté Sewan (support requis) — à confirmer
pour cette IP publique 80.251.100.175 (déclaration Sewan ?).

## Décision Julien (cycle #12) : PRIORITÉ = TRUNK SEWAN, il fournit les infos
Analyse sources trunk faite :
- Sources = trunk **mode IP statique** (`$si == @TRUNK_IP@` entrant → DID_LOOKUP ; sortant via `trunk-edge`).
- `DID_LOOKUP` (tenants.cfg) et `extensions-inbound.conf` = **stubs vides** à remplir avec les SDA.
- ⚠️ **Pas de registration/TLS Sewan dans le code** ; la maquette 90.178 était en TLS+register (TRUNKFSC8/sbc2
  → 37.97.65.74:5073). Si Sewan impose register pour 80.251.100.175 → **dev additionnel** (uac register + TLS).

### Infos demandées à Julien (bloquant trunk)
1. Mode (IP statique vs registration) · 2. SBC (IP/FQDN:port/transport) · 3. Si register: id+mdp+realm ·
4. SDA→tenant/extensions · 5. Format sortant + CLI · 6. IP 80.251.100.175 déjà déclarée Sewan ?

## Cycle #13 (21:20) — Trunk Sewan : infos partielles reçues
Params dans `reference_trunk_sewan.md`. **Mode = REGISTRATION** (domaine `procom-groupesb-7523.tel.voip`,
user `sbc2`, SBC `37.97.65.74:5070` UDP/TCP, pas de TLS). Non couvert par les sources (câblées IP statique).
- **OPS #007** (en cours) : ouvre le firewall vers Sewan (5070, IPv4+IPv6, whitelist), passe `.env` TRUNK_IP=
  37.97.65.74, et **propose un plan d'implémentation registration** (uac Kamailio recommandé) SANS l'activer.
- **Bloquants restants côté Julien** : (1) mot de passe Sewan à générer/fournir, (2) SDA/têtes entrantes →
  tenant+extensions, (3) format numéro sortant + CLI.
- Ensuite : MAIN valide le plan → ops_task_008 (activer register + config entrant/sortant) →
  check_task_006 (appel entrant SDA + sortant réels).

## Cycle #14 (21:33) — Design trunk VALIDÉ, activation gelée sur 4 données
- **OPS #006** : firewall Sewan ouvert (5070 UDP/TCP v4 `37.97.65.74` + v6 `2a02:c440:1000:608::74`, whitelist,
  `.bak`, persistant, pas de flush) ; `.env TRUNK_IP=37.97.65.74` (edge NON rechargé) ; 2 tenants UP, jail active.
- **Design registration validé MAIN** : uac Kamailio (modules déjà présents, pas de rebuild), socket dédiée
  `:5070`, db_text `uacreg` (droits 600), failure_route `uac_auth` pour le sortant. Asterisk-side écarté.
- **ops_task_008 créée mais GELÉE** — activation dès réception des 4 données Julien.
- **⚠️ Nouveau bloquant (OPS)** : la **plage média RTP Sewan** doit être whitelistée (30000-30999 n'est ouvert
  qu'aux 3 IP admin) sinon le média trunk est droppé.

## Cycle #15 (21:40) — mdp + SDA reçus → register Phase 1
- ✅ Reçu : mot de passe `sbc2` (`Fe3usQ3lESOO`, dans reference), **IP déclarée Sewan OUI**, **SDA `+33339571241`**.
- **ops_task_008 dégelée = PHASE 1 register seul** : socket :5070 + uac + db_text uacreg (600) + kamailio -c +
  recréer edge + prouver `uac.reg_dump` register actif. Appels NON configurés (Phase 2).
- **check_task_006** : CHECK vérifiera la registration (200 OK Sewan) + non-régression tenants.
- **✅ REALM confirmé = domaine** `procom-groupesb-7523.tel.voip` (Julien). Valeur figée dans uacreg + credential.

## Cycle #16 (22:12) — register pas encore exécuté, relance
- `ops_report_007` (OPS 21:36) était **périmé** : attendait les 4 données alors que le register ne dépend
  QUE du mot de passe. Vérif MAIN indépendante : **`:5070` n'écoute pas** → Phase 1 non exécutée.
- **ops_task_009 émise (priorité immédiate)** : lève l'ambiguïté, exécute le register seul MAINTENANT
  (mdp présent), RTP/SDA/format = Phase 2 non bloquants. Rendu attendu `ops_report_008.md`.

## 🔴 Cycle #17 (22:18) — INCIDENT SSH (sshd down)
- **Port 22 = Connection refused (RST)** depuis l'IP admin, confirmé par MAIN + CHECK. VM UP (ping OK).
- **Localisation MAIN** : `5060` **OPEN depuis notre IP** → firewall intact, **IP toujours whitelistée**,
  Kamailio UP. Donc **sshd est DOWN** (pas un retrait de whitelist — hypothèse CHECK écartée).
- Cause probable : sshd arrêté/planté pendant l'exécution Phase 1 (recréation edge / opérations OPS).
- **MAIN, CHECK et OPS sont TOUS lockout SSH** (OPS l'a confirmé à Julien) — aucune session réutilisable.
- **Récupération = console hors-bande Sewan** (action Julien). Étapes dans `ops_task_010.md` :
  `systemctl status ssh` → `journalctl -u ssh` → `sshd -t` → `systemctl restart ssh` → `ss -tlnp | grep :22`.
- Le service téléphonie n'est PAS impacté (5060 up) — c'est l'accès d'administration qui est perdu.
- **Décision : Julien reboote la VM via le portail Sewan.** Attendu au retour : sshd up, 4 conteneurs up
  (restart policy), firewall/jails persistés, 2 tenants sains, **edge SANS trunk** (config d'origine).
- **ops_task_011** (post-reboot) : post-mortem cause sshd (`journalctl -u ssh --boot=-1`) + état sain +
  **NE PAS rejouer le trunk** tant que la cause n'est pas comprise. Puis reprise Phase 1 sécurisée.
- ⚠️ Risque : perte des logs de la cause si journald non persistant → tenter boot précédent.

## 🔴 RESTE À FOURNIR (Phase 2 = appels réels)
1. **Plage(s) IP média RTP Sewan** — bloque l'AUDIO (sinon RTP droppé). Souvent sous-réseau distinct de 37.97.65.74.
2. **Format numéro sortant** (E.164 `+33…` / `0X…`) + **CLI présenté**.
3. **Confirmer** que le SDA `+33339571241` doit sonner **acme (201 & 202)** [défaut proposé] ou un autre tenant.
- **Backlog approuvé (non urgent, avant ouverture ports)** : `failure_route` Kamailio loggant l'IP réelle
  sur 403 confirmé → 2ᵉ failregex fail2ban anti-bruteforce d'extension valide (additif, `.bak` + `kamailio -c`).
- **À suivre** : trunk opérateur Sewan (nécessite creds/config Sewan — étape humaine probable), hardening SSH.

## Blocages ouverts
- Aucun blocage bloquant. Points de vigilance non urgents :
  1. [S3] SSH `PasswordAuthentication yes` — hardening différé (décision MAIN), atténué par whitelist+fail2ban.
  2. [A3] `kamctl ul show` indispo en conteneur (limitation outillage, fonctionnel non impacté ; vérif via logs).
  3. [A5] test SIP réel peut nécessiter un softphone humain si CHECK ne peut installer d'UA (poste admin whitelisté).

## Points de vigilance à surveiller aux prochains cycles
- **S6** (règles bridge 172.28.0.0/24) : bloquant fonctionnel — CHECK doit le confirmer post-déploiement.
- **S2** (jail fail2ban SIP) : à créer une fois Kamailio exposé.
- Ouverture des ports : garder **whitelist** jusqu'à validation explicite de Julien avant tout monde-ouvert.
- `advertise` Kamailio doit refléter `80.251.100.175` (pas l'ancienne IP).

## Prochain cycle
Lire `ops_report_002.md` / `check_report_002.md`. Si edge+tenant UP et passage à blanc GO →
émettre tâches de test SIP réel. Sinon, émettre tâche OPS corrective ciblée sur l'écart signalé.
