# Rapport OPS #015 — Fix 482 (Option B) : SORTANT OK, Sewan répond 200 OK

**En réponse à** : `ops_task_019.md` (canal GitHub)
**Rédigé par** : OPS — 2026-07-29 15:2x
**Cible** : `80.251.100.175` — appel sortant `→ +33642224323`

---

## STATUT
✅ **482 RÉSOLU. L'appel sortant aboutit au niveau SIP : Sewan répond `200 OK`.**
Option B appliquée (auth trunk côté Asterisk) : le ré-INVITE authentifié a un **CSeq incrémenté**
(4599 → **4600**), donc plus de « Request Merged ». Register OK, 0 régression.

## ACTIONS
### Asterisk acme (`pjsip.conf`, `.bak.avant-optionB`)
- Ajout `[trunk-auth] type=auth ; auth_type=userpass ; username=sbc2 ; password=<mdp Sewan> ;
  realm=procom-groupesb-7523.tel.voip`.
- Sur l'endpoint `edge-trunk` : **`outbound_auth = trunk-auth`** (vérifié : `OutAuth: trunk-auth/sbc2`).

### Kamailio (`kamailio.cfg`, `.bak.avant-optionB`)
- **Retiré** `t_on_failure("TRUNK_AUTH")` + le `failure_route[TRUNK_AUTH]` (uac_auth) + le `credential` modparam
  (devenu inutile). Kamailio **proxifie** désormais le 407 vers Asterisk.
- **Conservé** : `force_send_socket udp:80.251.100.175:5070`, réécriture RURI `@procom-groupesb-7523.tel.voip`,
  `$du=37.97.65.74:5070`, et le **register uac** (uacreg) inchangé.
- **`kamailio -c` = "config file ok"** → rebuild image edge + recréation ; `module reload res_pjsip.so` sur acme.

## RÉSULTAT (capture tcpdump host 37.97.65.74, via originate de test)
```
Réponses Sewan :  100 Trying · 407 Proxy Auth Required · 183 Session Progress · 200 OK
CSeq INVITE     :  4599 (INVITE initial)  ->  4600 (INVITE ré-authentifié)   ← incrémenté !
```
Séquence : `INVITE(4599) → 407 → INVITE+Proxy-Authorization(4600) → 183 → 200 OK`. **Plus aucun 482.**
Asterisk (outbound_auth) gère le challenge avec CSeq+1 comme attendu.

## NON-RÉGRESSION
- 4 conteneurs **UP** (edge/rtpengine recréés, acme/beta 16 h). Register Sewan **actif** (diff_expires frais).
- Jails `sshd`+`kamailio-sip` actives, `:5070` en écoute, postes acme (201/202) et beta (301/302) intacts.
- Limite 2 canaux respectée (originate unique). Mdp Sewan uniquement sur la VM (placeholder en source).

## SUITE — test réel requis (coordination MAIN/CHECK + Julien)
1. **Vrai appel `201 → +33642224323`** (mobile Julien) : valider **sonnerie + audio bidirectionnel** et le
   **CLI présenté = +33339571241** (mon test originate n'établit pas l'audio réel).
   > NB : le `200 OK` observé prouve que Sewan a accepté et routé l'appel ; reste à confirmer côté mobile.
2. Puis **ENTRANT** : appel vers le SDA `+33339571241` → doit faire sonner **201 & 202** ; j'en profiterai pour
   **noter la forme exacte du SDA** présentée par Sewan (E.164 / national) et nettoyer le DID_LOOKUP.
3. Limite **2 canaux** simultanés (tests séquentiels).

**Tâche `ops_task_019.md` : TRAITÉE — sortant SIP OK (200 OK), en attente du test audio mobile réel.**
