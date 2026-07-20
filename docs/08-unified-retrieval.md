# Layer 7: The Unified Retrieval Engine

The six memory layers each answer questions well inside their own lane. But when you ask "what did we decide about X?", the answer might live in a meeting transcript, a project note, a wiki page, or a session summary, and each layer has to be queried separately, by convention, with no shared ranking. Layer 7 fixes that: one query, every corpus, one fused ranking.

The pattern is adapted from the knowledge base Cerebras built internally (published July 2026: "How We Built Our Knowledge Base"), which answers 15,000 employee questions a day. Their architecture is deliberately boring, and that is why it works. This doc genericizes it to run on a laptop for one person, at zero embedding cost.

## When NOT to build this

Anthropic's own guidance: if your whole searchable corpus is under roughly 200k tokens (about 500 pages), skip retrieval entirely. Load it into the prompt and let caching do the work. Layer 7 earns its keep when you have corpora that cannot fit: meeting transcripts, large vaults, client document sets, codebases. Build it for those, not for vanity.

## The architecture in one diagram

```
  SOURCES          one connector per source, delta-only
  meetings ─┐
  vault .md ─┼──> DISTILL (LLM, only for raw conversation) 
  code      ─┤        │
  anything  ─┘        v
              ONE EMBEDDINGS TABLE (Postgres + pgvector)
              row: source | source_id | title | document |
                   metadata | source_ts | content_hash | embedding
                      │
              RETRIEVAL: ranked lists in parallel
                vector (paraphrase) + full-text (exact tokens) + recency
                      │
              FUSION: reciprocal rank fusion, K=60
                      │
              optional RERANK (small model, 0-10) 
                      │
              CONTEXT RE-EXPANSION (neighboring chunks)
                      │
              evidence rows -> the agent synthesizes with citations
```

## The row contract is the whole integration surface

One Postgres table. Every source lands in the same shape. Anything that emits this shape is instantly queryable alongside everything else, with no special handling anywhere downstream:

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE embeddings (
  id BIGSERIAL PRIMARY KEY,
  source TEXT NOT NULL,            -- 'meeting' | 'vault_note' | your connector
  source_id TEXT NOT NULL,         -- stable id (file name, path#chunk)
  title TEXT NOT NULL DEFAULT '',
  document TEXT NOT NULL,          -- the normalized text that gets embedded
  raw_excerpt TEXT,
  metadata JSONB NOT NULL DEFAULT '{}',
  source_ts TIMESTAMPTZ,           -- when the source content happened
  content_hash TEXT NOT NULL,      -- delta-only re-ingestion
  embedding vector(384) NOT NULL,
  tsv tsvector GENERATED ALWAYS AS
    (to_tsvector('english', left(title || ' ' || document, 100000))) STORED,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (source, source_id)
);

CREATE INDEX ON embeddings USING gin (tsv);
CREATE INDEX ON embeddings USING hnsw (embedding vector_cosine_ops);
```

A connector is any script that reads its system and upserts rows in this shape. Adding a source never touches the query side.

## The seven rules that make it good

**1. Never embed raw conversation. Distill first.** Cerebras' single biggest accuracy win: an LLM extracts a normalized artifact from each conversation (for a meeting: title, date, participants, summary, decisions, action items, key facts, topics), and THAT gets embedded. Raw transcripts are noise-dominated; two artifacts with the same shape match each other. Raw text stays keyword-searchable via the tsvector column the moment it lands.

**2. Local embeddings are free and good enough.** fastembed (ONNX) runs bge-small-en-v1.5 at 384 dimensions on any laptop, no API key, no per-token cost, no rate limits. Upgrade the model later if evals say so; the table schema does not care.

**3. Delta-only, always.** Hash the source content. Skip unchanged rows on re-ingest. Cache distillation artifacts on disk keyed by content hash so a re-embed never re-spends LLM calls. Re-running the whole pipeline should cost nearly nothing when nothing changed.

**4. Hybrid retrieval, because every scorer fails somewhere.** Vector search catches paraphrase but blurs exact tokens. Full-text catches pasted error strings, names, and citations but misses synonyms. Recency breaks ties toward answers that still describe reality. Run all lists in parallel and fuse with reciprocal rank fusion:

```
score(doc) = sum over lists of  1 / (60 + rank_in_list)
```

Consensus beats any single strong vote. Then cap how many results one file can contribute (diversity), optionally rerank the top ~20 with a small model scoring 0-10, and keep the top 10.

**5. Re-expand context after ranking.** Chunking splits headings, preconditions, and caveats away from the winning chunk. After the ranking is final, pull the neighboring chunks of each winner back in so the agent quotes complete thoughts, not orphaned paragraphs.

**6. Expose primitives over MCP, not an answer machine.** Tools like `search`, `search_meetings`, `search_vault`, `get_context`, `index_stats` return raw evidence rows, LLM-free, fast, cheap. The calling agent (Claude Code or any MCP client) is the orchestrator and synthesizer. Keeping LLM calls out of the retrieval tools means any client can use them without inheriting your orchestration opinions.

**7. Fail loud or do not run at all.** An always-on ingest worker that dies silently while reporting green is worse than no worker. Cap consecutive failures and abort with a visible error. Budget-cap every LLM-touching step. We learned this the hard way when a nightly automation silently exhausted an API budget and took unrelated services down with it; the post-mortem rule is now structural.

## Distillation without an API bill

If you run Claude Code on a subscription, the `claude` CLI is an authenticated LLM you can shell out to:

```bash
claude -p --model claude-haiku-4-5 --max-turns 1 < prompt.txt
```

Distilling ~90 meeting transcripts costs zero API dollars this way, and a few minutes of wall clock with 6 parallel workers. The distillation prompt asks for strict JSON: title, date, participants, summary, decisions, action items, topics, key facts.

## What it looks like installed

- Postgres 15+ with the pgvector extension (local homebrew Postgres is fine; compile pgvector against your major version if the bottle does not match).
- A small Python package with: `db.py` (schema + upsert + delta hashing), `embed.py` (fastembed), `distill.py` (claude CLI), one `ingest_<source>.py` per connector, `search.py` (hybrid + RRF + rerank + expansion), `mcp_server.py` (FastMCP primitives).
- Registered once: `claude mcp add --scope user knowledge -- uv run --directory ~/path/to/repo sk-mcp`.
- Re-ingest on demand or on a schedule; delta-only makes both cheap.

## Audit checks for this layer

```bash
# pgvector present?
psql -d your_knowledge_db -tc "SELECT extversion FROM pg_extension WHERE extname='vector'" 2>/dev/null

# index populated?
psql -d your_knowledge_db -tc "SELECT source, count(*) FROM embeddings GROUP BY source" 2>/dev/null

# MCP tools visible? look for your knowledge server in:
claude mcp list 2>/dev/null | grep -i knowledge
```

`INSTALLED` if the table has rows and the MCP server is registered. `PARTIAL` if the database exists but the MCP server is not wired. `MISSING` otherwise. Flag as optional-advanced: this layer only makes sense once layers 1-6 are in place and a corpus has outgrown the prompt window.

## Scale-up path

- **Code repositories:** use CocoIndex (Apache-2.0) instead of hand-rolled chunking. AST-aware splitting, incremental per-commit re-embedding, sync state in the same Postgres.
- **Contextual chunks:** prepend a chunk-specific context line before embedding (Anthropic's Contextual Retrieval: 49% fewer retrieval failures combined with lexical fusion, 67% with reranking).
- **Scoped projects:** when the corpus grows past one person, add a projects table that bundles sources per team or engagement, and scope every query to the active project by default.
- **Evals before tuning:** build a 30-50 question gold set from real usage with known correct sources. Retrieval changes are only improvements if the gold set says so.

## Credits

- Cerebras Engineering, "How We Built Our Knowledge Base" (July 2026), the architecture this layer adapts.
- Cormack, Clarke, Buttcher, "Reciprocal Rank Fusion" (SIGIR 2009).
- Anthropic, "Introducing Contextual Retrieval" (2024) and "Code Execution with MCP" (2025).
- Cursor, "Improving Agent with Semantic Search" (2025), the evidence that hybrid beats grep-only.
- CocoIndex (cocoindex-io/cocoindex), the incremental indexing engine for the code path.
