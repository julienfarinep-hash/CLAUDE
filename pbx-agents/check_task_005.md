# Tâche CHECK #005 — Validation tenant beta + isolation inter-tenant

**Émise par** : MAIN — 2026-07-28 20:42
**Déclencheur** : parution de `ops_report_005.md` (beta UP).
**Priorité** : haute
**Statut** : TRAITÉE — voir check_report_005.md (2026-07-28 21:15)

## À faire (depuis 217.181.224.153, réutiliser le script SIP du cycle #004)
1. **beta fonctionnel** : REGISTER **301** (creds `pbx-cloud/tenants/beta/pjsip.conf`) → 200 OK,
   endpoint Available ; INVITE **600@…** (echo) → 200 OK + SDP média 80.251.100.175 plage 30000-30999
   + retour RTP (comme acme). ⇒ prouve beta bout-en-bout.
2. **Isolation inter-tenant (CŒUR du multi-tenant)** :
   - Enregistrer **201 (acme)** et tenter **INVITE 301 (beta)**.
   - Résultat attendu : **l'appel ne doit PAS aboutir vers un poste beta comme s'il était interne**
     — soit rejet (403/404), soit routage explicite documenté. Un utilisateur acme ne doit pas
     pouvoir joindre/énumérer les postes beta ni inversement.
   - Documenter le comportement réel (Kamailio route 3xx→beta par préfixe ; beta accepte-t-il un INVITE
     dont la source n'est pas un de ses endpoints ?).
3. **Non-régression acme** : re-REGISTER 201 + echo 600 acme → toujours OK.

## Rendu attendu → `check_report_005.md`
- beta : REGISTER + echo RTP (GO/NO-GO).
- Isolation : comportement observé + verdict (isolé / fuite à corriger).
- acme : non-régression.
Toute fuite d'isolation → anomalie prioritaire ; MAIN émettra un correctif OPS (routing/contexte Kamailio).
