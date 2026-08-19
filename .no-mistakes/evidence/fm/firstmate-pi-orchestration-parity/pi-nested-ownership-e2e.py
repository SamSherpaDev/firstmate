#!/usr/bin/env python3
import json
import os
import pathlib
import subprocess
import sys

root = pathlib.Path(sys.argv[1]).resolve()
evidence = pathlib.Path(sys.argv[2]).resolve()
home = evidence / "pi-nested-live-home"
state = home / "state"
config = home / "config"
state.mkdir(parents=True, exist_ok=True)
config.mkdir(parents=True, exist_ok=True)
lock_holder_pid = os.getpid()
(state / ".lock").write_text(f"{lock_holder_pid}\n")
watch_before = f"PRIMARY_WATCH_MARKER\nowner={lock_holder_pid}\n"
guard_before = f"PRIMARY_TURNEND_MARKER\nowner={lock_holder_pid}\n"
(state / ".pi-watch-extension-loaded").write_text(watch_before)
(state / ".pi-turnend-extension-loaded").write_text(guard_before)
arm_claim = state / ".nested-arm-claimed"

env = os.environ.copy()
env.update({
    "FM_HOME": str(home),
    "FM_STATE_OVERRIDE": str(state),
    "FM_CONFIG_OVERRIDE": str(config),
    "FM_ROOT_OVERRIDE": str(root),
    "PI_OFFLINE": "1",
})
requests = "\n".join([
    json.dumps({"id": "commands", "type": "get_commands"}),
    json.dumps({"id": "arm", "type": "prompt", "message": "/fm-watch-arm-pi"}),
    json.dumps({"id": "settle", "type": "bash", "command": "sleep 0.5"}),
]) + "\n"
proc = subprocess.run(
    [
        "pi", "--mode", "rpc", "--approve", "--no-session",
        "--no-context-files", "--no-skills", "--no-prompt-templates",
        "--no-themes", "--offline",
    ],
    cwd=root,
    env=env,
    input=requests,
    text=True,
    capture_output=True,
    timeout=45,
)
records = []
for line in proc.stdout.splitlines():
    try:
        records.append(json.loads(line))
    except json.JSONDecodeError:
        pass
commands = next((row for row in records if row.get("type") == "response" and row.get("id") == "commands"), {})
arm_response = next((row for row in records if row.get("type") == "response" and row.get("id") == "arm"), {})
notifications = [row for row in records if row.get("type") == "extension_ui_request" and row.get("method") == "notify"]
arm_notice = next((row for row in notifications if "session lock" in str(row.get("message", ""))), {})
command_names = [item.get("name") for item in commands.get("data", {}).get("commands", [])]
watch_after = (state / ".pi-watch-extension-loaded").read_text()
guard_after = (state / ".pi-turnend-extension-loaded").read_text()
arm_side_effects = sorted(
    path.name
    for path in state.iterdir()
    if path.name == ".nested-arm-claimed" or path.name.startswith(".watcher")
)

version = subprocess.run(["pi", "--version"], text=True, capture_output=True, check=True).stdout.strip()
print(f"Pi version: {version}")
print(f"Primary lock-holder PID: {lock_holder_pid} (live parent of nested Pi RPC process)")
print(f"Nested Pi auto-discovered command: {'fm-watch-arm-pi' in command_names}")
print(f"Nested arm command accepted by Pi RPC: {arm_response.get('success') is True}")
print(f"User-visible extension notification: {arm_notice.get('message', '<missing>')}")
print(f"Watcher marker preserved byte-for-byte: {watch_after == watch_before}")
print(f"Turn-end marker preserved byte-for-byte: {guard_after == guard_before}")
print(f"Nested watcher lifecycle side effects: {arm_side_effects or 'none'}")
if arm_claim.exists():
    print(f"Watcher arm fixture claim: {arm_claim.read_text().strip()}")
print(f"Nested Pi exit code: {proc.returncode}")
if proc.stderr.strip():
    print("Nested Pi stderr:")
    print(proc.stderr.strip())

ok = (
    proc.returncode == 0
    and "fm-watch-arm-pi" in command_names
    and arm_response.get("success") is True
    and arm_notice.get("message") == "watcher: read-only - session lock is held by another firstmate session"
    and watch_after == watch_before
    and guard_after == guard_before
    and not arm_side_effects
)
if not ok:
    print("Raw RPC records:")
    for row in records:
        print(json.dumps(row, sort_keys=True))
    raise SystemExit(1)
