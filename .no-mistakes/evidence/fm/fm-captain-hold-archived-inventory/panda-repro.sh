#!/usr/bin/env bash
# Reproduce the 2026-09-28 panda-model-retest defect in a disposable lab home.
# Usage: panda-repro.sh <firstmate-root>   (root whose bin/ is exercised)
set -u
ROOT=$1
LAB=$(mktemp -d "${TMPDIR:-/tmp}/fm-lab.XXXXXX")
trap 'rm -rf "$LAB"' EXIT
"$ROOT/bin/fm-lab-home.sh" create "$LAB" >/dev/null || exit 1
cp "$ROOT/.tasks.toml" "$LAB/.tasks.toml"
printf '## In flight\n\n## Queued\n\n## Done\n' > "$LAB/data/backlog.md"
mkdir -p "$LAB/fakebin"
# The lab scout has no real runtime endpoint; tmux is absent on this host.
for t in tmux; do printf '#!/bin/sh\nexit 0\n' > "$LAB/fakebin/$t"; chmod +x "$LAB/fakebin/$t"; done
run() { echo "\$ $*"; env -u NO_MISTAKES_GATE -u FM_GATE_REFUSE_BYPASS -u FM_ROOT_OVERRIDE -u FM_STATE_OVERRIDE -u FM_DATA_OVERRIDE -u FM_CONFIG_OVERRIDE -u FM_PROJECTS_OVERRIDE PATH="$LAB/fakebin:$PATH" FM_HOME="$LAB" "$@"; echo "[exit $?]"; }
cd "$LAB"
ORIG=panda-model-retest; A=panda-library-proposals; B=panda-model-setting-lockdown
tasks-axi add "$ORIG" "Retest panda model" --kind scout --start >/dev/null
cat > "state/$ORIG.meta" <<META
window=firstmate:fm-$ORIG
worktree=$LAB/projects/missing-$ORIG
project=$LAB/projects/panda
harness=claude
kind=scout
mode=scout
spawn_gen=lab-$ORIG
META
mkdir -p "data/$ORIG"; printf '# Panda retest report\n' > "data/$ORIG/report.md"
printf 'done: report complete\n' > "state/$ORIG.status"
echo "== captain holds + completion pass inventory"
run "$ROOT/bin/fm-captain-hold.sh" hold "$A" --title "Panda library proposals" --reason "captain picks a library"
run "$ROOT/bin/fm-captain-hold.sh" hold "$B" --title "Panda model setting lockdown" --reason "captain approves lockdown"
run "$ROOT/bin/fm-captain-hold.sh" complete "$ORIG" "$A" "$B"
grep decision_keys "state/$ORIG.meta"
echo "== captain answers lockdown; Done retention archives it"
printf 'Lock the model setting down.\n' > answer-b.txt
run "$ROOT/bin/fm-captain-hold.sh" answer "$B" --decision-file answer-b.txt
tasks-axi prune --keep 0 >/dev/null
echo "--- tasks-axi show $B (live backlog):"; tasks-axi show "$B" 2>&1 | head -3
echo "--- data/done-archive.md:"; cat data/done-archive.md
echo "== captain answers library proposals (stays live in Done)"
printf 'Use the first proposal.\n' > answer-a.txt
run "$ROOT/bin/fm-captain-hold.sh" answer "$A" --decision-file answer-a.txt
echo "== the reported failing commands"
run "$ROOT/bin/fm-captain-hold.sh" verify "$ORIG"
run "$ROOT/bin/fm-captain-hold.sh" complete "$ORIG" --none
run "$ROOT/bin/fm-teardown.sh" "$ORIG"
echo "--- after teardown:"
[ -e "state/$ORIG.meta" ] && echo "meta still present" || echo "meta removed"
tasks-axi show "$ORIG" 2>&1 | grep -E "state:"
