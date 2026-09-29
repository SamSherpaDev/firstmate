#!/usr/bin/env bash
# usage: adversarial.sh <code-root> <fresh-lab-home> <case>
set -u
ROOT=$1; H=$2; CASE=$3
run() { echo "\$ $(basename "$1") ${*:2}"; env -u NO_MISTAKES_GATE -u FM_GATE_REFUSE_BYPASS -u FM_ROOT_OVERRIDE -u FM_STATE_OVERRIDE -u FM_DATA_OVERRIDE -u FM_CONFIG_OVERRIDE -u FM_PROJECTS_OVERRIDE FM_HOME="$H" "$@" 2>&1 | grep -v '^●' | grep -v '^fm-gate-refuse'; echo "[exit ${PIPESTATUS[0]}]"; }
tx() { echo "\$ tasks-axi $*"; (cd "$H" && tasks-axi "$@") 2>&1 | grep -E '^(ok|error|code)' | sed 's/^/  /'; }
cp "$ROOT/.tasks.toml" "$H/.tasks.toml"
printf '## In flight\n\n## Queued\n\n## Done\n' > "$H/data/backlog.md"
S=panda-model-retest
tx add $S "Retest the panda model" --kind scout --start
mkdir -p "$H/data/$S"; printf '# Panda model retest\n' > "$H/data/$S/report.md"
printf 'done: report complete\n' > "$H/state/$S.status"
printf 'worktree=%s\nproject=%s\nharness=claude\nkind=scout\nmode=scout\n' "$H/projects/missing-$S" "$H/projects/sample" > "$H/state/$S.meta"
printf 'Lock it.\n' > "$H/answer.txt"
C=panda-model-setting-lockdown
case "$CASE" in
  unanswered-archive)
    echo "## A captain call closed by a bare tasks-axi done (no recorded answer), then archived"
    run "$ROOT/bin/fm-captain-hold.sh" hold $C --title "Lock down model setting" --reason "captain choice pending"
    run "$ROOT/bin/fm-captain-hold.sh" complete $S $C
    tx done $C
    ;;
  recreated-live)
    echo "## An answered call archived, then a new UNHELD live task reuses the same id"
    run "$ROOT/bin/fm-captain-hold.sh" hold $C --title "Lock down model setting" --reason "captain choice pending"
    run "$ROOT/bin/fm-captain-hold.sh" complete $S $C
    run "$ROOT/bin/fm-captain-hold.sh" answer $C --decision-file "$H/answer.txt"
    ;;
  legacy-collision)
    echo "## Legacy key 'route': live $S-decision-route is the real call; an unrelated answered task named 'route' is archived"
    run "$ROOT/bin/fm-captain-hold.sh" hold $S-decision-route --title "Real legacy call" --reason "captain choice pending"
    run "$ROOT/bin/fm-captain-hold.sh" complete $S route
    run "$ROOT/bin/fm-captain-hold.sh" hold route --title "Unrelated call" --reason "separate choice"
    run "$ROOT/bin/fm-captain-hold.sh" answer route --decision-file "$H/answer.txt"
    ;;
  unreadable-backlog)
    echo "## Answered call archived, then the live backlog becomes unreadable"
    run "$ROOT/bin/fm-captain-hold.sh" hold $C --title "Lock down model setting" --reason "captain choice pending"
    run "$ROOT/bin/fm-captain-hold.sh" complete $S $C
    run "$ROOT/bin/fm-captain-hold.sh" answer $C --decision-file "$H/answer.txt"
    ;;
esac
tx prune --keep 0
echo "--- done-archive.md:"; cat "$H/data/done-archive.md"
case "$CASE" in
  recreated-live) tx add $C "New unrelated unheld task" ;;
  legacy-collision)
    echo "--- sanity: while the legacy call is still held, verify passes"
    run "$ROOT/bin/fm-captain-hold.sh" verify $S
    tx unhold $S-decision-route ;;
  unreadable-backlog) chmod 000 "$H/data/backlog.md"; tx show $C ;;
esac
echo "=== guard checks (all must refuse) ==="
run "$ROOT/bin/fm-captain-hold.sh" verify $S
run "$ROOT/bin/fm-captain-hold.sh" complete $S --none
run "$ROOT/bin/fm-teardown.sh" $S
[ "$CASE" != unreadable-backlog ] || chmod 644 "$H/data/backlog.md"
echo "--- scout records preserved:"; ls "$H/state"; tx show $S; (cd "$H" && tasks-axi show $S) 2>&1 | grep 'state:'
