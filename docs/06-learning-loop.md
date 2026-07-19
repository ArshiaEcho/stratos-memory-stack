# The Learning Loop

The six memory layers remember. This loop makes the brain learn and keep itself current. It is four small organs that run nightly on free infrastructure. This doc explains how it works, how to set it up, and the failure modes that are easy to hit (learned the hard way).

Quick start and file links live in [`learning/README.md`](../learning/README.md). This is the deeper writeup.

## Why two halves

Capture and recall is the mature half of "AI memory" and most setups stop there. They write things down and look them up. What they do not do:

- Turn a lesson you say once into a rule that fires forever.
- Notice that you keep correcting the same thing and promote it.
- Tell you what shipped in your field this week.
- Decide which of those new things is worth your time.

That is the learning half. It is a write-back loop, not a bigger database.

## The four organs

### 1. Capture (the afferent nerve)
A `SessionEnd` hook reads the session transcript, finds the rules you said in passing ("from now on", "next time", "always make sure"), and appends them to a capture buffer. No prompt, no friction, no confirmation. Friction is what kills capture loops, so there is none.

The hook is deterministic on purpose. It only catches strong correction cues, filters out injected/system content by length and markers, and skips subagent turns. Judgment-based capture (distilling a decision or a failure) is better done by a `CLAUDE.md` rule that asks Claude to append to the same buffer during the session.

### 2. Consolidation (the librarian)
A nightly job reads the buffer and proposes which patterns should graduate. The gate is recurrence: a lesson has to show up 2-3 times (or carry an explicit cue) before it is a candidate. Candidates graduate to the cheapest enforcement altitude: a one-line `MEMORY.md` rule, a new skill, or a mode-activator trigger.

Crucially, it writes a **digest you approve**. It never edits your rules on its own. The recurrence gate plus the human approval plus the git history is the safety model.

It also runs a decay scan: any project `STATE.md` that has gone stale (untouched past a threshold) or is marked paused gets flagged for re-validation. A brain that only grows is a failure mode; stale high-confidence facts are how a memory system becomes confidently wrong.

### 3. Scouts (perception)
One scout per department runs nightly, web-searches a source list you define, diffs against a last-seen marker, and appends only what is new to a tool-radar. It stays silent when nothing changed, so you only hear from it when there is a real delta.

The scout reads your `profile.yaml` so its findings are relevant to *your* stack, not generic news. "New framework released" is noise. "New framework released that replaces a thing you hand-roll today" is signal.

### 4. Conductor (the advisor)
A nightly job reads the tool-radar plus your profile plus your active project state, and ranks everything into a short board of missions. Each mission is a quest: why now, why you, the potential payoff, what it requires, the effort. It is capped (a few per day) so it never becomes a guilt pile.

The ranking is yours. You set the weights in `profile.yaml` (a blend of impact, leverage, and edge). The anti-horoscope bar is the discipline: a mission only ships if it has a concrete reason tied to something you are actually doing and a grounded payoff. No basis, no mission.

## Where it runs, and the cost

Run the nightly engines on **GitHub Actions**. Your vault is a git repo, so the whole motion is: check out the repo, run `claude -p` headless, commit the result back, push. Free private-repo minutes cover a handful of short nightly runs.

The only real cost is Anthropic tokens. Cap each run with `--max-budget-usd`. Put scouts and consolidation on a cheaper model and the Conductor on the top tier for ranking quality. A realistic monthly bill is a few dollars.

You can also run the Conductor on a small always-on box (e.g. a Fly machine with a cron) if you want it co-located with a delivery channel like a chat bot. The engines do not care where they run; they read and write markdown.

## Failure modes (hit these so you do not have to)

- **Do not use a workflow matrix for the scouts.** A matrix runs the department jobs in parallel, and GitHub pins each job's checkout to the triggering commit. They cannot safely rebase appends to the same tool-radar file, and you get merge conflicts. Run all departments in **one job, in sequence, with a single commit at the end.** One checkout, one push, no conflict.
- **There is no `--max-turns` flag in current Claude Code.** Bound runs with `--max-budget-usd` instead.
- **`--allowedTools` is space-separated, not comma-separated.** A comma list reads as one bogus tool name and silently disables the tools, so the scout cannot search.
- **Keep the capture buffer inside the git repo.** A nightly cloud job cannot read a file that only exists on your laptop.
- **Make scouts silent on no-change.** A `git diff --staged --quiet ||` guard suppresses empty commits, so the radar only changes when there is real news.
- **Gate the consolidation digest.** Never let a nightly job edit your always-loaded rules directly. Write a proposal, approve it by hand, and let the git commit be the audit trail.
- **Memory drift is a delivery hazard, not just an archival one.** Session summaries record what the agent did, in the agent's framing. On client work, verifying against that record is self-referential: everything reads green while the customer's actual request drifts out of the loop. Keep the customer's source messages as first-class raw material and audit deliverables against THEM, not against prior summaries. Full pattern: [the contract-first delivery gate](07-contract-first-gate.md).

## The closed loop

The Conductor shows missions. You accept, snooze, or dismiss. Feed that reaction back into the capture buffer and the Conductor learns your taste over weeks. That is what turns a pipeline into a circuit: the system evolves its judgment about you, not just its configuration.
