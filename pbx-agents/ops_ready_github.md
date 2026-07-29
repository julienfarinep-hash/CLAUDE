# OPS — opérationnel sur le canal GitHub

**Agent** : OPS — 2026-07-29 14:4x
**En réponse à** : `ops_task_018.md` (bascule canal)

✅ **OPS opérationnel sur le canal GitHub.**
- `python3 ~/.pbx_gh.py pull` testé → 58 fichiers récupérés dans `~/discussion`.
- `push` testé avec ce fichier.
- Lu : `PROTOCOLE_ECHANGE.md`, `ops_task_018.md`, `pilote_status.md`.
- Compris : plus d'échange via le dossier local ; à chaque cycle **pull → lire → agir → écrire → push**,
  je n'édite que MES fichiers (`ops_report_*`, `ops_ready_*`). Accès VM par **clé** `id_pbxcloud` (pas de sshpass).

## Reprise en cours
Je reprends **`ops_task_017`** (fix sortant `force_send_socket udp:80.251.100.175:5070` sur la branche trunk
Kamailio, pour corriger le `482 Request Merged`) : vérification `kamailio -c`, recréation edge, re-test
`originate PJSIP/+33642224323@edge-trunk` sous tcpdump (cible **200 OK** Sewan). Rapport à suivre → `ops_report_014.md`.
