# Tâche OPS #008 — Activer le trunk Sewan (registration uac Kamailio)

**Émise par** : MAIN — 2026-07-28 21:33
**Base** : ops_report_006 (design **VALIDÉ par MAIN**)
**Statut** : 🟢 **DÉGELÉE — PHASE 1 (register seul) à exécuter**. Mot de passe reçu + IP déclarée Sewan.
Phase 2 (appels entrant/sortant) reste gelée en attente RTP Sewan + SDA + format sortant.

## ✅ REALM CONFIRMÉ (MAIN, 21:46) — realm = domaine
Julien a confirmé : **realm digest = `procom-groupesb-7523.tel.voip`** (= le domaine). Utiliser cette
valeur telle quelle dans le champ `realm` du db_text `uacreg` ET dans le modparam `uac` `credential`
(`sbc2:procom-groupesb-7523.tel.voip:mdp`). Vérifier quand même le `realm="..."` de la 401 Sewan dans les
logs par acquit de conscience et le reporter dans ops_report_007, mais pas d'ajustement attendu.

## ⚠️ Découpage imposé par MAIN
- **PHASE 1 (CE CYCLE) = activer UNIQUEMENT la registration** vers Sewan et la prouver.
  Ne PAS configurer les appels (DID_LOOKUP/inbound/outbound restent des stubs). Register indépendant du média.
- **PHASE 2 (plus tard)** = appels réels, quand Julien fournit plage RTP Sewan + SDA + format sortant.

## Design approuvé (rappel)
- **uac Kamailio** côté edge, **socket dédiée `:5070`** (listen udp+tcp + Contact register en :5070).
- Register vers `procom-groupesb-7523.tel.voip` (user `sbc2`) via `37.97.65.74:5070` (UDP, pas de TLS).
- Auth INVITE sortants sur 407 via `failure_route` + `uac_auth()`.
- db_text `uacreg` (mdp en clair, **droits 600**, monté en volume).
- Modif `kamailio.cfg` (template) → **recréer le conteneur edge** (pas simple reload) ; `.bak` + `kamailio -c`
  (contrôle syntaxe) avant recréation.

## Données (état)
- ✅ **Mot de passe `sbc2`** : dans `reference_trunk_sewan.md` (`Fe3usQ3lESOO`). IP déclarée Sewan : OUI.
- ⏸ Plage RTP Sewan / SDA / format sortant : **PENDING → Phase 2**.

## PHASE 1 — étapes d'exécution (register seul)
1. Éditer `edge/kamailio/kamailio.cfg` (template) : ajouter socket dédiée `:5070` (listen udp+tcp,
   name "trunk"), `loadmodule uac.so` + `db_text.so`, modparams `uac` (reg_db_url text:///etc/kamailio/uacdb,
   reg_contact_addr 80.251.100.175:5070, credential sbc2:procom-groupesb-7523.tel.voip).
2. Créer le db_text `uacreg` (1 ligne, mdp depuis reference, **droits 600**, volume monté).
3. **`kamailio -c`** (contrôle syntaxe) OK **impératif** avant de recréer.
4. Recréer le conteneur edge (le template est rendu à l'entrypoint) — **noter la micro-coupure** signalisation
   phones (maquette sans users live, acceptable) ; vérifier que le handling `:5060` des tenants reste intact.
5. Vérifier registration : `kamcmd uac.reg_dump` = state **active/200**, et logs edge = `200 OK` en réponse au
   REGISTER depuis `37.97.65.74`. **NE PAS** toucher DID_LOOKUP/inbound/outbound (Phase 2).

## Interdits Phase 1
- Ne pas configurer d'appels (inbound/outbound restent stubs). Ne pas ouvrir le RTP Sewan (Phase 2).
- `.bak` de kamailio.cfg avant édition. Whitelist/jail/PasswordAuth inchangés.

## Rendu attendu → `ops_report_007.md`
Preuve registration active (`uac.reg_dump` + log 200 OK Sewan), db_text en 600, zéro régression tenants
(4 conteneurs UP, phones acme/beta toujours routés). Puis CHECK vérifie (check_task_006).
