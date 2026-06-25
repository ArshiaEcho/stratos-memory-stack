# 01. Obsidian Setup

Obsidian is the spine of the Stratos Memory Stack. Every other layer either indexes, captures, or points into your Obsidian vault. Set this up first.

## What Obsidian is

Local-first markdown editor. Your notes are plain `.md` files on disk that both you (via the Obsidian app) and Claude (via direct file reads) can edit. Free for personal use.

Site: https://obsidian.md
Download: https://obsidian.md/download

## Install

1. Download Obsidian from the site above. Available for Mac, Windows, Linux, iOS, Android.
2. Open the app.
3. Pick "Create new vault." Choose a folder location somewhere stable, for example `~/Documents/MyVault` or `~/Notes`.
4. Name the vault. The folder name becomes the vault name.
5. Open the new vault. You'll see a blank workspace.

## Vault structure

Inside your vault folder, create this skeleton. The Stratos stack depends on it.

```
your-vault/
├── inbox/           Quick captures, unsorted thoughts, raw ideas
├── projects/        Active work with clear goals and deadlines
├── areas/           Ongoing responsibilities
├── resources/       Reference material organized by topic
├── knowledge/
│   ├── raw/         Source material, Claude reads but NEVER modifies
│   └── wiki/        Claude-maintained compiled knowledge
├── _templates/      Note templates for daily notes, projects, meetings
├── _attachments/    Images, PDFs, binary files
└── CLAUDE.md        Vault rules for Claude (see doc 05)
```

You can create these in the Obsidian sidebar or by running this in your terminal:

```bash
cd your-vault
mkdir -p inbox projects areas resources knowledge/raw knowledge/wiki _templates _attachments
```

## Why each folder

- **inbox/** is a holding pen. Anything you capture in a hurry goes here, sorted later. Keeps you from naming and filing things mid-thought.
- **projects/** is for active work with a clear definition of done. Each project gets its own subfolder with a `STATE.md` (see doc 05).
- **areas/** is for ongoing responsibilities that never "finish." Things like finance, health, client relationships, your engineering practice.
- **resources/** is reference. Things you want to find again. Snippets, links, frameworks, summaries.
- **knowledge/raw/** holds source material that should never be edited. Articles, transcripts, papers, playbooks. Pinecone (layer 4) indexes this folder.
- **knowledge/wiki/** is Claude-maintained compiled knowledge built from the raw sources. Karpathy's LLM Wiki pattern.
- **_templates/** holds note templates. Daily notes, meetings, projects. Obsidian's Templater plugin makes these one-click.
- **_attachments/** is where Obsidian dumps images you paste in. Keeps your note folders clean.

## Recommended Obsidian plugins

From Settings > Community Plugins, turn on:

- **Templater** - programmable note templates. Worth it just for daily notes.
- **Dataview** - query your vault like a database. Useful for STATE.md indexes.
- **Periodic Notes** - opens today's daily note with a hotkey.
- **Git** (optional) - backs your vault up to a private GitHub repo.

## Verify

After setup, you should have:

- A folder you can `cd` into
- The 7+ subfolders above
- Obsidian opens and shows the structure in the sidebar

You're ready for doc 02.

## Why local-first matters

Cloud-only note tools (Notion, Roam, Evernote) put a network call between you and your own thinking. They also lock your data in their format. Obsidian's `.md` files are forever. Open them in any editor, ever. That's why the Stratos stack uses Obsidian as the source of truth and treats every other layer as a lens on top.
