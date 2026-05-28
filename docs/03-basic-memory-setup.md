# 03. basic-memory Setup

basic-memory is an MCP server that gives Claude semantic search over your entire Obsidian vault. Hybrid BM25 + vector retrieval. You ask "find notes about X" and Claude calls `mcp__basic-memory__search` to find them by meaning, not just keyword.

Built by [@basicmachines-co](https://github.com/basicmachines-co). 3k+ stars on GitHub.

## Links

- Site: https://basicmemory.com
- GitHub: https://github.com/basicmachines-co/basic-memory
- Docs: https://docs.basicmemory.com

## Prerequisites

- Python 3.10+
- Obsidian vault (from doc 01)
- Claude Code installed

## Install

Recommended via `pipx` so it lives in its own isolated environment:

```bash
pipx install basic-memory
```

Or with plain pip:

```bash
pip install basic-memory
```

Verify the install:

```bash
basic-memory --version
which basic-memory
```

## Point it at your vault

```bash
basic-memory project add my-vault /path/to/your/obsidian/vault
basic-memory project default my-vault
basic-memory sync
```

The first sync indexes every `.md` file. Could take a few minutes on a large vault. Subsequent syncs are incremental and run automatically when files change.

## Wire it into Claude Code

Add basic-memory as an MCP server. Open `~/.claude.json` (global) or `./.mcp.json` (per-project) and add:

```json
{
  "mcpServers": {
    "basic-memory": {
      "command": "basic-memory",
      "args": ["mcp"]
    }
  }
}
```

Restart Claude Code. The basic-memory tools should now appear with names like:

- `mcp__basic-memory__search`
- `mcp__basic-memory__build_context`
- `mcp__basic-memory__recent_activity`
- `mcp__basic-memory__read_note`
- `mcp__basic-memory__write_note`

## Verify

In a new Claude Code session, ask:

> "Use basic-memory to search my vault for 'memory stack'."

Claude should call the search tool and return matching notes from your vault. If no results, the index might be empty or pointed at the wrong folder. Re-run `basic-memory sync` and check `basic-memory project list`.

## What to use it for

- **"Where is that note about X?"** Claude finds it by meaning.
- **"Pull together everything I've written about client Y."** `build_context` aggregates related notes.
- **"What have I been working on this week?"** `recent_activity` lists recently modified notes.
- **"Update the wiki page on Z with these new findings."** Claude reads, edits, writes back.

basic-memory makes your vault feel queryable. Without it, Claude can only see files you explicitly point at.

## Why both basic-memory AND Pinecone?

basic-memory indexes living notes you're actively editing. Pinecone (layer 4) indexes frozen archives you only read. Different jobs. basic-memory has to handle constant re-indexing. Pinecone optimizes for "ingest once, query forever."

If you only ever write your own notes (no big external archives), you can skip Pinecone entirely.
