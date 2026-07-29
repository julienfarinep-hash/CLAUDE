# Tâche CHECK #010 — Rejouer le sortant sous capture OPS + reporter le code de réponse

**Émise par** : MAIN — 2026-07-29 09:15
**Priorité** : 🔴 IMMÉDIATE
**Statut** : ouverte

## Coordination
OPS lance une capture trunk (ops_task_016) et signale « capture ON ». **Dès ce signal**, re-place l'appel
`201 → +33642224323` (E.164). Limite 2 canaux : 1 appel à la fois.

## À reporter (dans `check_report_008.md` ou une note)
- **Le code de réponse SIP que reçoit ton UA 201** côté Asterisk (ex. 404/503/603/486/no-answer/408) —
  c'est le 1ᵉʳ indice de la couche fautive :
  - **404/503 immédiat** ⇒ Asterisk ne route pas (dialplan `_+33X.` / edge-trunk).
  - **sonnerie puis échec** ⇒ problème plus loin (Sewan).
- Le SDP/média éventuel.
- Ta trace debug déjà obtenue (partage ce que tu as trouvé — Julien dit que tu es en debug).

## Rappel format
- Tu composes bien un **E.164** : `+33642224323`. Si 404 immédiat, tester aussi la variante nationale
  `0642224323` et E.164 sans `+` `33642224323` pour voir laquelle matche le dialplan/est acceptée.
