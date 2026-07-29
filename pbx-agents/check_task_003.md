# Tâche CHECK #003 — Test SIP réel A5 (REGISTER + appel interne)

**Émise par** : MAIN — 2026-07-28 18:46
**Base** : verdict GO de `check_report_002b.md`
**Priorité** : haute (preuve fonctionnelle)
**Statut** : TRAITÉE — voir check_report_003.md (2026-07-28 18:52)

## Objectif
Prouver le fonctionnel bout-en-bout du tenant acme depuis une IP whitelistée
(la session CHECK tourne sur le poste admin 217.181.224.153, qui est dans la whitelist nftables).

## À faire
1. **REGISTER ext 201** vers `pbx1-procom.dyndns.org:5060` (UDP).
   - Identifiants : voir `/home/julien/pbx-cloud/tenants/acme/pjsip.conf`
     (ext 201 : username `201` ; realm/domaine `pbx1-procom.dyndns.org`). Ne pas recopier les
     mots de passe dans les rapports — référencer le fichier.
   - Outillage : `sipsak`/`pjsua`/`baresip` absents localement. Options CHECK :
     (a) installer un client léger (`sipsak` si sudo dispo sur le poste admin), ou
     (b) script Python minimal (REGISTER UDP + digest MD5, sans dépendance).
   - Critère succès : **200 OK** reçu ; endpoint 201 passe `Unavailable → Available`
     (`docker exec pbxcloud-tenant-acme-1 asterisk -rx "pjsip show endpoints"`).
   - Vérifier côté edge : `docker logs pbxcloud-edge-1 --tail 30 | grep -E "REGISTER|200|location"`.
2. **(si REGISTER OK)** Enregistrer aussi 202 et tenter **INVITE 201 → 202** ; vérifier
   établissement + flux RTP via rtpengine.
3. **Si aucun outil installable / pas de sudo local** : le signaler clairement — on basculera
   sur un softphone manuel côté Julien (poste whitelisté).

## Rendu attendu → `check_report_003.md`
Résultat REGISTER (200 OK ou échec + trace), état endpoints, extrait log edge, verdict A5.
