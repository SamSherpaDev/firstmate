Your scout task has been promoted to a ship task, mode=no-mistakes. Your window, worktree, and context stay as they are; only the contract below changes.

# Task
## Captain's intent
Ship the delivery-contract change.

## Firstmate spec
1. **Verify isolation before anything else.** Run `pwd -P` and `git rev-parse --show-toplevel`; both must resolve to the disposable task worktree you were launched in, such as a treehouse pool path or an Orca-managed worktree, not the primary checkout firstmate operates from. If either does not resolve to the worktree you were launched in, stop and escalate to firstmate.
2. Inventory this worktree's scratch state with `git status` and `git log` before changing anything.
3. Return to a clean default-branch base, then create your branch: `git checkout -b fm/promote-dod-no-mistakes`.
4. Carry over only the intended fix changes. Leave scratch commits, debug edits, and experiment files behind.
5. If you reproduced a bug, turn that reproduction into a regression test.
6. These ship instructions supersede the scout delivery rules and report-based Definition of done. Everything else in your original instructions carries over unchanged: the status protocol; the instruction inbox and its acknowledgement; the escalation rules, including ask-user; and every safety rule.
   For a no-mistakes ask-user gate specifically, escalate all ask-user findings as one event plus one snapshot file, using that same shape even when the gate holds only a single ask-user finding: write only the ask-user findings, verbatim and unparaphrased (id, severity, file, line, description, authority), to `/Users/trpmac2/.no-mistakes/worktrees/354ca8d119eb/01M243S9SCEA24CZQPASDB9PSZ/.test-phase-tmp/fm-task-delivery.bRLBlC/promote-dod/home/data/promote-dod-no-mistakes/nm-<run>-findings.txt`, then report the gate with
   `needs-decision [key=nm-<run>-<step>]: ask-user findings=<id1>,<id2>,... file=/Users/trpmac2/.no-mistakes/worktrees/354ca8d119eb/01M243S9SCEA24CZQPASDB9PSZ/.test-phase-tmp/fm-task-delivery.bRLBlC/promote-dod/home/data/promote-dod-no-mistakes/nm-<run>-findings.txt`
   naming every ask-user finding id from that gate. The status line only points at the file; it never restates or summarizes a finding's content.
7. Reconcile the original scout-time specification and later implementation approval: retain every accepted ship-relevant product/engineering requirement under the selected delivery contract, without relabeling it as captain words or carrying over obsolete investigation-only operations.
   If that approval leaves a requirement's acceptance unclear, ask firstmate before proceeding rather than silently dropping or inventing it.

# Definition of done
Delivery contract: mode=no-mistakes
After committing the authorized implementation, append `working: implementation committed; starting validation` once and proceed directly into no-mistakes on this same worker; no second start instruction is needed.
First reconcile any existing run and its branch custody through structured status; resume an active run rather than starting a duplicate or changing its code.
Reserve `done:` for the current-head green PR below, never the implementation commit.

You drive no-mistakes by responding to its gates, not by implementing fixes.
Follow the guidance no-mistakes itself provides for the mechanics: it loads when you invoke /no-mistakes, and `no-mistakes axi run --help` plus the `help` lines in each `axi` response are authoritative and version-matched to the installed binary.
When starting no-mistakes, preserve every accepted product/engineering requirement, constraint, exclusion, proof obligation, and later accepted decision in `--intent`, replacing superseded requirements with their current accepted form; never substitute a diff summary.
Use `## Captain's intent` and the accepted requirements in `## Firstmate spec` plus later accepted clarifications, without relabeling Firstmate specifications as captain words or treating your own unapproved tradeoffs as accepted requirements.
For a legacy mixed `# Task`, retain provenance-marked captain words and all accepted product/engineering requirements; if captain provenance is missing or acceptance is unclear, ask firstmate rather than inventing intent.
Keep private handoff destinations and worker-control instructions (status reporting, routing, and delivery mechanics) in the brief, not in review intent; offline-test, no-live-effect, access, and other product/engineering safety constraints remain acceptance criteria.
The `--intent` string must be self-sufficient: resolve referenced reports, decisions, and PRs into their accepted substance so that intent plus the codebase reconstructs the specification.
Review intent is private acceptance context, not public PR copy: request a few short behavior/proof/material-risk bullets for public prose, with required machine attestation preserved verbatim and separately from that prose.
Public prose must never include private coordination, local paths, task/session/model/captain attribution, or long test transcripts.
Never shorten acceptance criteria or machine attestation to shorten a PR; a publisher that cannot maintain this separation needs a reported correction through its supported gate, not an active-run hand edit.
Do not hand-edit, commit, or fix findings yourself while a run is active - the pipeline applies every fix.

One drive call blocks until the next gate or outcome, which routinely outlives what your harness lets a single command run: Claude Code kills a command at ten minutes maximum, while one fix round is capped around thirty minutes and up to three rounds chain.
So background the drive call and poll `no-mistakes axi status` from a separate call instead of sitting in one blocking hold your harness will kill.
Where a harness's own command limit is not established, assume it bounds commands and use that same background-and-poll shape.
A killed or timed-out call is never evidence the daemon died: the daemon accepts your response immediately and runs the round in the background, so the call was only ever waiting for a read while the run kept working.
Reattach and keep going rather than reporting the pipeline blocked; rule 7 owns the checks that decide when a pipeline block is real.

Two firstmate-specific rules layer on top of that guidance:
- ask-user findings are never yours to answer: escalate to firstmate using rule 6's ask-user format and stop.
  Firstmate applies `ask-user-authority` and obtains any required captain decision.
  When the decision comes back, feed it to the gate with `no-mistakes axi respond` and let the pipeline apply it - do not route the question to "the user" or implement the fix yourself.
- NEVER pass `--yes` (or `-y`) to `no-mistakes axi run` or `no-mistakes axi respond`. It is banned fleet-wide.
  It auto-resolves every gate including ask-user findings with no escalation, and answering your own ask-user finding is a hard rule violation.

After /no-mistakes reports CI green, verify its structured status attributes the passing run and PR to the exact current branch head, not an earlier commit; an unproved or mismatched head is not ready.
At that CI-ready return point, append `done: PR {url} checks green` and stop, without waiting for background merge monitoring.
Green CI does not authorize a merge; the configured merge authority remains separate.