# Consolidation Engine

The librarian. Runs nightly in a fresh agent session. Reads the capture buffer, promotes recurring patterns into durable rules, flags stale facts, and writes a GATED digest. It never auto-edits enforced rules. Promotion and archival happen only after you approve the digest.

## Inputs
- `inbox/_capture-buffer.md` (the scratchpad the capture hook writes to)
- your `MEMORY.md` (current hard-rules, for dedupe)
- `bash lib/staleness-scan.sh` (decay flags)

## Output
- `inbox/brain-digest.md` (a proposal, never an auto-merge)

## The routine (prompt for `claude -p`)

```
You are the Consolidation engine. Work only from the files named. Do not invent. No em dashes.

STEP 1 - Read the capture buffer at inbox/_capture-buffer.md.

STEP 2 - Cluster the entries by theme. A PROMOTION CANDIDATE is any rule, preference, correction, or workflow that appears 2 or more times (across this buffer and the last 7 days of git history of this file), OR is explicitly tagged with a strong cue (trigger-candidate lines).

STEP 3 - For each candidate, decide the cheapest enforcement altitude and draft the exact change, but DO NOT APPLY IT:
  - A short durable constraint -> a one-line addition to MEMORY.md (show the exact line).
  - A repeatable multi-step workflow -> a new skill (name + description + when-to-use).
  - A reusable trigger phrase -> a mode-activator entry + the hook regex.
  Dedupe against the current MEMORY.md so you never propose something already enforced.

STEP 4 - Run `bash lib/staleness-scan.sh` and include its decay flags. For each, propose: re-validate, archive, or keep. Do not move anything yourself.

STEP 5 - Write inbox/brain-digest.md with: ## Promotions proposed, ## Decay flags, ## Buffer lines to delete on approval. If the buffer has no 2x recurrence and no decay, write only "[SILENT] no promotions, no decay".

SAFETY: never edit MEMORY.md, never create a skill, never delete buffer lines in this run. The digest is a proposal you approve. Every later applied change is a git commit (audit + rollback).
```

## The recurrence gate is the point
Cheap-to-write notes (the buffer) stay separate from expensive-to-load rules (always in context). A pattern has to recur before it graduates. That gate is what keeps your always-loaded context small and high-signal, and what stops one-off noise from becoming a permanent rule.
