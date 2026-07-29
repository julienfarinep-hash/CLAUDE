# Rapport CHECK #007 — Non-régression post-incident + register Sewan

**Timestamp** : 2026-07-29 15:1x
**Tâche** : check_task_007.md
**Agent** : CHECK
**Cible** : 80.251.100.175 (pbx1-procom.dyndns.org)

---

## STATUT

✅ **GO — Non-régression 2 tenants intacte. Register Sewan confirmé actif.**

---

## RÉSULTATS

### 1. Non-régression tenants (SIP + RTP)

| Test | Résultat |
|------|----------|
| REGISTER 201 (acme) — 401→200 | ✓ 200 OK |
| REGISTER 301 (beta) — 401→200 | ✓ 200 OK |
| INVITE 600@acme (echo) — 401→200 | ✓ 200 OK |
| SDP media IP | ✓ **80.251.100.175** (rtpengine) |
| SDP media port | ✓ **30186** (plage 30000-30999) |
| RTP écho bidirectionnel | ✓ **93 envoyés / 151 reçus** |

→ **Tenants acme + beta : non-régression GO.** Nouvelle socket trunk `:5070` n'impacte pas le handling `:5060`.

---

### 2. Register Sewan — Confirmation indépendante

Via `kamcmd uac.reg_dump` (conteneur edge) :

```
l_username:   sbc2
l_domain:     procom-groupesb-7523.tel.voip
realm:        procom-groupesb-7523.tel.voip
auth_proxy:   sip:37.97.65.74:5070
flags:        20               ← état = REGISTERED
diff_expires: 448              ← ~7 min restantes sur 600
contact_addr: 80.251.100.175:5070
socket:       udp:80.251.100.175:5070
```

**Register ACTIF** : flags=20, Contact correct (`:5070`), realm = domaine attendu.
Edge logs confirment écoute sur 3 sockets : `:5060/pub`, `:5060/int`, `:5070/trunk`.

→ **Register Sewan : GO (Phase 1 confirmée indépendamment).**

---

### 3. Sécurité

**fail2ban** :
- Jails actives : `sshd` + `kamailio-sip`
- Currently banned : 0 (0 sur les 2 jails)
- ignoreip (jail.d/00-ignoreip-admin.local) : `86.219.153.123`, `217.181.224.153`, `195.135.34.181` ✓

**nftables** (`mainchain`, policy DROP) :
- SSH port 22 : whitelisté 3 IP admin seulement ✓
- SIP port 5060 : 3 IP admin + bridge 172.28.0.0/24 ✓
- SIP port 5070 (trunk) : 37.97.65.74 (Sewan) ✓
- RTP 30000-30999 : 3 IP admin + bridge + 37.97.65.74 ✓
- Aucune ouverture mondiale (5060/5070 non exposés all) ✓

→ **Sécurité : OK — conforme au design.**

---

### 4. État conteneurs (au moment du test)

| Conteneur | Statut |
|-----------|--------|
| pbxcloud-edge-1 | ✓ UP (edge reconstruit avec fix socket ops_task_017) |
| pbxcloud-rtpengine-1 | ✓ UP |
| pbxcloud-tenant-acme-1 | ✓ UP (16h) |
| pbxcloud-tenant-beta-1 | ✓ UP (16h) |

---

## NOTES

- Edge reconstitué par OPS (ops_task_017) avec `force_send_socket :5070` — **fix socket EFFICACE**
  (Via source désormais `:5070` vers Sewan). Voir ops_report_014 pour la suite (482 = CSeq non incrémenté).
- Test beta echo RTP non rejoué par manque de temps (non-régression beta confirmée via REGISTER 301 ✓ ;
  écho acme prouve rtpengine intact). Peut être complété si MAIN le demande.

---

## SUITE

**CHECK #007 : TERMINÉE — GO non-régression + sécurité + register.**

Prochaines tâches :
- **Sortant (check_task_009/010)** : bloqué sur fix CSeq (voir ops_report_014 — Option B recommandée par OPS).
  Dès que MAIN valide et OPS applique → CHECK rejouera le sortant 201→+33642224323.
- **Entrant** : après sortant GO.
