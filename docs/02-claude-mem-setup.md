# 02. claude-mem Setup

claude-mem captures your Claude Code sessions automatically and injects relevant past context at the start of your next session. Replaces the "let me re-read NEXT-SESSION-START.md" pattern.

Built by Alex Newman ([@thedotmack](https://github.com/thedotmack)). MIT licensed. Currently at v13.x.

## Links

- Site: https://claude-mem.ai
- GitHub: https://github.com/thedotmack/claude-mem

## Install (Claude Code plugin)

Open Claude Code and run:

```
/plugin marketplace add thedotmack/claude-mem
/plugin install claude-mem@thedotmack
```

Confirm the install. Restart Claude Code if prompted.

## Verify

```bash
ls ~/.claude/plugins/cache/thedotmack/claude-mem 2>/dev/null && echo "INSTALLED" || echo "NOT FOUND"
```

You should see the plugin folder listed and "INSTALLED" printed.

Also check `~/.claude/settings.json` includes:

```json
{
  "enabledPlugins": {
    "claude-mem@thedotmack": true
  }
}
```

## How it shows up

Open a new Claude Code session. Within the first message, you'll see a block of recent observations that looks something like:

```
Legend: 🎯session 🔴bugfix 🟣feature 🔄refactor ✅change 🔵discovery ⚖️decision

### May 27, 2026
455 12:24a 🟣 Automated screenshot capture for Stratos Portal Tour scenes
456 " 🔵 Partial screenshot capture: only scene 1 captured
```

That's claude-mem auto-injecting summaries of past sessions. Each line has an ID. Claude can fetch full details on demand using the MCP tools claude-mem provides.

## What it captures

- Decisions you made and why
- Features you shipped
- Bugs you fixed
- Discoveries about the codebase
- Open questions and follow-ups

It does NOT capture raw transcripts. Just observations with timestamps. Storage is local SQLite.

## Common commands

```bash
npx claude-mem search "stratos portal"        # search past sessions
npx claude-mem list                           # list recent sessions
npx claude-mem context                        # show what would auto-inject now
```

## Tune it

claude-mem auto-decides what to surface. If you find it too noisy or too sparse, edit its config (location depends on version, check the GitHub README for current path).

## Why this layer matters

Without claude-mem, every Claude Code session starts cold. You re-explain context, re-paste paths, re-state decisions. That's 5 to 15 minutes per session of pure waste. With claude-mem, the session opens already knowing what you were doing yesterday. It's the single biggest workflow change in the whole stack.
