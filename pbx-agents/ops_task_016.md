# Tâche OPS #016 — 🔴 Diagnostic appel sortant (ne sonne pas) : capture trunk + 2 couches

**Émise par** : MAIN — 2026-07-29 09:15
**Priorité** : 🔴 IMMÉDIATE (test sortant échoué : mobile ne sonne pas)
**Statut** : ouverte

## But
Localiser où meurt l'appel sortant `201 → +33642224323`. Deux couches à distinguer :
- **A. Asterisk acme** : le dialplan `_+33X.` (et national) matche-t-il ? Le `Dial(PJSIP/…@edge-trunk)` part-il ?
- **B. Kamailio → Sewan** : l'INVITE atteint-il `37.97.65.74:5070` ? Réponse Sewan (407 → auth → 200 ? ou 403/404/488 ? ou rien ?).

## Protocole (coordonné avec CHECK)
1. Lancer une **capture** ~60 s en tâche de fond :
   `sudo timeout 60 tcpdump -n -i any host 37.97.65.74 and udp -w /tmp/trunk_out.pcap` (ou `ngrep -W byline -d any port 5070`).
2. **Signaler « capture ON »** (fichier) → CHECK **re-place l'appel** `201 → +33642224323` pendant la fenêtre.
   (Limite 2 canaux : 1 seul appel à la fois.)
3. En parallèle, **logs Asterisk acme** : `docker logs pbxcloud-tenant-acme-1 --since 2m | grep -iE "\+33|edge-trunk|Dial|Everyone|congestion|404|no route"`.
4. **Analyser la capture** : `tcpdump -r /tmp/trunk_out.pcap -A | grep -iE "INVITE|SIP/2.0|CSeq|From|To|Contact|Proxy-Auth"`.

## Points de diagnostic
- **Aucun INVITE vers 37.97.65.74** ⇒ blocage couche A (Asterisk : pattern `_+33X.` ne matche pas — attention
  au `+` littéral dans le dialplan ; ou endpoint `edge-trunk`/aor/outbound_proxy mal réglé ; ou identify/context).
- **INVITE envoyé, 407 puis rien / 403** ⇒ auth uac (credential/realm) ou From/CLI refusé par Sewan.
- **INVITE, 407→200 mais mobile ne sonne pas** ⇒ numéro mal formé pour Sewan (essayer `0642224323` national, ou
  `+33642224323` vs `33642224323`) ou média/early-media.
- Noter la **réponse finale exacte** de Sewan (code + raison) — c'est la clé.

## Rendu → `ops_report_013.md`
Où meurt l'appel (couche A ou B), extrait trace (INVITE + réponse Sewan / log Asterisk), hypothèse de correctif.
Ne PAS appliquer de correctif à l'aveugle : rendre le diagnostic à MAIN d'abord.
