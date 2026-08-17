# Vault Audit: Daily Self-Healing Hygiene

Keeps the vault matching its own design contract (`.claude/vault-schema.md`). Fully autonomous: it fixes what it finds, stages removals into `.claude/audit-trash/` (never deletes), and never asks for approval mid-run.

**Why this exists:** vaults drift. Files land in the wrong folder, near-duplicate notes pile up, frontmatter goes missing, half-written stubs sit untouched for weeks. A monthly cleanup only catches this after months of decay have already made the vault harder to search and the agent's answers less reliable. This command catches the same drift every night, in minutes, by splitting the work two ways: a small deterministic script handles structure (walking the tree, hashing files, staging removals, purging old trash) and Claude handles judgment (does this file's content match its folder, do two files describe the same thing, is the schema itself wrong). Neither one is safe alone -- the script has no idea what a file means, and free-form judgment without a script drifts just as fast as the vault it's supposed to fix.

Modes:
- **Default (nightly)**: the six steps below. Run standalone anytime, or as EOD Phase 5.5.
- **`init`**: one-time bootstrap for a vault with no schema/index yet. See the Init section.

Hard rules:
- Never touch anything under a `protected` path or a non-markdown file.
- Never `rm` a vault file: removals go through the `stage` subcommand.
- Records (files under `no_merge` folders) are never merged, split, or rewritten.
- This command never runs git itself. In vaults using the EOD pipeline, `/eod` makes a pre-audit checkpoint commit right before invoking this command (see its Phase 5.5), so every change this run makes is trivially revertible. If you're running this standalone outside `/eod`, commit your own checkpoint first.

## Setup

0. If `scripts/vault-audit.py` is missing in this vault, copy it from the setup repo's `templates/scripts/` folder first: `cp REPO_PATH/templates/scripts/vault-audit.py VAULT_PATH/scripts/vault-audit.py` (locate `REPO_PATH` the same way `/onboard` does; ask the user if you can't find a local clone of the setup repo).
1. `date` for today.
2. `VAULT` = vault root (directory containing CLAUDE.md). `AUDIT="python3 \"$VAULT/scripts/vault-audit.py\""`.
3. If `.claude/vault-schema.md` is missing, stop and run Init instead.

## Step 1: Script pass

Run `scan --vault "$VAULT"` and read the JSON work order. It already purged old trash and refreshed the index (added/changed files are marked stale).

## Step 2: Deterministic fixes

Work the order. A move or rename ALWAYS requires checking inbound links via the `links` subcommand, never just when the basename changes: many vaults use path-qualified wiki-links (`[[Resources/Reference/Server Logins]]`, `[[Reference/Server Logins]]`), and any of those forms breaks when the file's path changes even if the basename stays the same. `links` matches both the bare basename and any path-qualified suffix ending at the stem, so it will surface these. Repoint any link whose target no longer resolves, fixing both the basename and the path portion of the link as needed (edit each `[[Old Path/Old Name]]` or `[[Old Name]]` to the file's new location).

- `root_clutter` and `unknown_folder`: read the file (skim is fine), pick the destination from the schema's folder purposes, `mkdir -p` if needed, `mv` it. If no folder fits, the closest general-purpose folder wins (e.g., `Resources/Reference/`); note the mismatch for Step 5.
- `exact_duplicates`: keep the copy whose folder the schema endorses (tie-break: most recently modified); `stage` the rest. When both copies sit in the SAME folder, mtime lies (the stray copy is usually newer): keep the one whose name the index or inbound links already know, falling back to git creation date. Repoint links from staged copies to the keeper.
- `empty_stubs`: read each before acting. `stage` only the genuinely contentless (template header only, no information). A tiny body that carries real information (an ID, a number, a link) is content, not a stub: keep the file and expand it minimally (frontmatter plus a one-line context sentence) so it stops flagging. The script already excludes `no_merge` records from this list (staging or expanding one would be a rewrite, and records are never rewritten), so nothing under a `no_merge` folder appears here.
- `missing_frontmatter`: add minimal frontmatter (`type` per the folder's content, `created` from the file's git or mtime date). Follow CLAUDE.md's frontmatter schema if one is documented; otherwise use `type`/`created` at minimum. The script already excludes `no_merge` records from this list (adding frontmatter is a rewrite, and records are never rewritten), so nothing under a `no_merge` folder appears here.
- `naming_violations`: rename to satisfy the pattern (derive the date from frontmatter/content), repoint links.

## Step 3: Semantic re-index

For each rel path in `stale`:
- If it falls under a `no_merge_paths` pattern: derive the row from path + filename + first 20 lines only (records are indexed for navigation, not merging).
- Otherwise read the file and write a row: `concept` = one line, `<entity>: <what this file is>`, max 120 chars; `entities` = the people/companies/projects it is about; `verdict` = `ok`, or `belongs:<folder>` when the CONTENT says it lives elsewhere even though the folder is schema-legal.

Batch the writes: build a JSON array `[{"file":..., "concept":..., "entities":[...], "verdict":"ok"}, ...]` in a scratch file and run `bulk-update --json <file>` (use `update-row` for one-offs). Then act on any `belongs:` verdicts as moves (Step 2 rules). Ordering rule whenever YOU edit a file's content: run `scan` first (so the index picks up the new hash), THEN `update-row`; the reverse order leaves a stale hash that re-flags the file next run.

## Step 4: Fragmentation sweep (full vault, every night)

Read a concepts-only projection of `.claude/vault-index.json` (path, concept, entities, verdict per row), e.g. via a python one-liner, rather than the raw JSON. Also re-examine every `watched_clusters` entry.

Find clusters: 2+ non-record files whose concepts describe the same thing about the same entity. For each cluster apply the confidence bar: same concept AND same entity AND same purpose.
- **Clear duplicate concept**: merge into the canonical home per the schema's canonical-home rules. Read every file in the cluster; the merged file must preserve EVERY unique fact from every source. `stage` the losers, repoint inbound links to the keeper, `update-row` the keeper.
- **Not sure**: `watch` the cluster and move on. A watched cluster gets fresh eyes every night; merge it only when a later night clears the bar.

## Step 5: Schema feedback

Read the last 3 run entries in `.claude/audit-log.md`, including each entry's `violations` line (written by Step 6). Group entries by their `kind:folder-or-path:destination-or-rule` tuple: if the same tuple recurs in the same direction across 3+ runs, the schema is wrong, not the vault's content: amend the YAML core (add the folder, adjust the rule) AND append one line to the schema's Amendment Changelog: `- YYYY-MM-DD: <change>. Why: <the recurring pattern>.` Never amend to bless junk (recurring genuine clutter is just fixed again), and never touch `protected` this way. After amending the schema, re-run scan to confirm it still parses before proceeding.

## Step 6: Receipt

Append to `.claude/audit-log.md`:

```
## YYYY-MM-DD
moved: <list or none>
renamed: <list or none>
merged: <keeper <- losers, or none>
staged: <list or none>
frontmatter: <count>
watched: <clusters or none>
amendments: <list or none>
violations: <kind:folder-or-path:destination-or-rule, ... or none>
```

`violations` is the identity record Step 5 compares across runs: one entry per `root_clutter`, `unknown_folder`, `naming_violations`, `empty_stubs`, or `missing_frontmatter` finding acted on this run, written as `kind:folder-or-path:destination-or-rule` -- e.g. `unknown_folder:Notes/:Resources/Reference/` for a file that landed in a folder the schema doesn't define and got routed to the closest general-purpose folder, or `missing_frontmatter:Resources/Health/:added` for a frontmatter fix. Reuse the exact same tuple wording when the same violation recurs so Step 5 can match it; do not paraphrase the folder or rule differently run to run.

Then report ONE line: `Vault audit: N moved, N merged, N staged, N amendments`. In EOD, that line is the phase status; standalone, print it plus anything surprising.

## Init (one time per vault)

1. `mkdir -p "$VAULT/.claude"` first (a fresh vault has no `.claude/` yet, and the schema, index, and trash state all live under it). Then draft `.claude/vault-schema.md` from CLAUDE.md's folder-structure block plus the real tree (`ls` root and one level down). Include `root_whitelist`, `protected`, `folders` with purposes, `naming` for dated records, `no_merge: true` for records, `frontmatter_required`.
2. **Derive `protected` by convention, do not ask for it.** Default protected paths: generated-output folders (anything a command overwrites wholesale, e.g. `Inbox/Today.md`'s parent if the vault renders it), `Archive/`, `Attachments/`, `Templates/`, `.claude/` and any other dot-folder, `.handoffs/`. This is a non-technical user's vault -- a raw "which paths should I protect" question is a technical question they can't answer well. Instead, ask **at most one** plain-language question:

   > "Are there folders I should never reorganize, like a private journal? I will still keep them tidy if you want, just never merge or rewrite them."

   Map the answer: "keep tidy but never rewrite" -> mark that folder `no_merge: true` (it's a record folder: filed and indexed, never merged or rewritten). "Never touch it at all" -> add it to `protected` (the audit skips it entirely, including filing). Everything else about the schema (root whitelist, folder purposes, naming patterns) is drafted from CLAUDE.md and the real tree without asking; a wrong guess self-corrects later through Step 5's amendment mechanism instead of an upfront interrogation.
3. Run `scan` (everything shows as added/stale). Build the first index with Step 3's procedure in batches of about 40 files per bulk-update. This is the one expensive run.
4. Run Steps 4 through 6 normally. Done: the vault is now under nightly audit; wire Phase 5.5 into `/eod` if not already present.
