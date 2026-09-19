# Live Pi progress verification

Pi 0.85.1 with openrouter/meta/muse-spark-1.3-contributor at xhigh ran in a private tmux server with isolated FM_HOME and agent/session directories. No real fleet records were changed.

The installed product extension, outcome CLI, wake queue, watcher, branch model, main model, and TUI renderer were real. A temporary command extension forwarded watcher messages through the production dispatch event bus and awaited settlement. This tests delivery through that bus, not automatic watcher rearming.

- Twelve CLI-seeded silent build outcomes produced one real watcher heartbeat and one visible model summary (sequence 13).
- CLI-injected decision, failure, and completion outcomes rendered immediately as exact anchor entries (14-16), without waiting for a progress summary.
- Pending build progress survived an unrelated fleet captain outcome (17-18) and was summarized by the next live model heartbeat (19).
- A forbidden silent captain outcome was rejected. A task-specific captain completion cleared its own pending progress.
- A second installed Pi executed a real 180-second shell wait. Its isolated metadata and busy generation were registered using production interfaces. Two working status events produced model-selected silent reports (20-21). Advancing the isolated heartbeat timestamp caused the real watcher to emit a due heartbeat and the model to render one summary (22).
- Meaningful routine recovery remained visible (23). After the worker actually finished, its idle state and completion event were recorded; the model selected captain and Pi rendered completion immediately (24). Main processed through sequence 24.
- Separate real watchers with no pending progress (Pi) and pending progress (non-Pi) absorbed two due heartbeat checks without queuing a wake. Timeout stopped these blocking controls after four seconds.

Pi's native HTML export, actual TUI captures, persisted outcomes, and extracted model report calls provide evidence. The HTML viewer may expose hidden context; TUI captures establish actual chat visibility. Screenshot capture was attempted, but chrome-devtools-axi could not find Google Chrome at /opt/google/chrome/chrome. No dependency was installed.

Targeted deterministic suites (not counted as live evidence): bash tests/fm-pi-branch-extension.test.sh; bash tests/fm-watch-triage.test.sh; bash tests/fm-branch-supervision.test.sh.

All three targeted regression suites exited 0. Live TUI assertions passed. Isolated tmux sessions and temporary worktree files were removed; final git status was clean.
