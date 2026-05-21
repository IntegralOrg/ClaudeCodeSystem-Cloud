---
name: graph-sync
description: Full vault knowledge graph rebuild for initial setup, periodic deep sweeps, or after major restructuring.
---

# Graph Sync -- Full Vault Knowledge Graph Rebuild

Run this for a complete re-index of the vault's knowledge graph. Use for initial setup, periodic deep sweeps, or after major vault restructuring.

**Runtime:** 10-20 minutes depending on vault size.
**When to use:** First time setup, monthly deep sweep, after reorganizing folders.

---

## How the Graph Works

The knowledge graph has four layers:

1. **Frontmatter** -- YAML metadata at the top of every markdown file (type, tags, associations)
2. **Wiki-links** -- Inline `[[Path|Display Name]]` connections between files
3. **Entity registry** -- Master lookup table mapping terms to link targets (`Graph/entity-registry.md`)
4. **Maps of Content (MOCs)** -- Curated navigation pages by topic (`Graph/` folder)

These layers make the vault navigable as a connected network, not just a folder tree.

---

## Phase 1: Frontmatter Audit

Process every markdown file in the vault (exclude `.claude/`, `Graph/`, `Templates/`, `.obsidian/`).

For each file:
1. Check if frontmatter exists (file starts with `---`)
2. If missing, add it. If incomplete, add missing fields without overwriting existing values.

**Type classification** -- derive from file location:
- Files in `Work/Clients/*/` or `[CompanyName]/` with "Profile" in the name -> `type: client-profile`
- Files in `**/Transcripts/` -> `type: transcript`
- Files in `Resources/People/` -> `type: person`
- Files in `Resources/Reference/` or `Resources/Concepts/` -> `type: reference`
- Files in `[CompanyName]/SOPs/` -> `type: sop`
- Files in `Projects/` -> `type: project`
- Files in `Inbox/` -> `type: inbox`
- Files in `Work/Daily/` -> `type: daily-note`
- Files in `Archive/` -> `type: archive`
- Everything else -> `type: reference`

**Read CLAUDE.md** to determine the user's company name and client list. Use these to assign `client:` fields:
- Files under `Work/Clients/<ClientName>/` get `client: <ClientName>`
- Files under `[CompanyName]/` get `client: [CompanyName]`

**Tags** -- generate 2-5 tags per file based on content. Use a controlled vocabulary appropriate to the vault's domain. Common tags: `automation`, `strategy`, `operations`, `sales`, `marketing`, `hiring`, `design`, `development`, `reporting`, `security`, `integration`.

**Frontmatter format:**
```yaml
---
type: client-profile
client: ClientName
tags: [strategy, operations, reporting]
---
```

Report: `Frontmatter audit: N files processed, N updated, N already complete`

---

## Phase 2: Entity Registry

Read `Graph/entity-registry.md`. If it does not exist, create it.

**Build or update the registry** by scanning the vault for entity pages -- files that represent a distinct person, company, concept, or process:

| Category | Where to find them |
|----------|--------------------|
| Clients | `Work/Clients/*/Company Profile.md` |
| People | `Resources/People/*.md` |
| Concepts | `Resources/Concepts/*.md` (create this folder if it does not exist) |
| SOPs | `[CompanyName]/SOPs/*.md` |
| Projects | Any file with `type: project` in frontmatter |

For each entity, add a row to the registry table:

```markdown
| Term | Page | Aliases |
|------|------|---------|
| ClientName | Work/Clients/ClientName/Company Profile | alternate names, abbreviations |
| Person Name | Resources/People/Person Name | first name, nickname |
| Concept | Resources/Concepts/Concept | related terms |
```

**Aliases** are alternative terms that should resolve to the same target. For example, a person named "Robert Smith" might have aliases "Rob", "Bob Smith".

**Do not create duplicate entries.** If a term already exists, update its aliases if needed.

Report: `Entity registry: N entries (N clients, N people, N concepts, N SOPs)`

---

## Phase 3: Wiki-Link Pass

Process every markdown file to add inline wiki-links.

For each file:
1. Read the entity registry
2. Scan file content (skip YAML frontmatter, code blocks, and existing `[[links]]`)
3. For each entity term found (case-insensitive match):
   - Replace the **first occurrence only** with `[[Page Path|Display Term]]`
   - Use the alias that best matches the original text for natural reading
   - Skip if the file IS the target page (no self-links)
   - Skip if the term appears in the page's title heading
4. If the file has connections to other pages not captured by inline mentions, add a `## Related` section at the bottom:
   ```markdown
   ## Related
   - [[Path/To/Page|Name]] -- brief description of the relationship
   ```

Report: `Wiki-link pass: N files processed, N links added, N Related sections added`

---

## Phase 4: Index and MOC Generation

Build or rebuild the navigation files in `Graph/`.

### index.md
Master alphabetical directory of all vault pages.

- Glob all markdown files
- Exclude: transcripts, daily notes, archived items, Graph/ files, .claude/ files, templates
- Sort alphabetically by display name
- Group by first letter (A-Z)
- Format: `- [[Full/Path|Display Name]] -- one-line description`
- Add timestamp: `*Last updated: YYYY-MM-DD*`

### MOC Files
Create or update Maps of Content based on what exists in the vault. Read CLAUDE.md for client tiers, team info, and project structure.

**Clients.md** -- Group clients by priority tier (if tiers are defined in CLAUDE.md) or alphabetically. Per client: profile link, key contacts, active projects, tech stack notes.

**People.md** -- Group by organization (user's company team, then by client). Per person: name link, role/title.

**Projects.md** -- Group by client or category. Per project: name link, one-line description, status if known.

**Concepts.md** -- Group by theme. Per concept: description, which clients or projects use it.

**SOPs.md** -- Group by category (delivery, sales, hiring, internal). Per SOP: name link, one-line description.

Only create MOCs that have content. If there are no SOPs, do not create SOPs.md. If there are no concept pages, do not create Concepts.md.

Report: `Index/MOC rebuild: N index entries, N clients, N people, N projects, N concepts, N SOPs`

---

## Phase 5: Orphan Report and Stats

### Orphan Detection
Find files with zero wiki-link connections (no inbound or outbound links):
1. Build link graph from all wiki-links across the vault
2. Files with zero inbound AND zero outbound links are orphans
3. Exclude: templates, Graph/ files, .claude/ files

Present the orphan list grouped by folder. Do not auto-action them. Let the user decide.

### Stats Summary
Report overall graph health:
- Total markdown files in vault
- Files with complete frontmatter
- Total wiki-links across all files
- Average links per file
- Top 10 most connected nodes
- Total entries in index and MOCs

**Final output:**
```
Graph Sync Complete -- YYYY-MM-DD
  Frontmatter: N/N files complete
  Wiki-links: N total across N files
  Index entries: N
  MOCs: [list which were created/updated]
  Orphans: N
  Duration: Xm
```
