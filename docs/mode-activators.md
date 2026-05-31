# Mode Activators

A pattern for vaults with multiple parallel project streams. Tells Claude which stream you are working in before claude-mem's auto-injection can mislead it.

## The bug

Last night you shipped Portal changes. The session captured cleanly. claude-mem stored a handoff. You closed your laptop.

This morning you sit down to do strategy work. You type `BRAIN ONLINE` expecting your strategy playbook to load. Instead, Claude opens with:

> Ready to continue from last night. Want me to verify the Portal deploy went through, or pick up the auth refactor we paused mid-session?

claude-mem did its job. It picked the most recent session and injected it. The problem is that the most recent session was the wrong stream for what you are doing now.

You correct Claude. Claude apologizes. Two messages of context window are already gone. By the time the strategy session is actually loaded, your opening pulse has been polluted by Portal terminology and Claude is half-anchored on the wrong work.

This is a daily failure mode the moment you have more than one active project.

## Root cause

Three things compound:

1. **claude-mem ranks by recency, not by intent.** The most recent session is rarely the most relevant one. You context-switched while you slept. The tool does not know that.
2. **Auto-injection happens before your prompt is read.** By the time Claude sees `BRAIN ONLINE`, it has already loaded the Portal handoff as system context. The opening response is shaped before you finish typing.
3. **ONLINE phrases are conventions, not instructions.** Claude treats `BRAIN ONLINE` as a phrase to interpret, not a routing decision to execute. Without something forcing the routing, it is just a string in the prompt.

The fix has to run before Claude reads the prompt, has to emit something Claude treats as authoritative, and has to explicitly counteract whatever was auto-injected.

## The solution

A `UserPromptSubmit` hook at `~/.claude/hooks/superpowers-suggest.sh` that:

1. Reads the prompt from stdin (Claude Code passes JSON).
2. Lowercases it for matching.
3. Greps for ONLINE-suffix phrases against a list of known modes.
4. On a match, emits a `## 🚨 MODE: <NAME>` block at the top of the system reminder. The block lists files to load and explicitly tells Claude to SUPPRESS context from other streams.
5. If no mode matches, emits nothing extra. Normal prompts are untouched.

The 🚨 emoji and the SUPPRESS directive matter. Claude treats them as high-priority instructions. The mode block prints first, so it sits above any auto-injected handoff in the reminder.

## Reference hook

Save as `~/.claude/hooks/superpowers-suggest.sh`, then `chmod +x` it, then register it as a `UserPromptSubmit` hook in `~/.claude/settings.json`.

```bash
#!/bin/bash
# Mode activator hook. Scans the user's prompt for ONLINE-suffix mode phrases
# and prepends a strong directive that overrides auto-injected context from
# the wrong project stream.

set -euo pipefail

PROMPT_JSON=$(cat)

if command -v jq >/dev/null 2>&1; then
  PROMPT=$(echo "$PROMPT_JSON" | jq -r '.prompt // .user_prompt // empty' 2>/dev/null || echo "$PROMPT_JSON")
else
  PROMPT="$PROMPT_JSON"
fi

PROMPT_LC=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

MODE_ACTIVATOR=""

set_mode() {
  # Only the first matched mode wins.
  if [ -z "$MODE_ACTIVATOR" ]; then
    MODE_ACTIVATOR="$1"
  fi
}

# Each pattern uses ^[[:space:]]* to anchor at the START of the prompt (allowing
# leading whitespace). This prevents false positives like "thinking about my
# brain online dating app" from firing the BRAIN ONLINE mode. The phrase must
# LEAD the prompt to be treated as a mode switch.

if echo "$PROMPT_LC" | grep -qE '^[[:space:]]*(brain online)\b'; then
  set_mode "## 🚨 MODE: BRAIN ONLINE (strategy / system work)

**Load these files before responding:**
- \`Arshia/areas/claude-ops/brain-upgrade/BRAIN-ONLINE-playbook.md\`
- \`Arshia/areas/claude-ops/brain-upgrade/active-tasks.md\`
- Latest \`Arshia/areas/claude-ops/brain-upgrade/*phase*.md\`

**SUPPRESS:** any auto-injected handoff from a different project stream (Portal, Monoli, Elora, etc.). The user is in strategy mode, NOT client delivery mode. Do NOT lead with portal verification or client status updates unless asked.

**Follow the playbook opener:** status pulse, backlog, recommendations, today's focus options."
fi

if echo "$PROMPT_LC" | grep -qE '^[[:space:]]*(portal online)\b'; then
  set_mode "## 🚨 MODE: PORTAL ONLINE

**Load these files before responding:**
- \`Arshia/projects/stratos/client-portal/STATE.md\`
- Latest portal session handoff doc

**SUPPRESS:** any auto-injected context from non-portal streams."
fi

# Add more modes here. Same pattern. Five lines each.

if [ -n "$MODE_ACTIVATOR" ]; then
  echo "$MODE_ACTIVATOR"
  echo ""
fi

exit 0
```

**Precedence is SCRIPT ORDER, not prompt-text order.** If a single prompt contains both `BRAIN ONLINE` and `PORTAL ONLINE`, whichever `if` block runs first in the script wins (even if the user typed the other one first in the text). Put your most-used modes near the top so you get the right default when phrases collide. In practice they rarely do, because ONLINE-suffix phrases are distinctive enough.

**Anchoring matters.** The `^[[:space:]]*` prefix on each regex means the mode phrase must LEAD the prompt (after any leading whitespace). Without this anchor, casual phrases like "thinking about my brain online dating app" would incorrectly fire the BRAIN ONLINE mode block and suppress legitimate context. If you change the anchor to a plain `\b(...)\b`, you get false positives every time the mode phrase appears anywhere in the prompt.

## Adding a new mode

Three steps. Should take two minutes.

1. **Edit the hook.** Copy an existing `if echo "$PROMPT_LC" | grep -qE ...` block. Change the phrase. Change the file list. Change the SUPPRESS clause to name the streams you want quieted.
2. **Document it.** Add a row to the table in the README's Mode Activators section so you remember what you set up. Future you will forget.
3. **Test it.** Open a fresh Claude Code session. Type the phrase. Confirm the 🚨 block shows up in the system reminder before Claude responds. If it does not, check `chmod +x` on the hook and check the `UserPromptSubmit` entry in `settings.json`.

That is the entire loop. Modes are cheap. Add one whenever a new project becomes a regular stream.

## Limitations

This is a band-aid. The real fix is per-stream namespacing in claude-mem so the injection is filtered by project before it lands. That work is upstream and not yet shipped. Until then:

- The hook is a string match, not semantic routing. If you type `working on brain stuff today`, nothing fires. You have to use the exact ONLINE phrase.
- Claude can still ignore the SUPPRESS directive on a bad day. The 🚨 emoji and explicit framing make it rare, but it is not enforced.
- Only the first matched mode wins. If you type two ONLINE phrases in the same prompt, the second is silently dropped. This is intentional. Two modes at once is usually a sign you wanted neither.
- The hook runs on every prompt. The cost is a single grep pass over the prompt text. Negligible, but worth knowing if you are auditing latency.

## When NOT to use this pattern

Single-stream vaults do not need this. If everything in your vault is one project, claude-mem's recency ranking is correct by definition. The auto-injection will pick the right session because there is only one possible right session.

You start needing mode activators when:

- You have three or more active streams.
- You context-switch between them on a daily or sub-daily basis.
- The streams use overlapping vocabulary (e.g., "deploy" means something different in each one).

If you only have two streams and you mostly work on one for days at a stretch, you can probably skip this and just manually correct Claude on the rare wrong-stream morning. The hook earns its keep when the corrections start happening every day.
