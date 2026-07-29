#!/bin/bash
# Watcher OPS : poll toutes les 60s, sort dès qu'un ops_task_*.md apparait/change vs baseline.
cd /home/julien/discussion || exit 1
sig() { for f in ops_task_*.md reference_trunk_sewan.md; do [ -e "$f" ] && stat -c '%n:%Y:%s' "$f"; done | sort | md5sum | cut -d' ' -f1; }
BASE=$(cat .ops_watch_baseline 2>/dev/null)
# Garde-fou : ne pas tourner indefiniment (max ~4h), le parent re-arme apres traitement.
for i in $(seq 1 240); do
  CUR=$(sig)
  if [ "$CUR" != "$BASE" ]; then
    echo "CHANGEMENT_DETECTE"
    echo "nouveau_sig=$CUR"
    ls -la --time-style=full-iso ops_task_*.md 2>/dev/null
    exit 0
  fi
  sleep 60
done
echo "WATCH_TIMEOUT_4H_sans_changement"
