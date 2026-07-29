# Rapport OPS #012 — Trunk Sewan Phase 2 (entrant SDA + sortant E.164) en place

**En réponse à** : `ops_task_015.md`
**Rédigé par** : OPS — 2026-07-29 09:05
**Cible** : `80.251.100.175` — trunk `sbc2` / tenant `acme`

---

## STATUT
✅ **Config Phase 2 déployée et validée (`kamailio -c` OK), zéro régression.**
Entrant **SDA `+33339571241` → acme, sonne 201 & 202** ; sortant **E.164 → Sewan, CLI `+33339571241`** ;
**RTP Sewan whitelisté**. Register Phase 1 **toujours actif** (re-registré après recréation edge).
**Prêt pour test d'appel réel** (nécessite le mobile de Julien) — quelques paramètres à confirmer en live.

## ACTIONS
### 1. Firewall RTP Sewan
- `mainchain` : `ip saddr 37.97.65.74 udp dport 30000-30999 accept` (`.bak.avant-rtp-sewan`, persisté, **sans flush**).
  Retour média sortant couvert par conntrack established. Intégrité OK (8×5060, 6 chaînes Docker).

### 2. Kamailio (`kamailio.cfg` + `tenants.cfg`) — `.bak.avant-phase2`
- **Sortant** : dans `route[TENANT]`, un INVITE tenant (src 172.28.0.x) avec RURI **E.164 `^\+`** → `tip="trunk"`.
  Puis RURI réécrit `sip:<num>@procom-groupesb-7523.tel.voip`, `$du=sip:37.97.65.74:5070`, `t_on_failure("TRUNK_AUTH")`.
- **`failure_route[TRUNK_AUTH]`** : sur `401/407`, `uac_auth()` (credential sbc2) + `t_relay()`.
- **`DID_LOOKUP`** : `+33339571241` / `0033339571241` / `0339571241` → acme `172.28.0.11` (3 formes tant que la
  forme réelle Sewan n'est pas observée).

### 3. Asterisk acme (`pjsip.conf`, `extensions.conf`, `extensions-inbound.conf`) — `.bak.avant-phase2`
- **`[global] endpoint_identifier_order = username,ip`** : les postes 2xx s'identifient par username,
  l'entrant opérateur par IP (fallback) — sinon tout le trafic de 172.28.0.1 serait pris pour le trunk.
- **Endpoint `edge-trunk`** (context `from-edge`, aor `sip:172.28.0.1:5060`, identify **match 172.28.0.1/32**,
  `from_domain=procom-groupesb-7523.tel.voip`) : double usage entrant (identify) + sortant (Dial @edge-trunk).
- **Entrant** (`extensions-inbound.conf` → contexte `from-edge`) : `+33339571241` → `Dial(PJSIP/201&PJSIP/202,30)`.
- **Sortant** (`acme-internal`) : `_+33X.` et national `_0[1-9]XXXXXXXX` → `Set(CALLERID(num)=+33339571241)` +
  `Dial(PJSIP/<num>@edge-trunk,60)`.

### 4. Application
- **`kamailio -c` = "config file ok"** → **rebuild image edge** (kamailio.cfg baké) + recréation ;
  **reload acme** (`dialplan reload` + `module reload res_pjsip.so`).

## VÉRIFICATIONS
- edge-trunk : endpoint **présent** (context from-edge), identify **match 172.28.0.1/32** ✓.
- Dialplan acme : entrant `+33339571241→201&202`, sortant `_+33X.→@edge-trunk` **chargés** ✓.
- **Register actif** : `uac.reg_dump` sbc2, `diff_expires≈568` (re-registré post-recréation) ✓.
- **Non-régression** : 4 conteneurs UP, jails `sshd`+`kamailio-sip` actives, 5070 Sewan + RTP Sewan présents,
  postes acme **201/202** et beta **301/302** intacts, sockets 5060 (pub/int) + 5070 OK.

## À CONFIRMER EN TEST RÉEL (mobile Julien)
1. **Forme exacte du SDA** présentée par Sewan à l'INVITE entrant (E.164 `+33…` / `0033…` / national) —
   le DID_LOOKUP et l'inbound gèrent les 3 ; noter la vraie pour nettoyer.
2. **RURI/From attendus par Sewan** en sortant (j'utilise RURI `@procom-groupesb-7523.tel.voip`, From CLI
   `+33339571241`) : ajuster si 4xx opérateur.
3. **Sens média rtpengine** (int 172.28.0.1 ↔ pub 80.251.100.175) sur un appel trunk réel (audio bidirectionnel).

## CAVEATS
- `tenants.cfg` (DID_LOOKUP) est **édité à la main** ; `tools/render.sh` l'écraserait à la prochaine
  régénération → à terme, porter les SDA dans `registry.txt`/`render.sh`.

## SUITE
- **→ CHECK + MAIN** : prêt pour **test d'appel réel** (entrant SDA sonne 201&202 ; sortant 201/202 → mobile,
  CLI +33339571241). Je noterai la forme SDA réelle dès qu'un INVITE entrant est observé.

**Tâche `ops_task_015.md` : TRAITÉE (config Phase 2 en place, en attente test d'appel réel).**
