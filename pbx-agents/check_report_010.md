# Rapport CHECK #010 — Non-régression post-optionB + état stack

**Timestamp** : 2026-07-29 19:30
**Tâches couvertes** : check_task_009 (relance), check_task_010 (sortant), check_task_011 (bascule GitHub)
**Agent** : CHECK (session relancée après reboot local — reprise via pull GitHub + lecture historique)
**Cible** : 80.251.100.175 (pbx1-procom.dyndns.org)

---

## STATUT

✅ **NON-RÉGRESSION GO — Stack saine. Option B et CLI SDA vérifiés en config. Sortant prêt pour test coordonné (Julien doit décrocher).**

---

## RÉSULTATS

### 1. Accès et santé VM

| Élément | État |
|---------|------|
| SSH (clé id_pbxcloud) | ✅ Fonctionnel |
| Uptime VM | ✅ 20h46 (démarré juil.28, aucun reboot) |
| RAM | ✅ 7,8 Gi total / 6,8 Gi libre |
| Disque | ✅ 67 G total / 59 G libres (5,3 G utilisés) |

---

### 2. Services / processus (sans docker exec — pas de sudo)

| Service | Preuve | État |
|---------|--------|------|
| dockerd | PID 1241, Ssl juil.28 | ✅ UP |
| kamailio (edge) | PID 9860+workers, démarré 14:58 | ✅ UP |
| rtpengine | PID 9795, `--interface=pub/80.251.100.175 --interface=int/172.28.0.1 --listen-ng=127.0.0.1:22222` | ✅ UP |
| asterisk acme | PID 1849 (uid=999) | ✅ UP |
| asterisk beta | PID 1850 (uid=999) | ✅ UP |
| fail2ban-server | PID 966 | ✅ UP |

**Ports en écoute confirmés** :
```
UDP 172.28.0.1:5060    ← Kamailio int (bridge)
UDP 80.251.100.175:5060 ← Kamailio pub
UDP 80.251.100.175:5070 ← Kamailio trunk (Sewan)
TCP 80.251.100.175:5060, :5070
UDP 127.0.0.1:22222    ← rtpengine NG socket
```

---

### 3. Non-régression SIP + RTP (sip_nonreg2.py)

| Test | Résultat |
|------|----------|
| REGISTER 201 (acme) → 401 → 200 | ✅ 200 OK |
| REGISTER 301 (beta) → 401 → 200 | ✅ 200 OK |
| INVITE 600@acme (écho) → 100/401 → 200 | ✅ 200 OK |
| SDP média (c=) | ✅ `80.251.100.175` (rtpengine public) |
| Port média | ✅ **30184** (plage 30000-30999) |
| RTP écho bidirectionnel | ✅ **88 paquets envoyés / 151 reçus** |

→ **Non-régression 2 tenants : GO. rtpengine fonctionnel.**

---

### 4. Configuration Option B et CLI SDA — vérification indépendante

**Fichier** : `~/pbx-cloud/tenants/acme/pjsip.conf` (actuel, hors .bak)

```ini
; Endpoint edge-trunk
outbound_auth = trunk-auth     ← OPTION B ✓
send_pai = yes                 ← CLI/PAI ✓
trust_id_outbound = yes        ← CLI/PAI ✓
callerid = +33339571241 <+33339571241>  ← SDA ✓

[trunk-auth]
; (section présente dans pjsip.conf)
```

**Fichier** : `~/pbx-cloud/edge/kamailio/kamailio.cfg` (actuel, hors .bak)

```cfg
; Branche trunk (sortant vers Sewan) :
$fs = "udp:80.251.100.175:5070";           ← force_send_socket ✓
$ru = "sip:" + $rU + "@procom-groupesb-7523.tel.voip";
$du = "sip:37.97.65.74:5070";

; Plus de failure_route TRUNK_AUTH — Option B = auth côté Asterisk ✓
; rtpengine_manage appelé sur INVITE (route MEDIA) + onreply (REPLY_MEDIA) ✓
```

→ **Option B confirmée indépendamment par CHECK.**

---

### 5. Register Sewan — état inféré

- kamcmd non accessible sans `docker exec` (procom pas dans le groupe `docker`, sudo avec mot de passe)
- Kamailio démarré à 14:58 avec config uac intacte (`uacdb/uacreg.cfg` présent)
- Séquence SIP non-régression réussie sur port 5060 confirme que le routing Kamailio est sain
- Dernier état confirmé (check_report_007, 15:1x) : `flags=20` (REGISTERED, expires 448 s sur 600)
- **Inférence : register probablement actif** — à confirmer via `kamcmd uac.reg_dump` si OPS dispose d'un accès docker exec

---

## ANOMALIES

### A1 — kamcmd non accessible depuis procom (mineur)
`procom` n'est pas dans le groupe `docker` → impossible d'exécuter `docker exec edge kamcmd uac.reg_dump`
sans sudo (mot de passe non disponible dans la session CHECK). Non bloquant pour les tests fonctionnels.
**Recommandation** : ajouter `procom` au groupe `docker` (`usermod -aG docker procom`) pour les sessions CHECK autonomes.

### A2 — Test sortant en attente de coordination Julien
La configuration est prête (200 OK prouvé par OPS, CLI SDA confirmé, rtpengine sain). Mais le test
réel `201 → +33642224323` avec audio bidirectionnel nécessite que Julien soit disponible pour décrocher.
ops_task_022 décrit le test "vitrine" à effectuer.

---

## SUITE

**CHECK #010 : TERMINÉE.**

### Prochain(s) test(s) à coordonner :

1. **Test sortant réel "vitrine" (ops_task_022)** — nécessite Julien disponible avec mobile :
   - OPS place l'appel `201 → +33642224323` via dialplan (CLI +33339571241 + Playback+Echo)
   - Julien décroche → doit entendre le son puis s'entendre (écho)
   - CHECK note le résultat côté SIP (code / trace) si coordonné

2. **Dès le sortant validé → test ENTRANT** :
   - Julien appelle `+33339571241` depuis son mobile
   - CHECK REGISTER 201+202 et auto-répond (si outillage dispo)
   - Relever la forme réelle du SDA dans les logs edge (E.164 `+33339571241` vs `0339571241`)

3. **Recommandation sécurité** : `procom` → groupe `docker` (améliore l'autonomie CHECK)

**Stack saine et prête. En attente de la coordination Julien pour le test réel.**
