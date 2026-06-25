#!/bin/bash
# staleness-scan.sh
# Deterministic decay helper for the Consolidation engine. Scans project
# STATE.md frontmatter and flags entries that are stale (last_touched older
# than STALE_DAYS) or carry a paused/archived status. Read-only. Prints a
# markdown flag list the Consolidation routine folds into the nightly digest.
# Flagging only; archival is a gated action you approve.
#
# Usage:  bash staleness-scan.sh
# Env:    VAULT (path to your vault, default below), STALE_DAYS (default 90)

set -uo pipefail

VAULT="${VAULT:-$HOME/vault}"          # EDIT THIS to your vault root
DAYS="${STALE_DAYS:-90}"
NOW=$(date +%s)
CUTOFF=$(( NOW - DAYS * 86400 ))

found=0
while IFS= read -r f; do
  head=$(sed -n '1,40p' "$f")
  lt=$(printf '%s\n' "$head" | grep -iE '^last_touched:' | head -1 | sed -E 's/^[^:]+:[[:space:]]*//; s/["'\'' ]//g' | tr -d '\r')
  st=$(printf '%s\n' "$head" | grep -iE '^status:' | head -1 | sed -E 's/^[^:]+:[[:space:]]*//' | sed -E 's/[[:space:]]+$//' | tr -d '\r')
  rel="${f#"$VAULT"/}"
  reason=""

  case "$(printf '%s' "$st" | tr '[:upper:]' '[:lower:]')" in
    *paused*|*archived*|*on-hold*|*on_hold*|*dormant*|*stalled*|*closed*lost*)
      reason="status=${st}" ;;
  esac

  if [ -n "${lt:-}" ]; then
    ts=$(date -j -f "%Y-%m-%d" "${lt:0:10}" +%s 2>/dev/null || date -d "${lt:0:10}" +%s 2>/dev/null || true)
    if [ -n "${ts:-}" ] && [ "$ts" -lt "$CUTOFF" ]; then
      age=$(( (NOW - ts) / 86400 ))
      reason="${reason:+${reason}, }last_touched=${lt:0:10} (${age}d ago)"
    fi
  fi

  if [ -n "$reason" ]; then
    echo "- [decay] ${rel} (${reason})"
    found=$(( found + 1 ))
  fi
done < <(find "$VAULT/projects" -name STATE.md 2>/dev/null)

[ "$found" -eq 0 ] && echo "[SILENT] no stale project STATE.md entries (threshold ${DAYS}d)"
exit 0
