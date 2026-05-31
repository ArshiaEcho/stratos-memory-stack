---
name: stratos-memory-stack
description: Audit, install, and configure the Stratos Memory Stack for Claude Code (six layers: claude-mem, basic-memory, Obsidian, Pinecone, CLAUDE.md/MEMORY.md, STATE.md) plus the optional Mode Activators hook for multi-stream vaults. Use when the user says "set up memory", "install the memory stack", "audit my memory", "what memory layers do I have", "Stratos memory stack", "mode activators", "wrong project context", "/stratos-memory-stack", or asks for persistent context across Claude Code sessions.
---

# Stratos Memory Stack

You are setting up or auditing a six-layer persistent memory system for Claude Code. The user wants Claude to remember context across sessions, search their knowledge base by meaning, and never re-explain a project from scratch.

## The Six Layers

| # | Layer | Type | Job |
|---|---|---|---|
| 1 | `claude-mem` | Plugin | Auto-captures sessions, auto-injects past context next session |
| 2 | `basic-memory` | MCP server | Semantic search over the user's knowledge vault |
| 3 | Obsidian | App | Source of truth, local markdown notes |
| 4 | Pinecone | Cloud + scripts | Vector archive of immutable raw docs |
| 5 | `CLAUDE.md` + `MEMORY.md` | File convention | Rules auto-loaded every session |
| 6 | `STATE.md` per project | File convention | Per-project resume state with handoff summary |

## Workflow

Run in two phases. Always start with **Audit**. Only proceed to **Install** for missing layers after the user confirms.

---

## Phase 1: Audit

Check each layer in order. Report results as a single status table at the end. Do not stop mid-audit even if early checks fail.

### Layer 1: claude-mem

Check whether the plugin is installed and enabled:

```bash
ls ~/.claude/plugins/cache/thedotmack/claude-mem 2>/dev/null && echo "FOUND" || echo "MISSING"
```

Also check `~/.claude/settings.json` for `"claude-mem@thedotmack": true` under `enabledPlugins`.

**Status:**
- `INSTALLED` if both checks pass
- `PARTIAL` if installed but not enabled in settings
- `MISSING` otherwise

### Layer 2: basic-memory

Check if the MCP server is configured:

```bash
cat ~/.claude.json 2>/dev/null | grep -i "basic-memory" | head -3
cat ./.mcp.json 2>/dev/null | grep -i "basic-memory" | head -3
which basic-memory 2>/dev/null
```

Also look for the tool in the current Claude Code session by checking if `mcp__basic-memory__*` tools appear in available tools.

**Status:** `INSTALLED` / `PARTIAL` (CLI present but no MCP config) / `MISSING`

### Layer 3: Obsidian

Detect whether the current working directory is an Obsidian vault, or if one exists nearby:

```bash
ls .obsidian 2>/dev/null && echo "VAULT_HERE" || echo "NO_VAULT_HERE"
find ~ -maxdepth 4 -name ".obsidian" -type d 2>/dev/null | head -3
```

Check structure: look for `inbox/`, `projects/`, `areas/`, `resources/`, `knowledge/`, `_templates/`.

**Status:**
- `INSTALLED` if vault found with at least 3 of the expected folders
- `PARTIAL` if vault exists but lacks the recommended structure
- `MISSING` if no vault found

### Layer 4: Pinecone

Check for the standard scripts and credentials:

```bash
find . -name "pinecone_query.py" -maxdepth 4 2>/dev/null | head -3
find . -name "pinecone_ingest.py" -maxdepth 4 2>/dev/null | head -3
grep -l "PINECONE_API_KEY" .env knowledge/.env 2>/dev/null
```

**Status:**
- `INSTALLED` if both scripts + a `.env` with the key exist
- `PARTIAL` if scripts exist but no key, or key exists but no scripts
- `MISSING` otherwise. Flag as **optional** since Pinecone only matters once the user has raw archives worth indexing.

### Layer 5: CLAUDE.md and MEMORY.md

```bash
ls CLAUDE.md ~/CLAUDE.md 2>/dev/null
ls ~/.claude/projects/*/memory/MEMORY.md 2>/dev/null
```

Read any `CLAUDE.md` found and check whether it includes:
- Vault/repo structure overview
- File naming conventions
- Memory system documentation
- Behavioral rules

**Status:**
- `INSTALLED` if `CLAUDE.md` exists and covers structure + conventions
- `PARTIAL` if file exists but is thin (under 30 lines, missing sections)
- `MISSING` if no file

### Layer 6: STATE.md per project

```bash
find . -name "STATE.md" -path "*/projects/*" -maxdepth 5 2>/dev/null | head -5
find . -name "STATE.md" -maxdepth 3 2>/dev/null | head -5
```

For each found file, check whether it has the standard frontmatter (`status`, `next_action`, `blockers`, `last_touched`) and a 🚨 FIRST ACTION block.

**Status:**
- `INSTALLED` if at least one STATE.md exists with the full pattern
- `PARTIAL` if files exist but lack the FIRST ACTION block
- `MISSING` if no project STATE.md files

### Bonus: Mode Activators (only check if multi-stream vault)

Mode Activators are an optional `UserPromptSubmit` hook that fixes the wrong-stream context injection problem in vaults with multiple parallel projects. Only relevant when the user has 3+ active project streams. Single-stream vaults do not need this.

Detect whether to check at all:

```bash
find . -name "STATE.md" -path "*/projects/*" -maxdepth 5 2>/dev/null | wc -l
```

If count < 3, mark this row as `N/A (single-stream vault)` and skip the rest. If count >= 3, run the checks below:

```bash
# Is any UserPromptSubmit hook registered?
cat ~/.claude/settings.json 2>/dev/null | jq '.hooks.UserPromptSubmit // empty'

# Does any registered hook script contain MODE: activator patterns?
grep -lE 'MODE:|mode_activator|set_mode' ~/.claude/hooks/*.sh 2>/dev/null
```

**Status:**
- `INSTALLED` if hook is registered AND script contains MODE: patterns
- `PARTIAL` if hook registered but no mode patterns (some other hook), OR mode script exists but hook not wired
- `MISSING` if no hook with mode patterns
- `N/A` if single-stream vault (count < 3)

### Audit report format

Present results to the user as a single table, then a one-line summary, then a single question asking which missing layer to install first.

```
| # | Layer                  | Status     | Notes                                  |
|---|------------------------|------------|----------------------------------------|
| 1 | claude-mem             | INSTALLED  | v13.3.0, enabled                       |
| 2 | basic-memory           | MISSING    | No MCP config found                    |
| 3 | Obsidian               | PARTIAL    | Vault at ~/notes, no projects/ folder  |
| 4 | Pinecone (optional)    | MISSING    | Skip unless user has raw archives      |
| 5 | CLAUDE.md / MEMORY.md  | INSTALLED  | 90 lines, covers all sections          |
| 6 | STATE.md               | PARTIAL    | 2 files found, neither has 🚨 block    |
| + | Mode Activators (bonus)| MISSING    | 4 active streams found, hook not set   |
```

The Mode Activators row appears only when the bonus check ran (>= 3 streams). Omit the row entirely for single-stream vaults.

Then ask: "You're missing X, Y, Z. Want to start with [recommended next layer]?"

---

## Phase 2: Install

Only proceed after the user confirms which layer to install. Install one layer at a time and verify before moving on.

For each layer, the full step-by-step lives in the `docs/` folder of this plugin. Follow those guides:

- **claude-mem** → `docs/02-claude-mem-setup.md`
- **basic-memory** → `docs/03-basic-memory-setup.md`
- **Obsidian + vault structure** → `docs/01-obsidian-setup.md`
- **Pinecone** → `docs/04-pinecone-setup.md`
- **File conventions (CLAUDE.md, MEMORY.md, STATE.md)** → `docs/05-file-conventions.md`
- **Mode Activators (bonus, multi-stream vaults)** → `docs/mode-activators.md`

Templates are in `templates/`:

- `CLAUDE.md.template`
- `MEMORY.md.template`
- `STATE.md.template`
- `pinecone_ingest.py`
- `pinecone_query.py`
- `mode-activator-hook.sh.template`

When installing a file-convention layer, copy the template, fill in vault-specific details with the user's input, and confirm before writing.

For the Mode Activators install: copy `templates/mode-activator-hook.sh.template` to `~/.claude/hooks/mode-activator.sh`, `chmod +x` it, then register it under `hooks.UserPromptSubmit` in `~/.claude/settings.json`. Ask the user which streams to define modes for (one per active project STATE.md found in audit) and pre-populate the hook with their actual file paths.

## Recommended install order

If the user has nothing, install in this order:

1. **Obsidian** + vault structure (foundation)
2. **CLAUDE.md** (rules)
3. **STATE.md** for one active project (immediate value)
4. **claude-mem** (auto session capture)
5. **basic-memory** (vault search)
6. **Pinecone** (only if user has raw archives)
7. **Mode Activators** (only if vault has 3+ active project streams; skip otherwise)

Justify the order: every other layer depends on Obsidian existing. CLAUDE.md and STATE.md give immediate value with zero installs. claude-mem and basic-memory require a bit more setup. Pinecone is only worth it when there's content to index. Mode Activators only earns its keep once the user has enough parallel streams that claude-mem's recency-based auto-injection starts picking the wrong stream.

## Rules

- Never install anything without explicit user confirmation per layer.
- Never write to user files outside the install step you announced.
- Never claim a layer is installed without running the verification command.
- Always prefer additive changes. If a `CLAUDE.md` already exists, suggest a diff, do not overwrite.
- No em dashes in any generated text. Use periods, commas, regular hyphens.

## Reporting

After each install, run the relevant audit check again and confirm the layer flipped from `MISSING` to `INSTALLED`. If it didn't, debug before moving to the next layer.

At the end of the full install, print the final 6-row status table again and summarize what changed.
