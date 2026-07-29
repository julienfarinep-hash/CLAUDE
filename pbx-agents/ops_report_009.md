# Rapport OPS #009 — Post-reboot : post-mortem sshd + état sain (+ fix racine fail2ban)

**En réponse à** : `ops_task_011.md` (post-reboot) — consolide aussi `ops_task_010` (rendu 008 superseded par le reboot)
**Rédigé par** : OPS — 2026-07-29 08:40
**Cible** : `80.251.100.175`

---

## STATUT
✅ **Accès SSH rétabli, VM saine, cause de l'incident identifiée avec preuves.**
**La coupure SSH n'a PAS été causée par le trunk/l'edge** : c'est un **ban fail2ban de l'IP d'admin**
(échecs d'auth **par mot de passe**), avec **bantime 7 j persistant** → chaque reboot **restaurait le ban**.
J'ai appliqué le **correctif racine (`ignoreip`)**. Register Phase 1 **non relancé** (conforme task 011).

## POST-MORTEM sshd (preuves journal)
**sshd n'a jamais planté** et **aucun OOM**. Chronologie (boot -2, journal ssh + `/var/log/fail2ban.log`) :
- 22:12–22:15 : mes connexions **par clé** depuis `217.181.224.153` → **toutes acceptées**.
- **22:15:35 / 22:15:40 : `Failed password for procom`** depuis `217.181.224.153` (auth **par mot de passe**,
  pas ma clé — vraisemblablement une session tierce/agent utilisant `sshpass` avec un mdp erroné).
- **22:15:43 : `fail2ban [sshd] Ban 217.181.224.153`** (maxretry=5 atteint) → **port 22 rejeté (RST)**
  pour notre IP ⇒ « Connection refused », **alors que sshd tournait encore** (5060 restait ouvert).
- sshd n'est stoppé qu'à **22:25:22 par SIGTERM** (reboot Julien), pas par un crash.
- **Bans persistants** : `Restore Ban` à 22:25:36 puis 22:31:57 (fail2ban rebannit au démarrage) →
  les 2 reboots n'ont pas suffi. **Déban définitif à 08:28:42** (intervention manuelle ce matin).

### Cause racine
Jail **`sshd`** : `maxretry=5`, `findtime=86400 (1 j)`, **`bantime=604800 (7 j)`**, action **reject**, **sans
`ignoreip`** pour les IP d'admin. ⇒ Un simple **échec d'auth mot de passe** depuis une IP légitime
**verrouille tout le monde 7 jours**, et le ban **survit aux reboots**. C'est le vrai défaut, pas le trunk.

## CORRECTIF RACINE APPLIQUÉ (mon périmètre fail2ban)
- Ajout `/etc/fail2ban/jail.d/00-ignoreip-admin.local` → `[DEFAULT] ignoreip = 127.0.0.1/8 ::1
  86.219.153.123 217.181.224.153 195.135.34.181` (protège **toutes** les jails, sshd + kamailio-sip).
- Déban de l'IP + **`fail2ban-client reload`** (pas de restart). Vérifié : `ignoreip` effectif, **0 banni**.
- ⇒ Un futur échec d'auth depuis une IP d'admin **ne verrouillera plus** l'accès.

## ÉTAT SAIN (vérifié post-reboot)
| Point | État |
|-------|------|
| `:22` LISTEN + `ssh` enabled | ✅ |
| Conteneurs `edge`/`rtpengine`/`tenant-acme`/`tenant-beta` | ✅ tous **UP** (10 h, restart policy) |
| fail2ban jails `sshd` + `kamailio-sip` | ✅ actives |
| nftables `mainchain` (persistée au reboot) | ✅ 3×SSH + 8×5060 + **2×5070 Sewan** + bridge 172.28 + 6 chaînes Docker |
| `.env` `TRUNK_IP` | ✅ `37.97.65.74` |
| tenants acme (201/202) / beta (301/302) | ✅ endpoints présents |

## ⚠️ CORRECTION à l'hypothèse de la tâche 011
Task 011 supposait « edge tourne SANS le trunk (config d'origine, pas recréé) ». **Faux** : j'avais
**rebuild l'image edge** (le template `kamailio.cfg` est *baké* dans l'image). Après reboot, la
restart-policy a redémarré l'edge **AVEC le trunk** → **`:5070` écoute** et la registration uac est chargée.
**Je n'ai rien relancé** ce cycle ; c'est l'état hérité, resté stable 10 h et 2 reboots.

### Registration : preuve d'activité (sans forcer de re-register, conforme task 011)
- `kamcmd uac.reg_dump` : enregistrement chargé (`l_username=sbc2`, `auth_proxy=sip:37.97.65.74:5070`,
  `contact_addr=80.251.100.175:5070`, timers actifs, `diff_expires` décroissant).
- **Capture réseau live** : **Sewan (`mod_sofia@37.97.65.74`) envoie un OPTIONS keepalive à
  `sbc2@procom-groupesb-7523.tel.voip` et notre Kamailio répond `200 OK`.** Sewan ne *qualifie* que les
  contacts appris d'un REGISTER réussi ⇒ **le trunk est bien enregistré côté Sewan.**
- Le REGISTER↔200 OK explicite n'a pas été capturé (ré-enregistrement ~toutes les 500 s avec expires=600 ;
  je n'ai pas forcé de refresh pour respecter « ne pas relancer le register »).

## RECOMMANDATIONS (décision MAIN)
1. **Durcir fail2ban durablement** : `ignoreip` est posé ; envisager de **réduire `bantime`** (7 j
   persistant est agressif) et vérifier la **persistance des bans** (base fail2ban) pour éviter les
   « Restore Ban » au reboot.
2. **Cause tierce** : identifier **qui** a fait les auth mot de passe échouées à 22:15 (agent CHECK/`sshpass`
   avec mdp erroné ?) et **standardiser l'accès par clé** `id_pbxcloud` (plus de password auth).
3. **Trunk** : la Phase 1 est **de facto active et stable** (register OK, aucun impact sur sshd — l'incident
   était fail2ban). MAIN peut soit l'entériner, soit demander une capture REGISTER↔200 explicite (j'aurais
   juste à `uac.reg_refresh` sous capture — ~5 s, sans risque puisque la cause SSH est corrigée).

## SUITE
- Prêt pour **Phase 2** (RTP Sewan + SDA + format sortant) sur feu vert MAIN.
- Watcher `ops_task_*`/reference toujours actif.

**Tâche `ops_task_011.md` : TRAITÉE** (post-mortem + état sain + fix racine fail2ban). `ops_task_010` couverte ici.
