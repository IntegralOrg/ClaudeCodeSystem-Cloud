---
name: monthly-review
description: Full monthly system review: collect feedback, clean vault, scan testimonials, apply improvements.
---

# Monthly Review

Runs a full system review: collects user feedback, cleans the vault, scans for testimonials, applies improvements, and updates the review date. Run this on the last workday of each month.

**Critical rule: Atomic writes.** The vault lives on iCloud. Background sync WILL modify files between reads and writes.
- **ALWAYS use Python atomic writes** (read -> modify -> write in a single `python3` script via Bash) when editing existing files.
- The Write tool is acceptable for NEW files since there's no read-modify-write race.

---

## Step 1: System Feedback

1. Use AskUserQuestion to collect feedback on each of the following (one question at a time):
   - What's working well in the current system?
   - What feels clunky or takes too many steps?
   - Any tools or integrations you wish you had?
   - Any behavior changes you'd like from the assistant?
2. Summarize responses and save to `/tmp/monthly-review-feedback-TODAY.md`

---

## Step 2: CLAUDE.md Self-Audit

Read CLAUDE.md in full. Audit it against the actual state of the vault and connected tools. Check each of the following and collect every discrepancy into a findings list before presenting anything to the user.

### 2a: Integrations

For each integration listed under "Direct Connections" and "Tools That Need Login Credentials":
1. If it is an MCP server (task manager, calendar, etc.), attempt a lightweight call (e.g., list workspaces, list events) to confirm the connection is live.
2. If it is a REST/GraphQL API, source `.env` and verify the credential variable exists and is not a placeholder value (e.g., still says `your_...`).
3. Flag: integrations listed in CLAUDE.md but not actually connected, and integrations that are connected but missing from CLAUDE.md.

### 2b: Local Tools and Scripts

For each script listed under "Local Tools":
1. Check that the script file exists at the listed path (e.g., `scripts/fathom-fetch.py`).
2. Check that the script is executable or at least parseable (`python3 -c "import ast; ast.parse(open('path').read())"` for Python).
3. Flag: scripts listed but missing from disk, scripts on disk in `scripts/` but not documented in CLAUDE.md.

### 2c: Folder Structure

1. Read the "Folder Structure" section of CLAUDE.md.
2. Run `ls` on the vault root and compare top-level folders against what CLAUDE.md documents.
3. Check one level deeper for each documented subfolder (e.g., does `Work/Clients/` exist and have client subfolders?).
4. Flag: folders listed but not on disk, folders on disk but not documented.

### 2d: Skills

1. List all `.md` files in `.claude/commands/`.
2. Compare against any skills referenced in CLAUDE.md (under Common Workflows, EOD Pipeline, etc.).
3. Flag: skills referenced in CLAUDE.md but missing from disk, skills on disk but not mentioned in CLAUDE.md.

### 2e: File Size Check

1. Count the characters in CLAUDE.md (use `wc -c`).
2. If over 25,000 characters, flag it as approaching the 30K limit and identify the largest sections that could be extracted to reference files.
3. If over 30,000 characters, flag it as urgent -- the file is too long and Claude may not read it reliably.

### 2f: Present Findings

Present all findings in a single summary grouped by category. For each issue, include what CLAUDE.md says vs. what reality shows.

Use AskUserQuestion: "Here is what I found. Which issues should I fix?"
Options:
- Fix all of them
- Let me pick which ones to fix
- Skip this, move on to vault cleanup

Apply approved fixes via atomic writes. For missing scripts or integrations, update CLAUDE.md to remove or comment out the stale entries. For missing documentation of real tools, add entries.

---

## Step 3: Vault Cleanup

1. Scan `Inbox/` for items older than 14 days -- these are stuck and need triage or archival
2. Check for notes filed in wrong folders (e.g., client content in `Inbox/[YourCompany].md` instead of the correct client file)
3. Flag files with outdated information (references to past dates, completed projects still marked active)
4. Identify empty or unused files (no content beyond template headers)
5. Present findings to the user; apply approved changes via atomic writes

---

## Step 4: Testimonial Scan

1. Read `CLAUDE.md` or `Resources/Reference/System Improvements.md` to find the last testimonial scan date
2. Search Slack (all workspaces) for positive client feedback since that date:
   - Keywords: "thank", "great job", "love", "amazing", "impressed", "saved", "clutch", "game changer"
   - Filter to DMs and client channels only
3. Search vault transcript files for positive client feedback in call recordings
4. Present all findings to the user with source and context
5. For each approved quote, append to `[YourCompany]/Testimonials.md` via atomic write with:
   - The quote text
   - Client name (or anonymized label if preferred)
   - Date and source (Slack/call)

---

## Step 5: Apply Updates

1. Route system improvements (tool ideas, automation suggestions) to `Resources/Reference/System Improvements.md`
2. Route workflow changes (new processes, updated procedures) to `CLAUDE.md`
3. Route preference updates (tone, behavior, formatting) to Assistant Guidelines section of `CLAUDE.md`
4. All edits via atomic writes; present a summary of what changed and where

---

## Step 6: Update Review Date

1. Update the "Last Monthly Review" date in `CLAUDE.md` to today's date via atomic write
2. Print a final summary: feedback items logged, vault issues found/fixed, testimonials added, improvements routed
