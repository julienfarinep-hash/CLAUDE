# Référence — Trunk Sewan (VM 80.251.100.175)

**Fourni par Julien — 2026-07-28 (cycle #13)**

| Champ | Valeur |
|-------|--------|
| Mode | **REGISTRATION** (identifiant / mot de passe) — PAS IP statique |
| Domaine SIP | `procom-groupesb-7523.tel.voip` |
| Realm digest | ✅ **`procom-groupesb-7523.tel.voip`** (= domaine, confirmé par Julien 2026-07-28). Utiliser cette valeur dans uacreg + credential uac. |
| Identifiant (username) | `sbc2` |
| Mot de passe | `Fe3usQ3lESOO` (fourni 2026-07-28) |
| SBC IPv4 | `37.97.65.74` (FQDN `trunkfsc8.sewan.fr`) |
| SBC IPv6 | `2a02:c440:1000:608::74` (FQDN `trunkfsc8-ipv6.sewan.fr`) |
| Port / transport | **5070 TCP/UDP** (pas de TLS) |
| SDA / têtes entrantes | **`+33339571241`** → **acme (sonner 201 & 202)** — confirmé Julien. Format exact présenté par Sewan (E.164 `+33339571241` vs `0339571241`) à observer au 1ᵉʳ INVITE entrant |
| Format sortant | **E.164** (`+33…`) — confirmé Julien. CLI présenté = `+33339571241` (défaut, à confirmer) |
| Limite canaux | **2 canaux simultanés max** (Sewan) — quota à respecter (tests séquentiels ; base du quota multi-tenant) |
| Mobile test Julien | `0642224323` → E.164 `+33642224323` (cible du test sortant depuis 201) |
| Plage RTP média Sewan | IP média = **`37.97.65.74/32`** ; **ports source Sewan = 10000-59999** (info Julien). NB : la whitelist par IP source (/32) accepte déjà tout port source → règle inchangée = `saddr 37.97.65.74 udp dport 30000-30999` (notre rtpengine). NE PAS ouvrir 10000-59999 en dport chez nous. |
| IP 80.251.100.175 déclarée Sewan ? | **OUI, confirmé par Julien** |

## Conséquence architecture
Mode registration ⇒ **non couvert par les sources** (câblées en IP statique `$si==TRUNK_IP`).
À implémenter (proposition à valider MAIN) : **registration côté Kamailio edge** (module `uac` :
`uac_reg`/`uac_auth`) car Kamailio porte l'IP publique — register vers `procom-groupesb-7523.tel.voip`
(sbc2) via `37.97.65.74:5070`, + auth des INVITE sortants sur 407.
- Entrant : `$si == 37.97.65.74` → `DID_LOOKUP` (à remplir avec SDA) → `extensions-inbound.conf`.
- Sortant : dialplan tenant `Dial(PJSIP/…@trunk-edge)` → Kamailio ajoute l'auth → Sewan.

## Sécurité
Ajouter `37.97.65.74` (+ IPv6) en whitelist nftables pour 5070 UDP/TCP. Ne PAS ouvrir 5070 au monde.
