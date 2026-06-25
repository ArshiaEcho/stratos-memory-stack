# The Learning Loop

The six layers give Claude **memory**. This layer gives it the ability to **learn** and **keep itself current**.

Memory remembers. Learning changes behavior. They are different halves. Most "AI memory" setups only do the first: they capture and recall, but they never get smarter on their own, and they have no idea what new tools exist in the world unless you go find them. This layer adds the second half.

## The four organs

```
        +-----------------------------------------------+
        |                                               v
   (1) CAPTURE --> (2) CONSOLIDATION --> rules / skills
   SessionEnd hook    promote 2-3x patterns,            |
   writes lessons     flag stale facts (gated digest)   | feeds judgment
   to a buffer                                          v
        ^                                         (4) CONDUCTOR --> your channel
        |                                         ranks radar into        + a board
        | your reactions                         missions by your weights
        | are training data                            ^
        +----------------------------------------------+
                                                        |
   (3) SCOUTS: nightly, per department, diff sources    |
       and append deltas, silent unless changed --------+
```

| # | Organ | What it does | File |
|---|---|---|---|
| 1 | **Capture** | A SessionEnd hook records the rules you say in passing ("from now on...") to a buffer | [`hooks/capture-session.sh`](hooks/capture-session.sh) |
| 2 | **Consolidation** | Nightly: promotes patterns seen 2-3x into rules, flags stale facts. Writes a digest you approve | [`engines/consolidate.md`](engines/consolidate.md) |
| 3 | **Scouts** | Nightly: per-department web scan for new tools that fit you, appends to a tool-radar | [`engines/scout.md`](engines/scout.md) |
| 4 | **Conductor** | Nightly: ranks the radar into a daily board of opportunities, by your own weights | [`engines/conductor.md`](engines/conductor.md) |

## How it runs (and what it costs)

The nightly engines run on **GitHub Actions**, which is free for this. Your vault is already a git repo; "check out, run `claude -p`, commit back" is the platform's native motion. The only cost is the Anthropic API tokens for the nightly runs, capped per run with `--max-budget-usd`. A realistic bill is a few dollars a month. Scouts and consolidation run on a cheaper model; the Conductor runs on the top tier for ranking quality.

No new server. No new database. Markdown and git all the way down, so every change the system makes to itself is a commit you can read, diff, and revert.

## The closed loop is the point

The Conductor shows you missions. You accept, snooze, or dismiss. That reaction is training data: it flows back into the capture buffer, and over weeks the Conductor learns which kinds of missions you actually act on. The system stops being a pipeline and becomes a circuit that evolves its judgment about *you*, not just its config.

## Setup

1. Put your vault in a private git repo (the memory stack already assumes a vault).
2. Add an `ANTHROPIC_API_KEY` secret to the repo (Settings > Secrets and variables > Actions).
3. Copy [`hooks/capture-session.sh`](hooks/capture-session.sh) to `~/.claude/hooks/` and register it under `SessionEnd` in `~/.claude/settings.json`:
   ```json
   "hooks": { "SessionEnd": [ { "matcher": "", "hooks": [ { "type": "command", "command": "bash ~/.claude/hooks/capture-session.sh" } ] } ] }
   ```
4. Fill in [`conductor/profile.yaml`](conductor/profile.yaml). This one file personalizes the whole loop.
5. Copy [`workflows/`](workflows/) into `.github/workflows/`, adjust the paths to your vault layout, and trigger each once from the Actions tab to test.

Start with the Scouts. They are the cleanest win and fully self-contained. Add the Conductor next. Add Consolidation last, once your capture buffer has built up a few weeks of material.

## Safety (tiered autonomy)

Inert writes happen automatically: capture, scout digests, mission boards, decay flags. Anything that becomes an always-loaded rule, or touches real config, is gated behind your approval. Every applied change is a git commit, which is the audit log and the rollback. A self-writing brain is an attack surface and a rot surface; the recurrence gate, the git history, and the human approval on promotion are what keep it honest.
