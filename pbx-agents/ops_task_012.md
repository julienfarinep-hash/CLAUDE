# Tâche OPS #012 — 🔴 URGENT : relancer sshd via ta session DÉJÀ OUVERTE (pas de reboot)

**Émise par** : MAIN — 2026-07-29 (reprise incident)
**Priorité** : 🔴🔴🔴 IMMÉDIATE
**Statut** : ❌ CADUQUE. Incident résolu par Julien. Cause = ban fail2ban jail sshd de l'IP admin (pas un sshd down).
Post-mortem journalctl inutile. Voir ops_task_013 (prévention ignoreip + vérif register).

## Info décisive (Julien)
**Ton terminal vers la VM est ENCORE connecté.** Une session SSH établie survit à l'arrêt de sshd
(seules les NOUVELLES connexions sont refusées). Donc **tu peux réparer depuis ta session existante** —
ne PAS ouvrir une nouvelle connexion SSH (elle échouera : port 22 RST). **N'attends pas le reboot.**

## À faire DANS TA SESSION VM ACTUELLE (ordre strict)
1. **Capturer la cause AVANT toute réparation** (les logs sont encore là, ne pas les perdre) :
   - `sudo systemctl status ssh --no-pager`
   - `sudo journalctl -u ssh --no-pager -n 120`
   - `sudo journalctl -k --no-pager -n 80 | grep -iE "oom|kill|ssh"`
   - `sudo journalctl --since "-40min" --no-pager | grep -iE "ssh|nftables|stopped|restart|recreate" | tail -60`
   → **Identifier ce qui a arrêté sshd** pendant la Phase 1 (arrêt volontaire ? crash ? OOM ? commande OPS ?
   dépendance systemd tombée avec un `restart` de service ?).
2. **Vérifier la conf avant de relancer** : `sudo sshd -t` (si erreur → corriger, `.bak` si tu l'avais éditée).
3. **Relancer** : `sudo systemctl restart ssh` puis `sudo systemctl enable ssh`.
4. **Prouver le retour** : `ss -tlnp | grep :22` = **LISTEN**. (MAIN re-testera une nouvelle connexion.)
5. **NE PAS** rejouer le trunk/register ce cycle.

## Rendu → `ops_report_009.md`
- **Cause de l'arrêt sshd** (post-mortem clair — c'est le point le plus important).
- Preuve `:22` LISTEN + `systemctl is-enabled ssh` = enabled.
- État : 4 conteneurs UP, `nft list chain ip filter mainchain` (whitelist SSH/5060/5070/bridge intacts),
  `fail2ban-client status`, 2 tenants sains.

> Si ta session VM est en fait morte elle aussi (aucune commande ne passe) : le signaler immédiatement,
> on basculera sur le reboot Sewan.
