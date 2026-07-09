# Graph Daily Sync -- Incremental Knowledge Graph Update

Run this at the end of the day (or as part of your EOD routine) to keep the knowledge graph current. Only processes files that changed today, so it runs in 2-5 minutes.

**When to use:** Daily, after your other EOD work is done. Can be added as a final phase of `/eod`.

---

## Phase 1: Identify Changed Files

Find files modified today:

```bash
find "$VAULT" -name "*.md" -newer /tmp/eod-graph-marker 2>/dev/null || \
find "$VAULT" -name "*.md" -mtime -1
```

Also check `git diff --name-only --diff-filter=ACM` if the vault is a git repo.

Filter out: `.claude/`, `Graph/` files (those are outputs, not inputs).

If no files changed, report "No changes today" and exit.

---

## Phase 2: Frontmatter on Changed Files

For each changed file:
1. Check if frontmatter exists and is complete (type, tags)
2. If missing or incomplete, add using the same classification rules as `/graph-sync`
3. Read CLAUDE.md for client/company context

Report: `Frontmatter: N files checked, N updated`

---

## Phase 3: Wiki-Links on Changed Files

For each changed file:
1. Read entity registry (`Graph/entity-registry.md`)
2. Scan for unlinked entity mentions
3. Add `[[wiki-links]]` on first mentions
4. Add or update `## Related` section if new connections found
5. Do not re-link entities that are already linked elsewhere in the file

Report: `Wiki-links: N links added across N files`

---

## Phase 4: Knowledge Extraction from Transcripts

Check if any changed files are transcripts (in `**/Transcripts/` or `type: transcript` frontmatter).

For each new transcript:
1. Read the transcript content
2. Extract 2-5 key takeaways: decisions made, action items assigned, important facts learned
3. Add `key_takeaways` list to the transcript's frontmatter
4. Push each takeaway to the relevant entity page (usually a client Company Profile):
   - Add to a `## Recent Activity` or `## Recent Decisions` section
   - Include source backlink
   - Newest entries at top

If no transcripts changed, skip this phase.

Report: `Transcripts: N processed, N takeaways extracted`

---

## Phase 5: Index and MOC Updates

1. Check if any **new files** were created today (not just modified)
2. For each new file that qualifies for the index (not a transcript, daily note, or archive):
   - Add an entry to `Graph/index.md` in the correct alphabetical position
   - Add to the relevant MOC file(s) based on type
3. If new entity pages were created, add them to `Graph/entity-registry.md`

Report: `Index: N new entries added`

---

## Summary

Write a brief sync report to `/tmp/eod-graph-YYYY-MM-DD.md` so the daily note can reference it.

```
Graph sync: N files processed, N links added, N takeaways extracted, N index entries added
```
