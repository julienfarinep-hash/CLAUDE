# Tâche OPS #021 — Sortant : pas d'audio + coupure ~6 s = timeout RTP (média non ancré / IP média Sewan)

**Émise par** : MAIN — 2026-07-29 (canal GitHub)
**Base** : retour terrain Julien — **CLI +33339571241 s'affiche OK** ; mais **audio unidirectionnel/absent**,
appel **coupé ~6 s** (= timeout RTP, aucun flux média reçu).
**Priorité** : 🔴 HAUTE

## Le CLI est réglé (point 1 de task_020 OK). Focus = MÉDIA.

## Diagnostic prioritaire (capture)
Originate `PJSIP/+33642224323@edge-trunk` **application Echo** (pour test 2 sens) sous
`tcpdump -n -i any '(host 37.97.65.74) or (udp portrange 30000-30999)' -w /tmp/trunk_media.pcap` :
1. **IP média réelle de Sewan** = lire le **`c=IN IP4 ...`** du **SDP du 200 OK** de Sewan.
   - Si ≠ `37.97.65.74` (média sur une autre IP/sous-réseau) → **notre whitelist RTP la droppe** → pas d'audio entrant.
     → Ajouter cette IP/plage en nftables `udp dport 30000-30999` (`.bak`, sans flush). **C'est l'hypothèse #1.**
2. **Ancrage rtpengine sur la jambe trunk** :
   - L'INVITE sortant vers Sewan doit avoir un **SDP réécrit `c=... 80.251.100.175` port 30000-30999** (rtpengine).
   - Vérifier que Kamailio appelle bien **`rtpengine_manage`** sur l'INVITE sortant vers Sewan **ET** sur le
     **200 OK** (onreply_route) de la jambe trunk. Si la branche trunk court-circuite `route(MEDIA)` → média non ancré.
3. **Flux RTP réel** : des paquets circulent-ils dans les 2 sens entre `80.251.100.175:30xxx` et l'IP média Sewan ?
   Sinon, quel sens manque ?
4. **Qui coupe à ~6 s** : Asterisk (RTP timeout / `rtp_timeout`) ou Sewan (BYE) ? (confirme le timeout média.)

## Correctif selon la trouvaille
- Cause #1 (IP média Sewan hors whitelist) → ajouter l'IP/plage média en nftables.
- Cause #2 (rtpengine non appelé sur la jambe trunk) → forcer `rtpengine_manage` sur INVITE sortant + 200 OK trunk.
- Codec : vérifier PCMU/PCMA négocié (pas de mismatch).

## Cadre
`.bak`, `kamailio -c`, jamais de flush nftables, limite 2 canaux. Register + non-régression préservés.

## Rendu → `ops_report_016.md` (push GitHub)
IP média Sewan (c= du 200 OK), état whitelist, ancrage rtpengine (oui/non), sens RTP manquant, qui coupe à 6 s,
correctif appliqué. Puis coordination re-test réel **avec Echo** (Julien doit s'entendre revenir).
