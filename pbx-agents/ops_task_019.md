# Tâche OPS #019 — Fix 482 : Option B (auth trunk côté Asterisk)

**Émise par** : MAIN — 2026-07-29 (canal GitHub)
**Base** : ops_report_014 (482 = même CSeq sur le ré-INVITE uac_auth de Kamailio)
**Priorité** : 🔴 HAUTE
**Statut** : ouverte — **GO (Option B VALIDÉE par MAIN)**

## Décision
**Option B** : l'auth de l'INVITE sortant passe **côté Asterisk** (CSeq incrémenté nativement → plus de 482).
Kamailio garde : register uac + `force_send_socket :5070` + réécriture RURI, mais **ne fait plus** l'`uac_auth`
sur l'INVITE (il laisse le 407 remonter jusqu'à Asterisk). Option A (auth centralisée edge) = raffinement futur
pour le multi-tenant ; pas maintenant.

## À faire
1. **Asterisk acme** (`pjsip.conf`, `.bak.avant-optionB`) :
   - `[trunk-auth] type=auth ; auth_type=userpass ; username=sbc2 ; password=<mdp Sewan — voir reference_trunk_sewan.md>`
     (realm : laisser vide pour matcher, ou `procom-groupesb-7523.tel.voip`).
   - Sur l'endpoint `edge-trunk` : ajouter **`outbound_auth=trunk-auth`**.
2. **Kamailio** (`kamailio.cfg`, `.bak`) :
   - Dans la branche trunk : **retirer/neutraliser** l'`uac_auth()` INVITE (le `t_on_failure("TRUNK_AUTH")` +
     `failure_route[TRUNK_AUTH]` qui ré-émettait). Laisser Kamailio **proxifier** le 407 vers Asterisk et
     relayer le ré-INVITE authentifié vers Sewan. **Garder** : socket `:5070`, RURI `@procom-groupesb-7523.tel.voip`,
     `$du=37.97.65.74:5070`, et le **register uac** (inchangé).
3. `kamailio -c` OK → rebuild/recréer edge + `pjsip reload` acme.
4. **Re-test** `originate PJSIP/+33642224323@edge-trunk` sous tcpdump → viser la séquence
   `INVITE → 407 → INVITE(auth, CSeq+1) → 200 OK` (plus de 482), appel établi.

## Suite si 200 OK
Signaler MAIN → vrai appel `201 → +33642224323` (mobile Julien : sonnerie + audio bidirectionnel, CLI +33339571241),
puis test **entrant** (SDA +33339571241 → 201&202). Limite 2 canaux (séquentiel).

## Rendu → `ops_report_015.md` (push GitHub)
Séquence SIP après fix (200 OK ?), extrait CSeq incrémenté, état appel, register OK, 0 régression.
