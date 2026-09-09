#!/bin/bash
# Run from the validated worktree. No real agent or runtime is launched.
set -eu
export TMPDIR="$PWD/.test-phase-tmp"
export FM_TEST_SKIP_ORPHAN_REAP=1
export PATH="/bin:/usr/bin:$PATH"
EVIDENCE=/Users/trpmac2/.no-mistakes/evidence/01M243S9SCEA24CZQPASDB9PSZ
. tests/fixtures.sh
CASE=$(fm_test_tmproot fm-instruction-evidence)
# Reproduce the original contract through its executable generator, not source assertions.
mkdir -p "$CASE/before"
cp -R "$ROOT/bin" "$CASE/before/bin"
git show 78318e2c5746189c04d19b6148124ed99ecc5495:bin/fm-brief.sh > "$CASE/before/bin/fm-brief.sh"
git show 78318e2c5746189c04d19b6148124ed99ecc5495:bin/fm-dod-lib.sh > "$CASE/before/bin/fm-dod-lib.sh"
for mode in no-mistakes direct-PR local-only; do
  home="$CASE/$mode/home"
  proj="$CASE/$mode/project"
  wt="$CASE/$mode/worktree"
  id="contract-$mode"
  fm_test_spawn_home "$home" codex
  printf 'manual\n' > "$home/config/backlog-backend"
  fm_git_worktree "$proj" "$wt" "fixture-$mode"
  fakebin=$(fm_test_make_spawn_fakebin "$CASE/$mode/tools")
  cat > "$fakebin/codex" <<'CAPTURE'
#!/bin/bash
for argument in "$@"; do last=$argument; done
printf '%s' "$last" > "$FM_CAPTURE_PAYLOAD"
CAPTURE
  chmod +x "$fakebin/codex"
  FM_HOME="$home" "$CASE/before/bin/fm-brief.sh" "$id" sample --mode "$mode" >/dev/null
  brief="$home/data/$id/brief.md"
  python3 - "$brief" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
p.write_text(p.read_text().replace('{TASK}', 'Ship the compatibility fix without live effects.').replace('{FIRSTMATE_SPEC}', 'Retain offline-test and access constraints. Keep implementation approval distinct from the original ask.'))
PY
  cp "$brief" "$CASE/$mode/stored-before.md"
  if [ "$mode" = no-mistakes ]; then
    assert_grep 'append `done: {summary}`' "$brief" 'baseline does not reproduce premature completion'
    cp "$brief" "$EVIDENCE/pre-update-no-mistakes-brief.md"
  fi
  export FM_FAKE_LAUNCH_LOG="$CASE/$mode/launch.log"
  FM_BACKEND=tmux fm_test_run_spawn "$home" "$wt" "$fakebin" "$id" "$proj" codex --mode "$mode" --yolo off > "$CASE/$mode/spawn.txt"
  cmp "$brief" "$CASE/$mode/stored-before.md"
  # Execute the shell command actually sent to the fake runtime, with a capturing agent.
  launch=$(tail -n 1 "$FM_FAKE_LAUNCH_LOG")
  (cd "$wt"; FM_CAPTURE_PAYLOAD="$CASE/$mode/agent-payload.txt" PATH="$fakebin:$PATH" /bin/bash -c "$launch")
  [ "$("$ROOT/bin/fm-operational-input.sh" kind < "$CASE/$mode/agent-payload.txt")" = launch-brief ]
  . "$ROOT/bin/fm-operational-input.sh"
  payload=$(< "$CASE/$mode/agent-payload.txt")
  fm_operational_input_body "$payload" received
  [ "$received" = "$(< "$home/data/$id/launch-brief.md")" ]
  printf '%s\n' "$received" > "$EVIDENCE/delivered-$mode.md"
  cp "$home/state/$id.meta" "$EVIDENCE/spawn-$mode.meta"
  cp "$CASE/$mode/spawn.txt" "$EVIDENCE/spawn-$mode.txt"
  FM_HOME="$CASE/$mode/current-home" "$ROOT/bin/fm-brief.sh" "$id" sample --mode "$mode" >/dev/null
  awk '/^# Definition of done$/ {emit=1} emit' "$CASE/$mode/current-home/data/$id/brief.md" > "$CASE/$mode/current-dod"
  awk '/^# Current ship delivery contract$/ {current=1} current && /^# Definition of done$/ {emit=1} emit' "$EVIDENCE/delivered-$mode.md" > "$CASE/$mode/delivered-dod"
  cmp "$CASE/$mode/current-dod" "$CASE/$mode/delivered-dod"
  cp "$CASE/$mode/current-home/data/$id/brief.md" "$EVIDENCE/fresh-$mode.md"
  printf '%s\n' "Delivered $mode through the real spawn CLI and emitted launch command into a capturing codex; stored brief unchanged; received current DOD equals fresh generation."
done
# Existing executable promotion fixture runs its printed fm-send command and captures delivery.
set +e
. tests/fm-task-delivery.test.sh
set -e
for mode in no-mistakes direct-pr local-only; do
  cp "$TMP_ROOT/promote-dod/payload-promote-dod-$mode" "$EVIDENCE/promoted-$mode.md"
done
