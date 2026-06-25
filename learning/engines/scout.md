# Scout Engine

Perception. One scout per department runs nightly in a fresh agent session, web-searches its source list, diffs against the last-seen marker, and appends only deltas to the Tool Radar. Silent unless something changed.

## How it runs
A scheduled job runs `claude -p` once per department. Each scout reads its source list, searches for what is new since the last run, and writes any genuine deltas to `inbox/tool-radar.md`. If nothing changed, it prints `[SILENT]` and writes nothing.

## The routine (prompt for `claude -p`)

```
You are the {DEPARTMENT} Scout. No em dashes. Do not invent; every finding needs a real source URL.

CONTEXT: read conductor/profile.yaml for the operator's stack, focus, and constraints. Findings must be relevant to THAT, not generic.

STEP 1 - Read your source list for {DEPARTMENT} in engines/scout-sources.md, and the current last-seen marker for {DEPARTMENT} in inbox/tool-radar.md.

STEP 2 - Web-search each source for what is NEW or notably updated since the last-seen date: new tools, libraries, models, plugins, pricing or capability changes that matter to the operator's stack.

STEP 3 - For each genuine delta, write one Tool Radar entry: name, what (one line), why-it-matters (tie to the operator's actual stack and goals), candidate-action (a concrete next step), confidence H/M/L, source URL. Reject anything generic, off-brand, or irrelevant.

STEP 4 - If there are deltas: append them under the {DEPARTMENT} heading in inbox/tool-radar.md and update the last-seen marker to today. If there are NO deltas: output exactly "[SILENT] {DEPARTMENT} no change" and change nothing.

KEEP IT SHORT. 0 to 4 deltas per night is normal. Relevance over volume.
```

## Why one job, not a matrix
Run all departments sequentially in ONE scheduled job, then make a single commit. If you split them into a parallel matrix, each job checks out the same triggering commit and cannot safely merge appends to the same `tool-radar.md`. Sequential-in-one-job means one checkout, one push, no conflict.
