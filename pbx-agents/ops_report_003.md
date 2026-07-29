# Rapport OPS #003 — Clôture tâches 003 + 004 (crash-loop edge déjà résolu)

**En réponse à** : `ops_task_003.md` (SUPERSEDED) + `ops_task_004.md`
**Rédigé par** : OPS — 2026-07-28 18:42
**Cible** : `80.251.100.175`, user `procom`+sudo

---

## STATUT
✅ **Déjà résolu.** Le crash-loop edge diagnostiqué par CHECK (bridge `pbxnet` manquant) a été
**corrigé au cycle #2**, avant réception de `ops_task_004`. Le correctif appliqué est **exactement
l'Option A** recommandée par CHECK. Détail complet dans `ops_report_002.md` (déjà remis, 18:35).
**Rien à relancer** — je confirme juste l'état stable actuel.

> Décalage temporel : MAIN (18:23) et CHECK (18:29) ont observé une fenêtre intermédiaire
> (build échoué + edge en Restarting). Mes correctifs ont atterri à 18:35. L'écart est dû à ce
> chevauchement, pas à un blocage OPS.

## ACTIONS (rappel — déjà faites au cycle #2)
1. **Incident réseau Docker** (auto-infligé par ma 1ʳᵉ persistance nftables `flush ruleset` qui a
   effacé les chaînes Docker en iptables-nft) → build initial échoué. **Corrigé** : `restart docker`
   + `/etc/nftables.conf` réécrit pour ne gérer QUE `mainchain` (non destructif, reboot-safe).
2. **Crash-loop edge** (bind `172.28.0.1` impossible, `pbxnet` absent) → **Correctif = Option A** :
   `docker compose -f docker-compose.yml -f docker-compose.tenants.yml up -d --build tenant-acme`
   (crée le bridge) puis `docker restart pbxcloud-edge-1`. Kamailio bind alors OK.

## ÉTAT VÉRIFIÉ MAINTENANT (18:42)
```
pbxcloud-tenant-acme-1 | Up 3 minutes
pbxcloud-edge-1        | Up 2 minutes      <-- stable, plus de Restarting
pbxcloud-rtpengine-1   | Up 15 minutes
```
- **Bridge** : `pbxcloud_pbxnet` subnet `172.28.0.0/24` gw `172.28.0.1` ✅ présent.
- **Port 5060** en écoute : `80.251.100.175:5060` udp+tcp (public) + `172.28.0.1:5060` udp (int).
- **Logs edge propres** : plus d'erreur `Cannot assign requested address`. Reste seulement
  `could not get TCP protocol number` (bénin, getprotobyname en conteneur ; TCP 5060 public bien ouvert)
  et `rtpengine instance <udp:127.0.0.1:22222> found, support for it enabled`.
- rtpengine UP, socket NG 22222 OK ; nftables S6 + whitelist en place et persistés.

## PROBLEMES
- **Aucun blocage ouvert.** Stack complète et stable.
- **Mise au point sur `~/.bash_history`** (signalé dans task 003) : les commandes
  `ssh-copy-id -i ~/.ssh/ssh-ed25519 AAAAC3...@80.251.100.175` (syntaxe malformée) et
  `mkdir -p /home/discussion` présentes dans `~procom/.bash_history` **ne sont PAS de moi**.
  Je n'ai jamais utilisé `ssh-copy-id` (déploiement de clé fait par `ssh-keygen` + append manuel
  du `.pub` via heredoc) ni créé `/home/discussion` sur la VM. Ce sont des tentatives **humaines
  antérieures** à ma session (l'ssh-copy-id a d'ailleurs échoué). Le dossier d'échange que j'utilise
  est bien **local** : `/home/julien/discussion` sur le poste d'admin. Aucun détour de mon côté.

## SUITE
- **→ CHECK** : edge stable > 2 min, tu peux **relancer la re-vérification** (A2 tenant + A3
  signalisation). Pour A5 (REGISTER/INVITE réels) il faut un softphone depuis une des 3 IP whitelistées.
- Rien d'autre à faire ce cycle. En attente de la prochaine `ops_task_*`.

**Tâches `ops_task_003.md` (superseded) et `ops_task_004.md` : TRAITÉES.**
