# Rapport CHECK #005 — En attente signal OPS (beta UP)
**Timestamp** : 2026-07-28 20:45
**Tâche** : check_task_005.md
**Agent** : CHECK

## STATUT : EN ATTENTE — ops_report_005.md absent, tenant-beta non démarré

```
docker ps actuel :
pbxcloud-edge-1         Up 2h
pbxcloud-tenant-acme-1  Up 2h
pbxcloud-rtpengine-1    Up 2h
← pbxcloud-tenant-beta-1 : ABSENT
```

Monitor `b0mgfyxc2` actif, poll 15 s sur ops_report_005.md.

---

## Analyse préliminaire : mécanisme d'isolation inter-tenant

Lecture de `edge/kamailio/tenants.cfg` et `kamailio.cfg` effectuée.

### Couche 1 — Kamailio routing (TENANT_LOOKUP)
```
$rd == "acme.pbx1-procom.dyndns.org" → 172.28.0.11 (acme Asterisk)
$rd == "beta.pbx1-procom.dyndns.org" → 172.28.0.12 (beta Asterisk)

Fallback (pas de sous-domaine DNS) :
  REGISTER : $tU (To-user)  | autres : $fU (From-user)
  $fU =~ "^2" → acme | $fU =~ "^3" → beta
```

### Couche 2 — Dialplan Asterisk
- acme-internal : `_2XX` (seulement extensions 200-299) + `600` (écho)
- beta-internal : `_3XX` (attendu — à vérifier)
- Un INVITE pour 301 arrivant chez acme Asterisk → pas de matching `_2XX` → **404**

### Couche 3 — Auth PJSIP Asterisk
- Asterisk challenge tout INVITE entrant (realm="asterisk")
- Credentials de 201 (acme) ≠ credentials de 301 (beta)
- Même si routage cross-tenant, l'auth Asterisk rejette

### Vecteurs d'injection à tester

| # | Vecteur | Comportement attendu |
|---|---------|----------------------|
| V1 | 201 INVITE `sip:301@pbx1-procom.dyndns.org` (sans sous-domaine) | Kamailio → acme ($fU=201→"2") → acme dialplan 301 not found → **404** |
| V2 | 201 INVITE `sip:301@beta.pbx1-procom.dyndns.org` (sous-domaine beta) | Kamailio → beta ($rd=beta.*) → beta Asterisk challenge → auth 201 échoue → **403/401** |
| V3 | 301 INVITE `sip:201@pbx1-procom.dyndns.org` (inverse) | Kamailio → beta ($fU=301→"3") → beta dialplan 201 not found → **404** |
| V4 | REGISTER 201 sur `beta.pbx1-procom.dyndns.org` | Kamailio → beta ($tU=201 → non-"3" → aucun tenant) → **404** |

Résultats attendus : isolation effective sur tous les vecteurs. Toute réponse autre que 4xx = fuite à signaler.

Dès `ops_report_005.md` : exécution immédiate des 4 vecteurs + tests fonctionnels beta.
