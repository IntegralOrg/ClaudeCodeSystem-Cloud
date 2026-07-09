---
name: eod-gather
description: EOD Phase 1: Data gathering. Triage brain dump, fetch transcripts, calendar, email, and Slack.
---

# EOD Phase 1: Gather

Data gathering phase. Triages Brain Dump first, then fetches Fathom transcripts, tomorrow's calendar, email, and Slack. Routes all items to inbox files immediately. Creates the manifest.

**This phase runs independently and writes all state to disk.** Later phases read from the manifest and inbox files, not from conversation context.

**Critical rule: Route-as-you-go.** Every item extracted MUST be routed to the correct client file AND logged to the manifest IMMEDIATELY.

**The vault is a Git repository in your cloud workspace.** There is no background file sync, so the built-in editor is safe for reads and writes -- when editing an Inbox file, read it, modify it, and write it back with the Edit or Write tool. The Write tool is fine for new files (transcripts, manifest).

**Critical rule: Tasks are flat bullets.** Do NOT create `### New from <source>` subsection headers for tasks. Append new tasks directly under `## Open Tasks` as flat bullets. Source context lives in the italic suffix at the end of each task (e.g., `*from Fathom: [Call Name] MM/DD*`). This keeps client files scannable as history accumulates. (`### Notes from <source>` headers under `## Notes` are still fine -- meeting notes benefit from source grouping, tasks do not.)

**Critical rule: EOD deduplication.** Before adding a task from a call recap, check if the same task already exists in the client file. If it does, update the source note (append "*also discussed X/X*") instead of creating a duplicate.

**Critical rule: EOD task ownership.** Team member actions become follow-up items for you (e.g., "Follow up: [Team Member] to deliver X"). Never frame other people's responsibilities as your direct tasks.

---

## Setup

1. Run `date` to get today's date and current time ([Your Timezone])
2. Source the `.env` file at the vault root to load API credentials
3. Set `TODAY` as the current date in `YYYY-MM-DD` format and `TOMORROW` as the next calendar day
4. **Create the manifest file** at `/tmp/eod-manifest-TODAY.md`:
   ```markdown
   # EOD Manifest -- YYYY-MM-DD

   ## Items

   | # | Item | Client | Type | Source | Routed To | Status |
   |---|------|--------|------|--------|-----------|--------|
   ```

### Manifest Column Definitions
- **#**: Sequential number (1, 2, 3...)
- **Item**: Brief description of the action item
- **Client**: Client name ([Client A], [Client B], etc.) or "Cross-Client"
- **Type**: `action-owner`, `action-other`, `research`, `decision`, `followup`, `email-response`, `note`
- **Source**: Where it came from (e.g., "Fathom: [Contact Name] call", "Email: from jack@...", "Slack: [Client A] DM")
- **Routed To**: File path where item was written (e.g., `Inbox/[Client A].md`)
- **Status**: checkmark once routed, `ORPHAN` if couldn't determine destination

---

## Section 0: Brain Dump Triage

Process the Brain Dump section in `Inbox/Today.md`. This is the user's quick-capture area throughout the day. Classify each item, route client-specific items to the correct client file, and clean up the Brain Dump.

1. **Read** `Inbox/Today.md` and extract the Brain Dump section (everything between `## Brain Dump` and the next `##` header).

2. **Parse each item** (bullets and sub-bullets). Skip items that are:
   - Already completed: `- [x]`
   - Already routed: contains `~~` strikethrough + "moved to"
   - Empty lines or section headers (`###`)

3. **Classify each remaining item** by client using these signals (in priority order):
   - **Explicit client name**: "[Client A]", "[Client B]", "[Client C]", "[Client D]", "[Client E]"
   - **Contact names**: Map each contact to their client. Example:
     - [Contact 1]/[Contact 2] = [Client A]
     - [Contact 3]/[Contact 4] = [Client B]
     - [Contact 5]/[Contact 6] = [Client C]
   - **Tool/product names**: Map tools to clients. Example:
     - Klaviyo/SamCart = [Client B]
     - Shopify = [Client A]
   - **Internal context** (hiring, team, SOPs, strategy): route to `Inbox/[YourCompany].md` Open Tasks
   - **Personal items** (health, travel, errands): leave in Brain Dump, do not route
   - **Ideas**: leave in Brain Dump, do not route
   - **Unclassifiable work items**: leave in Brain Dump, log as `ORPHAN` in manifest

4. **For Notes subsections** (e.g., `### Notes from Agency Check-in 3/16`):
   - If the notes contain items for a specific client, extract those bullets and route to that client's `## Notes` section
   - If the notes are cross-client (agency strategy, hiring, general), route to `Inbox/[YourCompany].md` Notes section
   - Meeting notes with mixed clients: split by client, route each subset to the correct file
   - Always route as plain bullets (NOT checkboxes) under a `### Notes from <source>` header in the client file

5. **Route the items** (read each file, modify it, write it back):
   a. For each client file that needs items added:
      - Read the file
      - Tasks (`- [ ]` items): append directly under `## Open Tasks` as flat bullets. Preserve source via the inline italic suffix `*from Brain Dump MM/DD*`. Do NOT create a `### New from Brain Dump MM/DD` subsection header.
      - Notes (plain bullets): insert under `## Notes` section, under a `### Notes from <source>` header
      - Dedup check: if the same task already exists in the client file, skip it (don't duplicate)
      - Write the file back
   b. Mark routed items in `Today.md` Brain Dump:
      - Tasks: change to `- [x] ~~<original text>~~ moved to <Client>.md ✅ TODAY`
      - Notes: remove from Brain Dump entirely (they now live in the client file's Notes section)
      - Personal items and ideas: leave in place (they don't route — they carry forward to tomorrow)
   c. Append a manifest row for each routed item with Source = "Brain Dump"

6. **Summary**: Print count of items routed per client, items left in Brain Dump, orphans.

---

## Section 1: Fathom Call Transcripts

1. Run the deterministic Fathom fetch script:
   ```bash
   python3 scripts/fathom-fetch.py --date $TODAY --env .env --json-file /tmp/fathom-report-$TODAY.json 2>/tmp/fathom-fetch-$TODAY.log
   FATHOM_EXIT=$?
   ```
2. Check the exit code and stderr log:
   - Exit 0: all calls processed OK
   - Exit 1: fatal error (API failure, missing env). Read the log for details. Alert the user.
   - Exit 2: partial success. Some calls failed. Continue with what succeeded.

3. Parse the JSON report from `/tmp/fathom-report-$TODAY.json`.

4. For each item in the report:
   - If status is `ok` or `summary_only`: read the written transcript file and extract:
     - **Action items** for you (with deadlines if mentioned)
     - **Action items for others** (framed as follow-ups)
     - **Research items**
     - **Decisions made**
     - **Follow-ups needed**
   - If status is `summary_only`: flag low confidence on extracted items
   - If status is `no_content`: flag the call in the manifest
   - If status is `already_exists`: still read it and extract action items if this is the first EOD run for the day.

   **Task vs. Note distinction**: Only create `- [ ]` items for clear, specific next actions. Meeting recaps without action items, status updates, and finalized decisions are Type `note` (not tasks).

5. **ROUTE IMMEDIATELY** (edit the Inbox files directly):
   a. Determine the client from the JSON report's `client` field (already classified by the script)
   b. Tasks -> `Inbox/<Client>.md` under `Open Tasks`; cross-client/agency/hiring/internal -> `Inbox/[YourCompany].md` under `Open Tasks`
   c. Notes/decisions -> `## Notes` section (plain bullets, NOT checkboxes)
   d. Append a row to the manifest for each item
   e. If client is null in the report, route to `Inbox/[YourCompany].md` and mark `ORPHAN`
6. Confirm manifest item count matches extraction count

---

## Section 2: Tomorrow's Calendar

1. Get a Google OAuth access token using the refresh token flow
2. Fetch tomorrow's events:
   ```
   curl -s "https://www.googleapis.com/calendar/v3/calendars/primary/events?timeMin=TOMORROWT00:00:00-05:00&timeMax=TOMORROWT23:59:59-05:00&singleEvents=true&orderBy=startTime" -H "Authorization: Bearer $ACCESS_TOKEN"
   ```
3. Format as readable list with times (your timezone), titles, attendees
4. Flag early meetings (before 9 AM) and back-to-backs
5. Write formatted schedule to `/tmp/eod-calendar-TODAY.md` for later phases

---

## Section 3: Email Check

1. Reuse Google OAuth access token
2. Fetch today's emails:
   ```
   curl -s "https://gmail.googleapis.com/gmail/v1/users/me/messages?q=newer_than:1d" -H "Authorization: Bearer $ACCESS_TOKEN"
   ```
3. Get headers (From, To, Subject, Date) and body preview for first 15-20 messages
4. Surface emails requiring response, client/team emails, time-sensitive items

   **Task vs. Note distinction**: Only create tasks for emails needing a specific action. Fathom recaps, calendar acceptances, FYI emails, auto-notifications are NOT tasks.

5. **ROUTE IMMEDIATELY**:
   a. Tasks -> client file `Open Tasks`; Notes -> `## Notes` section
   b. Append manifest rows

---

## Section 4: Slack Check

For each workspace (customize with your workspace names):
1. Check unread DMs and mentions using `SLACK_TOKEN_<WORKSPACE>`
2. Use `conversations.list` (types=im,mpim) then `conversations.history` with `unreads=true`
3. Surface unread DMs, mentions, time-sensitive items
4. Skip channels with no unread activity
5. **ROUTE IMMEDIATELY**:
   a. Append items to client file `Open Tasks`
   b. Append manifest rows

---

## Phase 1 Complete

After all sections finish:
1. Read back the manifest and print a summary: total items extracted, routed, orphaned
2. Print the calendar preview for tomorrow
3. The manifest at `/tmp/eod-manifest-TODAY.md` and all transcript/inbox files on disk are the handoff to Phase 2
