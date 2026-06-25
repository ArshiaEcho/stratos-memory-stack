#!/bin/bash
# capture-session.sh
# SessionEnd hook. No-ask capture of correction-cue triggers.
# Scans the session transcript for spoken rules ("from now on", "next time", ...)
# and appends them to a capture buffer as trigger-candidate lines. This is the
# afferent nerve of the learning loop: it records what you teach Claude in
# passing, before it is lost at session end.
#
# Install: copy to ~/.claude/hooks/capture-session.sh, then register in
# ~/.claude/settings.json under "SessionEnd" (see learning/README.md).
#
# Config: set CAPTURE_BUFFER to the markdown file you want captures appended to.
# Keep it INSIDE your git-tracked vault so the nightly Consolidation job can read it.

set -uo pipefail

PAYLOAD=$(cat)

# EDIT THIS: point it at a git-tracked file in your vault.
BUFFER="${CAPTURE_BUFFER:-$HOME/vault/inbox/_capture-buffer.md}"

# Need jq. If missing, exit silently. Never block session end.
command -v jq >/dev/null 2>&1 || exit 0

TRANSCRIPT=$(printf '%s' "$PAYLOAD" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "${TRANSCRIPT:-}" ] && [ -f "$TRANSCRIPT" ] || exit 0

# Correction-cue regex. Tunable.
CUES='from now on|going forward|next time|remember to|remember that|never again|always make sure|make sure to|note for next time'

# Markers that flag injected / system content (tool results, task notifications,
# pasted blobs). These arrive as user-role turns but are not human typing.
NOISE='<result>|</result>|system-reminder|task-notification|<task-|tool_use_id|SYSTEM NOTIFICATION|PostToolUse|PreToolUse|<function|hook additional context'

# Extract real user-typed turns: exclude subagent sidechains and tool-result blocks,
# join text blocks, drop empty/oversized turns (human rules are short), then keep
# only turns that contain a cue and no noise marker.
MATCHES=$(
  jq -rc 'select(.type=="user" and (.isSidechain==false))
          | .message.content as $c
          | (if ($c|type)=="string" then $c
             else ([$c[]? | select(.type=="text") | .text] | join(" ")) end)
          | gsub("\n";" ")
          | select(length > 0 and length <= 400)' \
     "$TRANSCRIPT" 2>/dev/null \
  | grep -iE "$CUES" \
  | grep -ivE "$NOISE" \
  | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
  | grep -v '^$'
)

[ -n "${MATCHES:-}" ] || exit 0

TODAY=$(date +%F)
mkdir -p "$(dirname "$BUFFER")"
[ -f "$BUFFER" ] || printf '# Capture Buffer\n' > "$BUFFER"
grep -qF "## $TODAY" "$BUFFER" || printf '\n## %s\n' "$TODAY" >> "$BUFFER"

while IFS= read -r line; do
  [ -n "$line" ] || continue
  clean=$(printf '%s' "$line" | tr '\n' ' ' | cut -c1-280)
  entry="- [trigger-candidate] \"$clean\""
  grep -qF -- "$entry" "$BUFFER" || printf '%s\n' "$entry" >> "$BUFFER"
done <<< "$MATCHES"

exit 0
