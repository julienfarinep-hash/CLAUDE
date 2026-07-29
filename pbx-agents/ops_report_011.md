# Rapport OPS #011 — Preuve REGISTER↔200 OK Sewan (Phase 1 CLOSE)

**En réponse à** : `ops_task_014.md`
**Rédigé par** : OPS — 2026-07-29 08:50
**Cible** : `80.251.100.175` — trunk Sewan `sbc2`

---

## STATUT
✅ **Registration Sewan PROUVÉE. Phase 1 officiellement close.**
Refresh forcé (`kamcmd uac.reg_refresh sewan`) sous capture `tcpdump` sur `host 37.97.65.74` :
la séquence d'auth complète a été observée, **200 OK / expires=600, aucun 403**.

## SÉQUENCE CAPTURÉE (REGISTER → 401 → REGISTER+auth → 200 OK)
```
-> REGISTER sip:procom-groupesb-7523.tel.voip        (CSeq 10 REGISTER)
<- SIP/2.0 401 Unauthorized                          realm="procom-groupesb-7523.tel.voip"
-> REGISTER sip:procom-groupesb-7523.tel.voip        (CSeq 11 REGISTER, + Digest auth)
<- SIP/2.0 200 OK                                    (CSeq 11 REGISTER) expires=600
```

## POINTS DEMANDÉS
- **realm réel de la 401 Sewan** : **`procom-groupesb-7523.tel.voip`** ✅ (= domaine attendu, confirmé).
- **expires négocié** : **600 s** ✅.
- **Aucun 403 ni erreur** : ✅ (auth acceptée du premier coup après challenge).
- **Keepalive** : Sewan (`mod_sofia@37.97.65.74`) envoie aussi des `OPTIONS` à `sbc2@…` → on répond `200 OK`
  (qualification de contact enregistré — cohérent avec un binding actif).

## CONTEXTE
- Socket dédiée `80.251.100.175:5070` (name "trunk"), uac + db_text `uacreg` (droits 600), Contact
  annoncé `80.251.100.175:5070`. Firewall : 5070 UDP/TCP whitelisté pour `37.97.65.74` (+ IPv6).
- Risque SSH nul : ban fail2ban corrigé (ignoreip actif) avant ce refresh.

## NON-RÉGRESSION
- 4 conteneurs UP (edge/rtpengine/acme/beta), jails `sshd`+`kamailio-sip` actives, `:22` LISTEN.
- Tenants acme (201/202) / beta (301/302) inchangés. Aucun appel configuré (Phase 2).

## SUITE
- **Phase 1 = CLOSE** (register actif et prouvé). Prêt pour **Phase 2** (appels) sur feu vert MAIN +
  données : **plage média RTP Sewan** (whitelist RTP 30000-30999), **SDA→tenant/ext** (DID_LOOKUP +
  extensions-inbound), **format sortant + CLI** (dialplan `edge-trunk` + normalisation).
- → CHECK (check_task_007) pour validation croisée.

**Tâche `ops_task_014.md` : TRAITÉE — Phase 1 register close.**
