# Rapport OPS #016 — Sortant : SDA présenté (From+PAI) + diagnostic média

**En réponse à** : `ops_task_020.md` (canal GitHub)
**Rédigé par** : OPS — 2026-07-29 15:4x
**Cible** : `80.251.100.175` — sortant `→ +33642224323`

---

## STATUT
✅ **Point 1 fait & vérifié** : l'INVITE sortant présente désormais le SDA **`+33339571241`** en
**From ET en P-Asserted-Identity**. 🔎 **Point 2 (média) diagnostiqué** : côté trunk tout est sain
(média ancré par rtpengine sur l'IP publique, codecs OK, **aucun BYE** — l'appel sonne). La coupure
immédiate signalée était très probablement due au **CLI/PAI manquant** (Sewan coupe si l'identité n'est
pas un SDA valide), désormais corrigé. **Test audio réel requis** pour confirmer bout-en-bout jusqu'à 201.

## 1. CLI / SDA présenté (fait) — acme `pjsip.conf` (`.bak.avant-pai`)
Sur l'endpoint `edge-trunk` : `send_pai=yes`, `trust_id_outbound=yes`, `callerid=+33339571241`
(en plus du `Set(CALLERID(num)=+33339571241)` du dialplan). `module reload res_pjsip.so`.
**Vérifié dans la capture** (originate via dialplan `Local/…@acme-internal`) :
```
From: <sip:+33339571241@procom-groupesb-7523.tel.voip>;tag=...
P-Asserted-Identity: <sip:+33339571241@procom-groupesb-7523.tel.voip>
```
(plus de `sbc2`, plus de `anonymous`). `send_pai=true`, `trust_id_outbound=true` chargés côté endpoint.

## 2. Diagnostic média / coupure
Capture `tcpdump host 37.97.65.74` pendant un originate (mobile non décroché → early media) :
- **Séquence SIP** : `INVITE → 407 → INVITE(auth,CSeq+1) → 100 → 183 Session Progress`. **Aucun BYE/CANCEL**
  observé → ce n'est pas Sewan qui raccroche brutalement (dans ce test). Pas de 200 (mobile non décroché).
- **RTP réel** : **Sewan envoie 836 paquets RTP** depuis `37.97.65.74:39992` vers **notre rtpengine public
  `80.251.100.175:30147`** (tonalité de retour/early media). → **le média est bien ancré côté trunk** et
  Sewan sait où pousser le flux. Sens retour : 3 paquets sortants (normal, l'appelant de test = silence).
- **SDP sortant** : `c=IN IP4 80.251.100.175` (IP **publique**, rtpengine a réécrit) ; `m=audio 30444 RTP/AVP 8 0 101`
  → **PCMA/PCMU/telephone-event** proposés. **Pas de mismatch codec**, connexion média = IP publique correcte.

**Conclusion média** : l'ancrage rtpengine de la **jambe trunk fonctionne** (flux Sewan reçu sur l'IP publique,
SDP cohérent). Le seul maillon non observable sans phone réel = le **relais rtpengine → acme (jambe interne)
→ 201** ; il se teste avec un appel réel où 201 décroche.

## HYPOTHÈSE sur la coupure/absence d'audio initiale
1. **CLI invalide** (From/PAI ≠ SDA) → Sewan libérait l'appel : **corrigé** (From+PAI = +33339571241).
2. Résidu possible si l'audio manque encore côté 201 : **direction des interfaces rtpengine** (int↔pub) sur la
   jambe trunk — à vérifier en appel réel (si besoin, ajouter les flags `direction=int/pub` à `rtpengine_manage`).

## NON-RÉGRESSION
- 4 conteneurs UP, register Sewan **actif**, `outbound_auth=trunk-auth` + `send_pai/trust_id_outbound` OK.
- Jails actives, `:5070` en écoute, tenants acme/beta intacts. `.bak` faits. Limite 2 canaux respectée.

## SUITE — test réel coordonné (MAIN/CHECK + Julien)
**Vrai appel `201 → +33642224323`** :
- Attendu : mobile **sonne**, affiche le **CLI `+33339571241`**, et surtout **audio bidirectionnel** quand 201
  et le mobile sont décrochés (parler des 2 côtés).
- Pendant l'appel je capture **les 2 jambes RTP** (int 172.28 + pub 80.251) pour confirmer le pont rtpengine
  jusqu'à 201 ; si l'audio manque d'un côté, j'ajuste les directions rtpengine.
- Ensuite : **ENTRANT** (SDA `+33339571241` → 201 & 202) + relevé de la forme SDA réelle.

**Tâche `ops_task_020.md` : TRAITÉE — SDA présenté (From+PAI), média trunk ancré/diagnostiqué ; test audio réel à coordonner.**
