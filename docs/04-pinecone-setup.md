# 04. Pinecone Setup (Optional)

Pinecone is a cloud vector database. You ingest big reference docs (playbooks, transcripts, long PDFs) once, then Claude can semantically query them at flat cost instead of re-reading the full file every time.

**Skip this layer if you don't have raw archives worth indexing.** It's the most complex layer to set up and the easiest to skip when starting out.

## Links

- Site: https://www.pinecone.io
- Docs: https://docs.pinecone.io
- Pricing: https://www.pinecone.io/pricing

## When to add Pinecone

Good fit:
- You have long PDFs, transcripts, or playbooks you reference often
- You want Claude to quote exact passages without re-reading huge files
- You have a `knowledge/raw/` folder with content that almost never changes

Bad fit:
- You're starting from scratch with no archive
- All your knowledge lives in editable notes (use basic-memory instead)
- You're cost-sensitive (Pinecone free tier is generous but not infinite)

## Prerequisites

- Python 3.10+
- OpenAI API key (for embeddings)
- Pinecone account (free tier works)

## Install dependencies

```bash
pip install pinecone-client openai python-dotenv
```

## Get API keys

1. Sign up at https://app.pinecone.io
2. Create a new project
3. Copy your API key from the dashboard
4. Sign up at https://platform.openai.com if you don't have an OpenAI key
5. Create an OpenAI API key

## Create the index

In the Pinecone console:

- Click "Create Index"
- Name: anything you like, for example `my-vault`
- Dimension: `1536` (matches `text-embedding-3-small`)
- Metric: `cosine`
- Cloud / region: pick the closest one (free tier defaults are fine)

## Drop in the scripts

Copy `pinecone_ingest.py`, `pinecone_query.py`, and `.env.example` from the `templates/` folder of this plugin into your vault. Recommended location: `your-vault/knowledge/`.

```bash
cp templates/pinecone_ingest.py your-vault/knowledge/
cp templates/pinecone_query.py your-vault/knowledge/
cp templates/.env.example your-vault/knowledge/.env
```

## Configure

Edit `your-vault/knowledge/.env`:

```
PINECONE_API_KEY=your_actual_pinecone_key
OPENAI_API_KEY=your_actual_openai_key
```

**Make sure `knowledge/.env` is in your `.gitignore`.** Never commit it.

Edit `pinecone_ingest.py` and `pinecone_query.py`, change `INDEX_NAME` at the top to match the index name you created.

## Ingest your first document

```bash
cd your-vault/knowledge
python3 pinecone_ingest.py raw/some-playbook.md
```

Output should show "Ingested some-playbook.md: N chunks". Each chunk becomes a vector in Pinecone.

To ingest a whole folder:

```bash
python3 pinecone_ingest.py raw/
```

## Query

```bash
python3 pinecone_query.py "what does the playbook say about pricing?" --top-k 3
```

Output: top 3 matching chunks with source path and similarity score.

## Wire it into Claude Code

Two ways:

**Option A (simple):** add a note to your `CLAUDE.md` telling Claude to call the script when needed:

> Use Pinecone for raw recall, not full file reads.
> Query with: `python3 knowledge/pinecone_query.py "question" --top-k 3`

Claude will run it via Bash when relevant.

**Option B (advanced):** wrap the scripts in a custom MCP server. Out of scope for this doc, but the Anthropic MCP quickstart covers it.

## Cost

For a 100-doc archive at ~5k tokens each:
- One-time ingest: ~$0.50 (OpenAI embeddings)
- Storage: free tier on Pinecone (100k vectors)
- Per query: ~$0.0001 (embed) + free (Pinecone query)

Essentially free at personal scale.

## Verify

```bash
ls your-vault/knowledge/pinecone_*.py
cat your-vault/knowledge/.env | grep -v "^#" | grep "_KEY="
python3 your-vault/knowledge/pinecone_query.py "test query" --top-k 1
```

Last command should print a top match. If it errors, check API keys and index name.
