# 05. File Conventions: CLAUDE.md, MEMORY.md, STATE.md

Three files. No installs. Just patterns that turn Claude Code's built-in memory features into a working system.

## CLAUDE.md

**What it is:** A markdown file Claude Code auto-loads at session start when present in your project or vault root. Built-in feature, no setup beyond creating the file.

**Where it lives:** Root of your Obsidian vault, or root of any project repo.

**What goes in it:**

- Vault or repo structure overview
- Conventions (file naming, frontmatter, linking)
- Memory stack documentation (so Claude knows which layers to use when)
- Behavioral rules ("no em dashes", "use templates", "never modify raw/")

**Template:** `templates/CLAUDE.md.template` in this plugin.

**Rule of thumb:** Keep it under 200 lines. If you're past that, you're storing things that should live in subfolders or sub-`CLAUDE.md` files instead.

## MEMORY.md

**What it is:** A curated, hand-maintained strategic index that Claude Code auto-loads alongside CLAUDE.md. Some Claude Code distributions look for `MEMORY.md` in `~/.claude/projects/<project>/memory/`. Others use `CLAUDE.md` as the primary memory file. Check your Claude Code docs for the exact path.

**What goes in it:**

- The 5 to 10 hard rules you never want Claude to forget
- Current focus (north star, active priority, deadline)
- Active clients with stage and next action
- Active projects with status and STATE.md paths
- Strategic anchors

**Template:** `templates/MEMORY.md.template` in this plugin.

**Rule of thumb:** Keep it shorter than CLAUDE.md. Under one screen of content. This file should make you ask "would I want Claude to read this every single session?" If no, it belongs in a STATE.md or a wiki page instead.

## STATE.md per project

**What it is:** One file per active project. Lives at `projects/<project-name>/STATE.md` inside your vault. Captures where you left off and what to do next.

**Why it matters:** Solves the "I have no idea what I was working on" problem. With a properly maintained STATE.md, you can walk away from a project for two weeks, come back, and pick up in 30 seconds.

**What goes in it:**

```yaml
---
title: Project STATE
status: active | paused | blocked | done
next_action: Single concrete next step
blockers: List, or empty
last_touched: YYYY-MM-DD
trigger_word: PROJECT_NAME ONLINE
---

# 🚨 FIRST ACTION FOR THIS SESSION

Print the verbatim summary below as your first reply.

# Last session summary (verbatim)

Three to six bullets of what shipped, what got decided, what's open.

# Tasks queued for this session

Tier 1 (critical), Tier 2 (important), Tier 3 (nice).

# Context Claude needs

Repo path, deploy URL, key files, services in play.
```

**Template:** `templates/STATE.md.template` in this plugin.

## The trigger-word pattern

The most important thing in `STATE.md` is the **🚨 FIRST ACTION block**. Without it, sessions silently skip the handoff summary. With it, Claude prints the summary verbatim as the first chat reply every time.

How it works:

1. You define a trigger word in the frontmatter, for example `PORTAL ONLINE`.
2. When you start a new session, you say "PORTAL ONLINE."
3. Claude reads the STATE.md for that project, sees the 🚨 block, prints the verbatim summary.
4. You confirm. Then work begins with full context.

Without the loud 🚨 block, Claude reads the file but often summarizes or paraphrases, which loses critical detail. The instruction "print verbatim" is what forces the perfect handoff.

## End-of-session ritual

Last thing you do every session: update the relevant `STATE.md`. Two minutes max.

- What shipped this session
- What got decided
- What's blocked
- What the next action is

That's the entire system. Files you keep current carry all the rest.

## Common mistakes

1. **STATE.md without the 🚨 block.** The handoff silently fails. Always include it.
2. **Hand-maintaining an Active Context block in CLAUDE.md.** Don't. STATE.md owns active context. CLAUDE.md owns rules.
3. **MEMORY.md that grows past one screen.** It becomes noise. Move things to wiki/ or STATE.md.
4. **Multiple STATE.md files for one project.** One per project, period. Sub-features go inside the single STATE.md as sections.
5. **Forgetting to update STATE.md at session end.** Build the habit. Three days of skipping breaks the system.
