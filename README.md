<div align="center">
  <img src="assets/social-preview.png" alt="Stratos Memory Stack" width="100%" />
</div>

<h1 align="center">Stratos Memory Stack</h1>

<p align="center">
  <strong>Memory that learns and keeps itself current.</strong><br/>
  Seven layers that remember. A learning loop that keeps it sharp. Drop in. Audit. Install what's missing.
</p>

<p align="center">
  <a href="#install"><img src="https://img.shields.io/badge/Claude_Code-Plugin-7FFFB0?style=flat-square&labelColor=050709" alt="Claude Code Plugin"/></a>
  <a href="#the-learning-loop"><img src="https://img.shields.io/badge/Self_Evolving-Learning_Loop-CDB06A?style=flat-square&labelColor=050709" alt="Learning Loop"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-F2F5F4?style=flat-square&labelColor=050709" alt="MIT License"/></a>
  <a href="https://www.stratosagency.ai"><img src="https://img.shields.io/badge/by-Stratos_House_AI-F2F5F4?style=flat-square&labelColor=050709" alt="by Stratos House AI"/></a>
</p>

---

## What this is

A free Claude Code plugin in two halves.

**The memory half (seven layers).** Install it, run the skill, and Claude will:

1. **Audit** your machine. Check which of the seven layers you already have.
2. **Report** a clean status table (`INSTALLED` / `PARTIAL` / `MISSING` per layer).
3. **Install** the missing pieces one at a time, with your confirmation.

You end up with a stack that means you never re-explain a project, never lose a decision, and never re-read a 40-page doc to find one number.

**The learning half (a nightly loop).** Memory remembers. Learning changes behavior. The loop captures the rules you teach Claude in passing, scouts the web every night for new tools that fit you, and ranks them into a daily board of opportunities. Your brain stops being a notebook and starts being a nervous system. [Jump to the learning loop](#the-learning-loop).

## The seven layers

| # | Layer | What it does |
|---|---|---|
| 1 | **[claude-mem](https://github.com/thedotmack/claude-mem)** | Auto-captures every session, auto-injects relevant past context next session. |
| 2 | **[basic-memory](https://github.com/basicmachines-co/basic-memory)** | Semantic search over your whole knowledge vault, exposed as MCP tools. |
| 3 | **[Obsidian](https://obsidian.md)** | Local markdown notes. The source of truth everything else points at. |
| 4 | **[Pinecone](https://www.pinecone.io)** | Vector archive of immutable raw docs for fast quoting without re-reading. |
| 5 | **`CLAUDE.md` + `MEMORY.md`** | Rules and priorities Claude Code auto-loads every session. |
| 6 | **`STATE.md` per project** | Per-project resume file with verbatim handoff summary. |
| 7 | **Unified retrieval engine** | One pgvector table over every corpus, hybrid search fused with RRF, served as MCP primitives. Optional, advanced. |

Four are tools you install. Two are file patterns you adopt. The seventh is a small engine you build from [`docs/08-unified-retrieval.md`](docs/08-unified-retrieval.md) once a corpus outgrows the prompt window. All seven talk to each other.

## How they connect

```
                  IMMUTABLE
        ┌─ Pinecone (raw archives, semantic search) ─┐
            ┌── Obsidian vault (living notes, you write) ──┐
                ┌── basic-memory (vault index, MCP search) ──┐
                    ┌── claude-mem (session capture + replay) ──┐
                        ┌── CLAUDE.md / MEMORY.md (rules) ──┐
                            ┌── STATE.md (active resume) ──┐
                                EPHEMERAL / CURATED
```

The spine is Obsidian. Every other layer is a lens on it.

- `basic-memory` indexes the vault for semantic search.
- `claude-mem` captures what you do *with* the vault.
- `Pinecone` archives a frozen slice for fast quoting.
- `CLAUDE.md`, `MEMORY.md`, and `STATE.md` are pointers *into* the vault that load at the right time.

Full architecture writeup: [`docs/architecture.md`](docs/architecture.md).

## Layer 7: the unified retrieval engine

Layers 1-6 remember perfectly inside their own lanes, but a real question ("what did we decide about X?") can live in a meeting transcript, a vault note, or a session summary, and each layer has to be searched separately with no shared ranking. Layer 7 is the fix: **one query, every corpus, one fused ranking.**

The pattern is adapted from the internal knowledge base Cerebras published in July 2026 (15,000 employee questions a day), scaled down to run on a laptop for one person at zero embedding cost:

- **One Postgres + pgvector table.** Every source (meetings, notes, code, anything) lands in the same row shape through a small connector script. The row contract IS the integration surface.
- **Distill before you embed.** Raw conversations are never embedded. A small model extracts a normalized artifact (summary, decisions, action items, key facts) and that is what gets indexed. This was Cerebras' single biggest accuracy win.
- **Hybrid retrieval, fused.** Vector search catches paraphrase, full-text catches exact tokens, recency breaks ties. Reciprocal rank fusion merges the lists so consensus beats any single scorer. Optional small-model rerank on the top 20.
- **MCP primitives, not an answer machine.** Tools return raw evidence rows, LLM-free. The calling agent orchestrates and synthesizes with citations.
- **Delta-only and loud-failure.** Content hashing makes re-ingestion nearly free; ingest workers abort visibly instead of dying silently.

When NOT to build it: if your corpus fits in ~200k tokens, prompt caching beats retrieval. Build Layer 7 for the corpora that cannot fit.

Full pattern, schema, and setup: [`docs/08-unified-retrieval.md`](docs/08-unified-retrieval.md).

## The learning loop

The layers above are the **recall** half. They remember perfectly, but they never get smarter on their own, and they do not know what shipped in the world this week. The learning loop is the **write-back** half. Four small organs, running nightly, that turn your brain from a notebook into a nervous system.

```
        +-----------------------------------------------+
        |                                               v
   (1) CAPTURE --> (2) CONSOLIDATION --> rules / skills
   SessionEnd hook    promote repeated                  |
   writes the rules   lessons, flag stale facts         | feeds judgment
   you say out loud   (a digest you approve)            v
        ^                                         (4) CONDUCTOR --> your channel
        |                                         ranks the radar into     + a board
        | your accept / dismiss                   a daily board of missions
        | is training data                              ^
        +----------------------------------------------+
                                                        |
   (3) SCOUTS: nightly, per department, diff your        |
       sources and append only what is new --------------+
```

| Organ | What it does |
|---|---|
| **Capture** | A `SessionEnd` hook records the rules you say in passing ("from now on, always...") before they are lost. |
| **Consolidation** | Nightly, it promotes a pattern that recurs 2-3 times into an enforced rule, and flags stale facts. It writes a digest you approve; it never edits rules on its own. |
| **Scouts** | Nightly, one scout per department web-searches your sources for genuinely new tools, models, and libraries that fit your stack, and files them to a tool-radar. Silent when nothing changed. |
| **Conductor** | Nightly, it ranks the radar into a short board of opportunities, by weights you set, and delivers the top few to a channel you choose. |

**It runs for free.** The nightly engines run on GitHub Actions. Your vault is already a git repo, so "check out, run `claude -p`, commit back" is the platform's native motion. The only cost is the Anthropic tokens per run, capped with `--max-budget-usd`. A realistic bill is a few dollars a month. No new server, no new database, markdown and git all the way down, so every change the brain makes to itself is a commit you can read and revert.

**The loop closes.** The Conductor shows you missions. You accept, snooze, or dismiss. That reaction becomes capture, and over weeks the Conductor learns which missions you actually act on. It evolves its judgment about *you*, not just its config.

Full pattern, engine routines, ready-to-use workflows, and the profile that personalizes it: **[`learning/`](learning/)**.

## The contract-first delivery gate

If you use this stack for client or stakeholder work, there is a failure mode that perfect recall makes *worse*: the agent verifies its work against its own session summaries instead of the customer's actual request, and the summaries drift. Everything reads green while the customer keeps being right. We hit this in production; the write-up and the fix are in **[`docs/07-contract-first-gate.md`](docs/07-contract-first-gate.md)**: treat the customer's source messages as immutable raw material, keep a per-engagement contract audit note ([template](templates/CONTRACT-AUDIT.md.template)), encode the delivery gate at three altitudes (always-loaded CLAUDE.md, a deep rule with the story attached, per-project STATE.md), and verify behavior on the customer's hardware envelope, not your own.

## Mode Activators

Once you have more than one active project stream in your vault, claude-mem will start picking the wrong one. The last session you ran was Portal shipping work. This morning you sit down to do strategy work and type `BRAIN ONLINE`. claude-mem auto-injects the Portal handoff because it was most recent, and Claude opens with "ready to verify the portal deploy?" You wanted a strategy pulse.

That is the wrong-stream problem. The fix is small. A `UserPromptSubmit` hook scans your prompt for ONLINE-suffix phrases and prepends a strong directive to the system reminder. The directive tells Claude which files to load for the requested mode, and explicitly tells it to suppress the auto-injected context from any other stream.

You type the phrase. The hook fires before Claude reads the auto-injection. The mode wins.

Define your own modes. The shape is `<NAME> ONLINE` (or any phrase you want to anchor on). A few illustrative examples to copy and adapt:

| Phrase | Loads | Suppresses |
|---|---|---|
| `STRATEGY ONLINE` | your strategy playbook, current backlog | client-delivery + ops streams |
| `CLIENT-A ONLINE` | `projects/client-a/STATE.md`, latest client-a handoff | all other client streams |
| `PRODUCT ONLINE` | `product/STATE.md`, latest sprint notes | non-product streams |

Replace `STRATEGY` / `CLIENT-A` / `PRODUCT` with the names of your actual streams. The pattern is what matters, not the labels.

The hook only adds the activator block when a phrase matches. Normal prompts are untouched. Adding a new mode is a five-line edit.

Full pattern, reference hook, and limitations: [`docs/mode-activators.md`](docs/mode-activators.md).

## Install

In Claude Code:

```text
/plugin marketplace add ArshiaEcho/stratos-memory-stack
/plugin install stratos-memory-stack@stratos
```

Then trigger the skill:

```text
/stratos-memory-stack
```

Claude will run the audit and walk you through installing what's missing. To add the nightly learning loop after your memory layers are in place, follow [`learning/README.md`](learning/README.md).

## What the audit looks like

```
| # | Layer                  | Status     | Notes                                  |
|---|------------------------|------------|----------------------------------------|
| 1 | claude-mem             | INSTALLED  | v13.3.0, enabled                       |
| 2 | basic-memory           | MISSING    | No MCP config found                    |
| 3 | Obsidian               | PARTIAL    | Vault at ~/notes, no projects/ folder  |
| 4 | Pinecone (optional)    | MISSING    | Skip unless user has raw archives      |
| 5 | CLAUDE.md / MEMORY.md  | INSTALLED  | 90 lines, covers all sections          |
| 6 | STATE.md               | PARTIAL    | 2 files found, neither has 🚨 block    |
| 7 | Unified retrieval (opt)| MISSING    | No pgvector index found; corpus small  |
```

Followed by: "You're missing X, Y, Z. Want to start with [recommended next layer]?"

## Manual setup (without the skill)

If you want to read through everything before letting Claude touch your machine:

- [`docs/01-obsidian-setup.md`](docs/01-obsidian-setup.md) - Obsidian + vault structure
- [`docs/02-claude-mem-setup.md`](docs/02-claude-mem-setup.md) - claude-mem install
- [`docs/03-basic-memory-setup.md`](docs/03-basic-memory-setup.md) - basic-memory MCP
- [`docs/04-pinecone-setup.md`](docs/04-pinecone-setup.md) - Pinecone (optional)
- [`docs/05-file-conventions.md`](docs/05-file-conventions.md) - CLAUDE.md, MEMORY.md, STATE.md
- [`docs/06-learning-loop.md`](docs/06-learning-loop.md) - the nightly learning loop (capture, consolidate, scouts, conductor)
- [`docs/08-unified-retrieval.md`](docs/08-unified-retrieval.md) - Layer 7, the unified retrieval engine (pgvector + hybrid search + RRF, optional)
- [`docs/mode-activators.md`](docs/mode-activators.md) - Mode Activators hook for multi-stream vaults (optional)
- [`docs/architecture.md`](docs/architecture.md) - How it all fits together

Templates to copy:

- [`templates/CLAUDE.md.template`](templates/CLAUDE.md.template)
- [`templates/MEMORY.md.template`](templates/MEMORY.md.template)
- [`templates/STATE.md.template`](templates/STATE.md.template)
- [`templates/pinecone_ingest.py`](templates/pinecone_ingest.py)
- [`templates/pinecone_query.py`](templates/pinecone_query.py)
- [`templates/mode-activator-hook.sh.template`](templates/mode-activator-hook.sh.template) - starter `UserPromptSubmit` hook with 2 example modes
- [`learning/`](learning/) - the full learning loop: hook, engine routines, workflows, profile

## Recommended install order

If you're starting from zero, do it in this order:

1. **Obsidian** + vault structure (foundation)
2. **`CLAUDE.md`** (rules)
3. **`STATE.md`** for one active project (immediate value)
4. **`claude-mem`** (auto session capture)
5. **`basic-memory`** (vault search)
6. **`Pinecone`** (only if you have raw archives)
7. **The learning loop** (once the memory layers are stable, add the nightly capture + scouts + conductor)
8. **The unified retrieval engine** (last, and only once a corpus has outgrown the prompt window)

Total time to a working memory stack: about 2 hours, spread across a week as you actually need each piece. The learning loop is another hour once you are ready. The skill walks you through each step.

## Why this stack

Most "AI memory" setups pick one tool and try to make it do everything. They all hit the same wall: a vector DB is bad at rules, a rules file is bad at search, a session log is bad at archives.

This stack works because **every layer has a different write authority and a different recall mechanism**, so they don't fight each other.

- Obsidian for living notes you write.
- Pinecone for frozen archives you only read.
- `STATE.md` for active resume state.
- `MEMORY.md` for never-forget rules.
- `claude-mem` for "what did past me decide?"
- `basic-memory` for the search layer that ties it all together.

And then the learning loop sits on top, so the whole thing does not just remember, it gets sharper and keeps itself current. No layer tries to be the whole brain. Each one does one job well.

## Owned memory vs vendor memory (July 2026)

Since this stack first shipped (May 2026), memory went native. Claude now generates memory from your chats and consolidates it overnight. ChatGPT rebuilt its memory system in June 2026. New agent memory frameworks launch weekly.

Turn the native features on. They are useful, and nothing here conflicts with them.

But they are not a replacement, for one structural reason: vendor memory lives inside the vendor's product, on the vendor's terms. When a provider re-architects (as happened in the June 2026 rebuild, when some users reported years of saved memories no longer surfacing), your accumulated context changes with it, and none of it is portable.

This stack is the opposite bet. Plain markdown and local databases, readable by any model, exportable by design. The models underneath get swapped or retired, and the memory does not notice.

## A typical day, end to end

1. Open Claude Code in your vault. `claude-mem` auto-injects relevant past context.
2. Claude auto-loads `CLAUDE.md` and `MEMORY.md`. You say a trigger word; it reads the right `STATE.md` and prints the handoff.
3. You work. Claude searches via `basic-memory`, quotes from `Pinecone`, and when you say "from now on, always..." the **capture** hook quietly records it.
4. End of session: `STATE.md` and `claude-mem` update. The capture buffer holds today's lessons.
5. Overnight, on their own: the **scouts** find what shipped in your field, the **conductor** ranks it into a board, and **consolidation** proposes which of your repeated lessons should become permanent rules.
6. Morning: you open a short list of opportunities instead of a firehose of news. No file-hunting, no re-explaining, and nothing about your field got past you.

## Credits

This stack is built on the work of others. The Stratos Memory Stack just opinionates a path through them.

- [claude-mem](https://github.com/thedotmack/claude-mem) by Alex Newman ([@thedotmack](https://github.com/thedotmack))
- [basic-memory](https://github.com/basicmachines-co/basic-memory) by [Basic Machines](https://basicmemory.com)
- [Obsidian](https://obsidian.md) by Dynalist Inc.
- [Pinecone](https://www.pinecone.io)
- The Karpathy LLM Wiki pattern (`knowledge/raw/` + `knowledge/wiki/`)
- The unified retrieval layer adapts Cerebras Engineering's "How We Built Our Knowledge Base" (2026), with [pgvector](https://github.com/pgvector/pgvector), [fastembed](https://github.com/qdrant/fastembed), reciprocal rank fusion (Cormack, Clarke, Buttcher, SIGIR 2009), Anthropic's Contextual Retrieval, and [CocoIndex](https://github.com/cocoindex-io/cocoindex) for the code path.

The learning loop draws on the self-improving-agent patterns documented across the field in 2025-26: auto-logging capture, Reflexion-style post-mortems, recurrence-gated promotion, and silent-unless-changed scheduled watchers.

## Share this

If you found this useful, send it to someone else who uses Claude Code. Keep the title "Stratos Memory Stack" so they can find updates.

Compiled by **Stratos House AI** (Arshia Navabi). MIT licensed. Free forever.

If you build on top of this stack and ship something cool, I want to hear about it. Find me at [stratosagency.ai](https://www.stratosagency.ai) or open an issue here.

---

<div align="center">
  <sub>
    <a href="https://www.stratosagency.ai">stratosagency.ai</a>
    &nbsp;·&nbsp;
    <a href="https://github.com/ArshiaEcho/stratos-memory-stack">repo</a>
    &nbsp;·&nbsp;
    <a href="https://github.com/ArshiaEcho/stratos-memory-stack/issues">issues</a>
  </sub>
</div>
