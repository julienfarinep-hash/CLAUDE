# Tâche OPS #004 — Corriger le crash-loop edge (bridge pbxnet manquant)

**Émise par** : MAIN — 2026-07-28 18:39
**Base** : diagnostic `check_report_002.md` (18:29)
**Priorité** : HAUTE
**Statut** : ouverte
**Remplace** : `ops_task_003.md` (probe) — le diagnostic est désormais connu, plus besoin de l'erreur brute.

## Diagnostic confirmé (CHECK)
- `rtpengine` UP ✅, socket NG 22222 OK, `.env` (PUBLIC_IP=80.251.100.175), nftables S6 + whitelist : tout bon.
- **`edge` (Kamailio) en crash-loop exit 255** :
  `bind(...) on 172.28.0.1: Cannot assign requested address`.
- **Cause** : le réseau `pbxcloud_pbxnet` (172.28.0.0/24, gw 172.28.0.1) **n'existe pas**. edge et
  rtpengine étant en `network_mode: host`, aucun conteneur ne rejoint pbxnet → Docker n'assigne
  jamais 172.28.0.1 → Kamailio ne peut pas binder son socket "int" → exit 255.

## Correctif (Option A — recommandée par CHECK)
Démarrer le tenant acme crée le bridge ET valide l'invariant A2 :
```bash
cd ~/pbx-cloud
docker compose -f docker-compose.yml -f docker-compose.tenants.yml up -d tenant-acme
docker compose restart edge          # 172.28.0.1 désormais assigné → edge doit binder
```
(Option B de repli si tenant pas souhaité tout de suite :
`docker network create --driver bridge --subnet 172.28.0.0/24 --gateway 172.28.0.1 pbxcloud_pbxnet` puis `docker compose restart edge`.)

## Vérifs OPS avant de rendre la main
- `docker ps` : `rtpengine`, `edge`, `tenant-acme` **UP** (edge stable > 1 min, plus de Restarting).
- `ss -tulnp | grep 5060` : port **en écoute**.
- `docker logs pbxcloud-edge-1 --tail 20` : plus d'erreur de bind.

## Cadre (inchangé)
- Whitelist SIP uniquement, pas d'ouverture mondiale, TRUNK_IP=0.0.0.0 (pas de trunk).
- **NE PAS** passer `PasswordAuthentication no` (hardening différé).

## Rendu attendu → `ops_report_002.md` (enfin) ou `ops_report_003.md`
État `docker ps`, port 5060, logs edge propres, confirmation bridge présent.
Puis signaler à CHECK pour re-vérification (edge stable → tests A2 + enregistrement SIP).

> NB inter-agents : `procom` n'est PAS dans le groupe `docker` — toute commande docker nécessite `sudo`.
> MAIN ne peut donc pas inspecter Docker directement (pas de mot de passe sudo) : **CHECK/OPS sont la
> source de vérité** sur l'état des conteneurs.
