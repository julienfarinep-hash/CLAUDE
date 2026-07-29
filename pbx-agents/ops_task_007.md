# Tâche OPS #007 — Préparer le trunk Sewan (registration) : firewall + design uac

**Émise par** : MAIN — 2026-07-28 21:20
**Base** : `reference_trunk_sewan.md`
**Priorité** : haute
**Statut** : ouverte
**⚠ Contrainte** : le **mot de passe Sewan n'est pas encore fourni** (à générer par Julien).
→ Ce cycle = **préparation + design**, PAS d'activation du register (il échouerait sans mdp).

## À faire
### 1. Firewall — autoriser le SBC Sewan (concret, sûr)
- Ajouter en whitelist nftables `mainchain` : `37.97.65.74` **et** IPv6 `2a02:c440:1000:608::74`
  pour **5070 UDP + TCP** (signalisation trunk). RTP : plage 30000-30999 déjà ouverte.
- **Sauvegarde `.bak`** de `/etc/nftables.conf` avant, persister les règles, ne PAS flush la table
  (piège Docker iptables-nft). Ne PAS ouvrir 5070 au monde.

### 2. `.env`
- Passer `TRUNK_IP=37.97.65.74` (permet l'aiguillage entrant `$si==TRUNK_IP → DID_LOOKUP`).
  `.bak` du `.env`. Ne pas encore recharger l'edge tant que le design register n'est pas validé.

### 3. Design registration (PROPOSITION à valider MAIN — ne pas appliquer)
Mode = registration (domaine `procom-groupesb-7523.tel.voip`, user `sbc2`, SBC `37.97.65.74:5070` UDP/TCP,
pas de TLS). Les sources sont câblées IP statique → il faut ajouter la registration.
- **Étudier et proposer** l'implémentation côté **Kamailio edge** (module `uac` : `uac_reg` ou
  `uac_auth`) : où déclarer la registration, comment gérer l'auth des INVITE sortants (407),
  comment le module est chargé dans l'image `pbxcloud/kamailio` (paquet `kamailio-uac-modules` présent ?).
- Alternative à comparer : registration côté **Asterisk** (un endpoint/registration PJSIP `trunk` sur un
  tenant), avec ses limites (Contact = IP conteneur, passage par l'edge).
- Rendre un **plan concret** (fichiers à modifier, modules à installer, extrait de conf en placeholder
  avec `PASSWORD=<pending>`), **sans rien activer**.

## Rendu attendu → `ops_report_006.md`
- Firewall Sewan ajouté + persistant (montrer le ruleset), `.env` TRUNK_IP mis à jour.
- **Plan d'implémentation registration** (uac Kamailio recommandé ou Asterisk), modules requis,
  extrait de conf placeholder, points de vigilance. MAIN validera avant activation (ops_task_008).
- Confirmer zéro régression (2 tenants toujours UP, jail active).
