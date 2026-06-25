# Conductor Engine

The advisor. Runs nightly after the scouts. Reads the Tool Radar plus your profile plus active project state, ranks opportunities into missions, and writes a daily board. Optionally delivers the top 3 to a channel you choose (chat, email, a dashboard).

This is the organ that turns raw discovery into a decision. A scout that finds a new tool is noise. A mission that says "here is the tool, here is why it matters to you, here is the payoff, here is what it costs" is signal.

## Inputs
- `inbox/tool-radar.md` (scout deltas)
- `conductor/profile.yaml` (who you are, your ranking weights, your constraints)
- `conductor/mission-schema.md` (the output format)
- active `projects/**/STATE.md` (what is live right now)
- yesterday's dismissed missions (so it learns your taste)

## Outputs
- `inbox/missions/today.md` (the dashboard, overwritten each run)
- one line per mission appended to `inbox/missions/_log.md`
- optional: deliver the top 3 to your channel (gated; off until you wire it)

## The routine (prompt for `claude -p`)

```
You are the Conductor. No em dashes. Work only from the files named.

STEP 1 - Read conductor/profile.yaml (ranking weights, constraints, focus, the bottleneck it should optimize for), mission-schema.md (output format), inbox/tool-radar.md (candidate findings), and the active projects/**/STATE.md files. Read yesterday's dismissed missions.

STEP 2 - Build a candidate mission for every radar finding AND every live-project next-action that maps to a finding. Score each with the formula in profile.yaml (a weighted blend of impact, leverage, and edge). A MAIN quest moves your top metric or serves an active project. A SIDE quest is capability or time-save.

STEP 3 - Apply the anti-horoscope bar: a mission ships only if it has a concrete why-now, a why-you tied to an active focus, and a grounded potential (a real number or time-save) or one explicitly marked an estimate. Drop anything that fails. Drop any category your dismissed list shows you rejected repeatedly.

STEP 4 - Cap the daily push at the top 3. Write inbox/missions/today.md using mission-schema.md: top 3 first (full detail), then the rest of the board, then the dismissed section carried forward. Append the top 3 to inbox/missions/_log.md.

STEP 5 - Delivery: only if a delivery channel is configured AND enabled, send the top 3. Otherwise write a delivery draft into today.md and stop.

If tool-radar has no new deltas and no live-project changes, output "[SILENT] no new missions".
```

## The closed loop
The Conductor's accept / snooze / dismiss is training data. Feed your reactions back into the capture buffer, and over weeks the Conductor learns which kinds of missions you actually act on and stops showing you the rest. That feedback is what makes the system evolve its judgment about you, not just its config.
