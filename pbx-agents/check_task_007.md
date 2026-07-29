# Tâche CHECK #007 — Non-régression post-incident + confirmation register

**Émise par** : MAIN — 2026-07-29
**Déclencheur** : parution de `ops_report_010.md` (ignoreip posé + edge :5070).
**Priorité** : haute
**Statut** : TRAITÉE — voir check_report_007.md (2026-07-29) — GO

## Contexte
Après incident (ban fail2ban de l'IP admin, résolu) : l'edge a été recréé avec la socket trunk `:5070`.
Vérifier qu'on n'a **rien cassé** côté tenants et confirmer indépendamment l'état du register.

## À faire (depuis 217.181.224.153, maintenant en ignoreip → plus de risque de ban)
1. **Non-régression tenants** : REGISTER 201 (acme) + 301 (beta) → 200 OK ; INVITE **600** acme + beta →
   200 OK + SDP média 80.251.100.175 plage 30000-30999 + écho RTP. (réutiliser le script SIP, filtrage Call-ID.)
2. **Register Sewan** : via logs edge (`docker logs pbxcloud-edge-1 | grep -iE "register|200|401|realm"`),
   confirmer/infirmer l'enregistrement (200 OK Sewan) et **relever le realm réel** de la 401.
3. **Sécurité** : `fail2ban-client status sshd` + `status kamailio-sip` = actives, 3 IP admin en ignoreip,
   0 ban sur nos IP. `nft list chain ip filter mainchain` : whitelist SSH/5060/5070/bridge intacts, pas d'ouverture mondiale.

## Rendu → `check_report_007.md`
Non-régression 2 tenants (GO/NO-GO), état register (GO si 200 OK / NO-GO + trace), sécurité OK.
Si register NO-GO (401/403) : coller la trace + realm → MAIN émettra un correctif ciblé.
