# Tâche OPS #020 — Sortant : présenter le SDA (CLI) + corriger l'absence d'audio/coupure immédiate

**Émise par** : MAIN — 2026-07-29 (canal GitHub)
**Base** : ops_report_015 (200 OK OK) + retour terrain Julien (mobile sonne, **pas d'audio, raccroche direct**)
**Priorité** : 🔴 HAUTE
**Statut** : ouverte — GO

## Contexte
Sortant abouti au SIP (200 OK). Mais à l'appel réel : mobile sonne → **aucun son + coupure immédiate**.
Julien demande explicitement : **présenter le SDA `+33339571241` comme numéro appelant** (souvent, un
opérateur coupe direct si le CLI présenté n'est pas un SDA valide → ça peut expliquer la coupure).

## 1. Présenter le SDA en sortant (identité appelant)
Sur l'appel sortant depuis acme, présenter **`+33339571241`** à Sewan :
- **From** : user = `+33339571241` (ex. `Set(CALLERID(num)=+33339571241)` — déjà posé, à confirmer qu'il
  arrive bien dans le From vers Sewan, sinon forcer `from_user`/`callerid` sur le trafic edge-trunk).
- **P-Asserted-Identity** = `sip:+33339571241@procom-groupesb-7523.tel.voip` : sur l'endpoint `edge-trunk`
  (côté sortant), activer `send_pai=yes` + `trust_id_outbound=yes` (et `from_domain` = domaine Sewan).
- Vérifier dans la capture que le **From: et le PAI: portent bien `+33339571241`** (pas `sbc2`, pas anonymous).

## 2. Diagnostiquer l'absence d'audio + coupure immédiate
Originate `PJSIP/+33642224323@edge-trunk` (ou vrai appel coordonné) sous **tcpdump host 37.97.65.74 + capture RTP** :
- **Qui raccroche et quand** : Sewan envoie-t-il un **BYE/CANCEL** juste après le 200 OK ? (→ rejet CLI probable,
  corrigé par le point 1) ou est-ce Asterisk (RTP timeout) ?
- **Média/SDP** : le **200 OK** et l'**ACK** portent-ils un SDP cohérent ? La **plage média est-elle ancrée par
  rtpengine** côté public (`80.251.100.175:30xxx`) sur la **jambe trunk** ? Vérifier que Kamailio applique bien
  `rtpengine_manage` sur l'INVITE **sortant vers Sewan** ET sur le 200 OK (onreply) — sinon média non ancré = pas d'audio.
- **RTP réel** : des paquets RTP circulent-ils dans les 2 sens entre rtpengine (80.251.100.175) et Sewan (37.97.65.74) ?
- **Codec** : PCMU/PCMA proposé/accepté ? Pas de mismatch.

## Ordre suggéré
Appliquer d'abord le point 1 (SDA/CLI) — il peut résoudre à lui seul la coupure — puis re-tester ; si le son
manque encore, traiter l'ancrage rtpengine de la jambe trunk (point 2).

## Cadre
`.bak` avant édition, `kamailio -c`, jamais de flush nftables, limite 2 canaux. Register + non-régression à préserver.

## Rendu → `ops_report_016.md` (push GitHub)
From/PAI présentant `+33339571241` (extrait), cause de la coupure (BYE Sewan ? RTP timeout ?), état ancrage
rtpengine jambe trunk, et si prêt : coordination test réel mobile (sonnerie + **audio** + CLI).
