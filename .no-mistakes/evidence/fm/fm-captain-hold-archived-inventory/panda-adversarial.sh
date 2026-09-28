#!/usr/bin/env bash
# Adversarial lab checks: archive evidence must never settle an unsettled call.
set -u
ROOT=$1
case_run() {  # <name> <setup-fn>
  local name=$1 setup=$2
  LAB=$(mktemp -d "${TMPDIR:-/tmp}/fm-lab.XXXXXX")
  "$ROOT/bin/fm-lab-home.sh" create "$LAB" >/dev/null || exit 1
  cp "$ROOT/.tasks.toml" "$LAB/.tasks.toml"
  printf '## In flight\n\n## Queued\n\n## Done\n' > "$LAB/data/backlog.md"
  mkdir -p "$LAB/fakebin"; printf '#!/bin/sh\nexit 0\n' > "$LAB/fakebin/tmux"; chmod +x "$LAB/fakebin/tmux"
  ( cd "$LAB"
    tasks-axi add panda-model-retest "Retest panda model" --kind scout --start >/dev/null
    printf 'window=firstmate:fm-panda-model-retest\nworktree=%s/projects/missing\nproject=%s/projects/panda\nharness=claude\nkind=scout\nmode=scout\nspawn_gen=lab\n' "$LAB" "$LAB" > state/panda-model-retest.meta
    printf 'done: report complete\n' > state/panda-model-retest.status
    mkdir -p data/panda-model-retest; printf "# report\n" > data/panda-model-retest/report.md
    echo "===== CASE: $name"
    $setup
    printf 'decisions_reviewed=1\ndecision_keys=panda-model-setting-lockdown\n' >> state/panda-model-retest.meta
    for cmd in "fm-captain-hold.sh verify panda-model-retest" "fm-captain-hold.sh complete panda-model-retest --none" "fm-teardown.sh panda-model-retest"; do
      echo "\$ $cmd"
      env -u NO_MISTAKES_GATE -u FM_GATE_REFUSE_BYPASS -u FM_ROOT_OVERRIDE -u FM_STATE_OVERRIDE -u FM_DATA_OVERRIDE -u FM_CONFIG_OVERRIDE -u FM_PROJECTS_OVERRIDE \
        PATH="$LAB/fakebin:$PATH" FM_HOME="$LAB" $ROOT/bin/$cmd 2>&1 | grep -v '^●'
      echo "[exit ${PIPESTATUS[0]}]"
    done
    [ -e state/panda-model-retest.meta ] && echo "RESULT: scout meta still present (teardown refused)" || echo "RESULT: scout meta REMOVED"
  )
  rm -rf "$LAB"
}
H="$ROOT/bin/fm-captain-hold.sh"
labenv() { env -u NO_MISTAKES_GATE -u FM_ROOT_OVERRIDE -u FM_STATE_OVERRIDE -u FM_DATA_OVERRIDE -u FM_CONFIG_OVERRIDE PATH="$LAB/fakebin:$PATH" FM_HOME="$LAB" "$@" >/dev/null; }
unanswered_archived() {
  labenv "$H" hold panda-model-setting-lockdown --title "Lockdown" --reason "pending"
  tasks-axi done panda-model-setting-lockdown >/dev/null   # closed outside, no captain answer
  tasks-axi prune --keep 0 >/dev/null
  grep -c panda-model-setting-lockdown data/done-archive.md | sed 's/^/archive rows mentioning id: /'
}
mention_only() {
  tasks-axi add other-task "Other (mentions panda-model-setting-lockdown)" >/dev/null
  printf 'Resolution recorded by fm-captain-hold.\nResolution mode: answered\n' > body.txt
  tasks-axi done other-task >/dev/null; tasks-axi prune --keep 0 >/dev/null
  printf '\n## Archived 2026-09-28\n- [x] other-task - mentions panda-model-setting-lockdown - (done 2026-09-28)\n  Resolution recorded by fm-captain-hold.\n  panda-model-setting-lockdown\n' >> data/done-archive.md
}
recreated_live() {
  labenv "$H" hold panda-model-setting-lockdown --title "Lockdown" --reason "pending"
  printf 'Lock it.\n' > a.txt; labenv "$H" answer panda-model-setting-lockdown --decision-file a.txt
  tasks-axi prune --keep 0 >/dev/null
  tasks-axi add panda-model-setting-lockdown "New unheld task, same id" >/dev/null
}
never_created() { :; }
case_run "archived row closed without a captain answer" unanswered_archived
case_run "id only mentioned by another archived row" mention_only
case_run "answered row archived, then id recreated live and unheld" recreated_live
case_run "inventoried id never existed" never_created
