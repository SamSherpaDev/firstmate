#!/usr/bin/env bash
# usage: scenario.sh <code-root> <fresh-lab-home>
set -u
ROOT=$1; H=$2
run() { echo "\$ $*"; env -u NO_MISTAKES_GATE -u FM_GATE_REFUSE_BYPASS -u FM_ROOT_OVERRIDE -u FM_STATE_OVERRIDE -u FM_DATA_OVERRIDE -u FM_CONFIG_OVERRIDE -u FM_PROJECTS_OVERRIDE FM_HOME="$H" "$@" 2>&1; echo "[exit $?]"; }
tx() { echo "\$ tasks-axi $*"; (cd "$H" && tasks-axi "$@") 2>&1 | sed 's/^/  /'; }
cp "$ROOT/.tasks.toml" "$H/.tasks.toml"
printf '## In flight\n\n## Queued\n\n## Done\n' > "$H/data/backlog.md"
S=panda-model-retest
tx add $S "Retest the panda model" --kind scout --start
mkdir -p "$H/data/$S"; printf '# Panda model retest\n' > "$H/data/$S/report.md"
printf 'done: report complete\n' > "$H/state/$S.status"
cat > "$H/state/$S.meta" <<EOF
worktree=$H/projects/missing-$S
project=$H/projects/sample
harness=claude
kind=scout
mode=scout
EOF
run "$ROOT/bin/fm-captain-hold.sh" hold panda-library-proposals --title "Pick library proposals" --reason "captain choice pending"
run "$ROOT/bin/fm-captain-hold.sh" hold panda-model-setting-lockdown --title "Lock down model setting" --reason "captain choice pending"
run "$ROOT/bin/fm-captain-hold.sh" complete $S panda-library-proposals panda-model-setting-lockdown
echo "--- meta after inventory:"; grep -E 'decision' "$H/state/$S.meta"
printf 'Lock the model setting to the retested value.\n' > "$H/lockdown.txt"
run "$ROOT/bin/fm-captain-hold.sh" answer panda-model-setting-lockdown --decision-file "$H/lockdown.txt"
printf 'Adopt proposals A and C.\n' > "$H/library.txt"
run "$ROOT/bin/fm-captain-hold.sh" answer panda-library-proposals --decision-file "$H/library.txt"
echo "--- Done retention (keep 1 newest Done row):"
tx prune --keep 1
echo "--- backlog.md Done section:"; sed -n '/^## Done/,$p' "$H/data/backlog.md"
echo "--- done-archive.md:"; cat "$H/data/done-archive.md"
tx show panda-model-setting-lockdown
echo "=== THE REPORTED FAILURE PATH ==="
run "$ROOT/bin/fm-captain-hold.sh" complete $S --none
run "$ROOT/bin/fm-captain-hold.sh" verify $S
run "$ROOT/bin/fm-teardown.sh" $S
echo "--- post-teardown:"; ls "$H/state"; tx show $S | head -5
