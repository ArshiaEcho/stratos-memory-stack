# The Contract-First Delivery Gate

A memory stack that remembers everything can still fail you in the one place it hurts most: client work. This doc covers a failure mode we hit in production, why a memory system makes it worse rather than better by default, and the pattern that fixes it. Learned the hard way, on a real engagement that nearly lost the client.

## The failure mode: self-referential verification

An agent doing delivery work builds something, then verifies it. The trap is *what* it verifies against. Left alone, the agent checks its own output: does the thing I built render, do my pages return 200, do my tests pass. Every check can come back green while the customer keeps being right that the work is wrong, because nothing in the loop ever compared the deliverable to what the customer actually asked for.

A capture-and-recall memory stack amplifies this. The agent's session summaries, state files, and observations are all records of *what the agent did*. When the next session loads that context, it inherits the agent's framing of the work, not the customer's. Summaries drift. "Ported the homepage" quietly becomes "shipped the redesign." Three sessions later the memory system is confidently wrong about what was promised, and every new session verifies against the drifted record.

Concrete ways this bit us in one engagement:

- A layout bug that only appeared on screens wider than the dev viewport shipped and stayed live for days. Every verification pass ran at the developer's own screen sizes. The client saw a broken site on a 27 inch monitor the whole time.
- A "full site verification" checked that every URL in the sitemap returned 200. It never extracted and checked the links *on* the pages, so the homepage shipped with a dozen dead links while the audit read clean.
- The client asked for a specific interaction in writing (a popup form). A later rebuild silently downgraded it to a simpler mechanism. No check caught it, because the check list was derived from the build, not from the client's email.
- Partial work was repeatedly described as complete: one rebuilt page type became "the design is updated." Each gap the client then found converted a small miss into a broken promise.

One root cause, four costumes: **the spec lived in the customer's messages, and the customer's messages were never a first-class memory object.**

## The fix: make the contract a memory artifact

Three changes, mapped to the layers of this stack.

### 1. Ingest the contract itself, not your summary of it

For every engagement, keep a **contract audit note** in the project folder (template: [`templates/CONTRACT-AUDIT.md.template`](../templates/CONTRACT-AUDIT.md.template)). It quotes the customer's requests item by item from their source messages (emails, texts, call notes), each with a status and how it was verified. Two rules make it work:

- Build it by re-reading the source messages verbatim at audit time. Never build it from prior session summaries; summaries are exactly the thing that drifts.
- Every "done" claim on the engagement re-walks this note, item by item, before the word "done" is used.

This is the same principle as the stack's `knowledge/raw/` convention: sources are immutable, and the compiled layer must cite them. Customer messages are raw sources. Treat them that way.

### 2. Put the delivery gate at three altitudes

A rule that lives in one place dies. A session that never searches memory misses the deep rule; a project resumed from a state file misses the global rule; an always-loaded rule with no context gets rationalized away under pressure. Encode the gate at all three altitudes:

- **Always-loaded (`CLAUDE.md`):** a compact version of the gate loads into every session, every project, unconditionally. See the `## Client work: contract-first delivery gate` section in [`templates/CLAUDE.md.template`](../templates/CLAUDE.md.template).
- **Deep rule with scar tissue (memory folder):** the full rule, including the story of the failure that created it, lives as a searchable memory file. The context is not decoration. Rules with a remembered cost get followed; naked rules get argued with.
- **Per-project state (`STATE.md`):** the project's own state file names the gate requirements (the audit note, the verification envelope) in its next-action block, so resuming the project surfaces them even if everything else is skipped.

### 3. Verify on the customer's envelope, against behavior

The gate itself, condensed. These are the lines we now load into every session:

1. The customer's source messages are the spec. Audit item by item against them before any "done".
2. Test on the customer's envelope, not yours: for anything visual, a viewport matrix that brackets real hardware (390 / 768 / 1440 / 1920 / 2560 minimum). Same idea for browsers, devices, data sizes.
3. Verify behavior, not existence: crawl the links pages actually contain, exercise the real flows (checkout, forms, popups). "The page exists" is not "the page works".
4. Never present partial work as complete. Name what is covered and what is not.
5. "Green" only describes what was actually tested, with its scope stated. Overclaiming converts small gaps into broken promises.
6. Releases: contract audit passed, envelope matrix passed, the operator's explicit go, and an immediate machine-verified re-check of the live surface after the flip.
7. When the customer reports a defect, reproduce their exact report first (their device class, their click path), fix, then re-test that same reproduction.

## Wiring it into the learning loop

The capture hook and consolidation engine (see [the learning loop](06-learning-loop.md)) are how the gate stays alive instead of becoming a document nobody reads:

- When a delivery mistake happens, the session captures it to the buffer as usual. The consolidation gate promotes recurring delivery failures into the always-loaded rule, so the gate grows from real incidents rather than speculation.
- The staleness scan applies to contract audit notes too: an engagement whose audit note has not been re-walked since the last client message is stale, and stale audits are how drift restarts.

## The one-line version

Capture-and-recall remembers what you did. Delivery work needs the system to also remember what you *promised*, in the customer's own words, and to make every "done" answer to that record instead of to itself.
