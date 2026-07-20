# Architecture

How the seven layers fit together.

## The ring model

Concentric rings of editability and recency:

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

Outer rings change slowly or never. Inner rings change every session.

## Write authority

Each layer has a different writer. This is what keeps them from fighting:

| Layer | Who writes | When |
|---|---|---|
| Pinecone | You (via ingest script) | When you add a new raw archive |
| Obsidian | You + Claude | Continuously |
| basic-memory | Auto (indexes Obsidian) | On every file change |
| claude-mem | Auto (captures session) | At session end |
| CLAUDE.md / MEMORY.md | You, hand-curated | Rarely. Days or weeks |
| STATE.md | You + Claude | Every session, per project |
| Unified retrieval (L7) | Auto (connector scripts) | On ingest runs; derived data only, fully rebuildable |

If two layers tried to be the single source of truth, they'd diverge. Splitting write authority by layer prevents that. Layer 7 never becomes a write target for humans or agents: it is a derived index over the other layers' content, and deleting it loses nothing.

## Read order

When Claude needs context, query in this order:

1. **STATE.md** for the active project. Highest signal, lowest cost.
2. **CLAUDE.md / MEMORY.md** for hard rules. Already auto-loaded, free.
3. **basic-memory** for vault-wide semantic recall. Cheap and fast.
4. **claude-mem** for past session decisions. Local SQLite, fast.
5. **Pinecone** for raw archives. Network call but cheap.
6. **Unified retrieval (Layer 7)**, when installed, for cross-corpus questions ("what did we decide about X?") that span meetings, notes, and sessions. One query, fused ranking, evidence rows with scores.
7. **Read whole files** only as a last resort.

The cost-per-token-of-signal goes up as you go down the list. Always start at the top.

## Indexing flow

```
                 ┌─────────────────────┐
                 │   Obsidian vault    │
                 │  (the source of     │
                 │      truth)         │
                 └────────┬────────────┘
                          │
            ┌─────────────┼─────────────┐
            │             │             │
            ▼             ▼             ▼
    ┌──────────────┐  ┌────────┐  ┌──────────┐
    │ basic-memory │  │CLAUDE  │  │ Pinecone │
    │   indexes    │  │ .md is │  │  ingests │
    │  every .md   │  │  read  │  │ raw/ docs│
    │   on change  │  │   on   │  │   once   │
    │              │  │ start  │  │          │
    └──────┬───────┘  └────┬───┘  └────┬─────┘
           │               │           │
           ▼               ▼           ▼
       ┌──────────────────────────────────┐
       │       Claude Code session        │
       │                                  │
       │  • Auto-loads CLAUDE.md/MEMORY   │
       │  • Auto-injects claude-mem       │
       │  • Calls basic-memory MCP        │
       │  • Calls pinecone_query.py       │
       │  • Reads STATE.md on trigger     │
       │  • Writes back to STATE.md       │
       │  • Writes back to vault          │
       └──────────────────────────────────┘
```

Obsidian is the substrate. Every other layer is a lens that watches or compresses or indexes it. Nothing duplicates state. Each layer has one job.

## Why this works

Most "AI memory" setups pick one tool and try to make it do everything. Vector DBs are bad at rules. Rules files are bad at search. Session logs are bad at archives. By splitting the problem across six purpose-fit layers, you avoid the failure mode where one tool is mediocre at all three.

The cost is setup time (about 2 hours total, spread across a week as you need each piece). The payoff is sessions that open already knowing what you were doing yesterday, queries that find notes by meaning, and zero re-explaining.

## Layer 7: the unified retrieval engine (optional)

The ring model above answers "where does each kind of memory live." Layer 7 answers a different question: "how do I search all of it at once." It is one Postgres + pgvector table that connector scripts fill from every corpus (meeting transcripts, vault notes, code, session summaries), queried through hybrid search (vector + full-text + recency) fused with reciprocal rank fusion and served as LLM-free MCP primitives.

Two properties keep it from violating the ring model:

- **It is derived data.** Sources of truth are never touched; the whole index rebuilds from scratch. Delete it and nothing is lost.
- **It is read-only at query time.** Nothing writes back through it, so it cannot diverge from the layers it indexes.

Full design, schema, and setup: [`08-unified-retrieval.md`](08-unified-retrieval.md).

## Failure modes

- **Source of truth drift.** If you let basic-memory or Pinecone become a write target, they'll diverge from Obsidian. Don't. Always write to Obsidian, let the indexers follow.
- **STATE.md staleness.** Skip the end-of-session update three times and the trigger-word pattern breaks. Build the habit.
- **CLAUDE.md sprawl.** Past 300 lines, signal drops fast. Move things to wiki/ pages and link.
- **claude-mem noise.** If session summaries fill your context window, tune what claude-mem captures. Less is more.
- **Pinecone for active notes.** Pinecone is for frozen archives. If you find yourself re-ingesting the same doc weekly, that doc belongs in basic-memory's scope (it's a living note, not an archive).
