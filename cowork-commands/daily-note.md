---
name: daily-note
description: Lightweight daily capture. Record what happened today and move on.
---

# Daily Note

Lightweight daily capture. Just record what happened today and move on.

---

## Step 1: Date Check

1. Run `date` to get today's date and set `TODAY` in `YYYY-MM-DD` format

---

## Step 2: What Happened Today

1. **AskUserQuestion**: "What did you work on today? Just talk -- bullets, sentences, whatever comes to mind."
2. Save the raw response as `USER_INPUT` for use in Step 4

---

## Step 3: Pull Supporting Data

Gather what you can. Skip anything that is not available.

1. **Calendar**: Fetch today's meetings (Google Calendar MCP or API)
   - List meeting titles and times
   - If unavailable, skip and note "No calendar data"
2. **Client inboxes**: Scan `Inbox/*.md` for tasks marked `[x]` with today's date
   - Collect completed items per client
   - If no inbox files exist, skip

---

## Step 4: Write the Daily Note

Create the file at `Work/Daily/TODAY.md`:

```markdown
# TODAY

## Meetings
- (list from calendar, or "None captured")

## What I Worked On
- (user's response from Step 2, cleaned into bullets)

## Tasks Completed
- (completed items from inbox files, or "None captured")

## Summary
(2-3 sentence recap of the day)
```

Use the Write tool (new file, no read-modify-write race).

---

## Step 5: Tomorrow's Plan (Optional)

1. **AskUserQuestion**: "Want me to draft a quick plan for tomorrow?"
2. If yes:
   - Check tomorrow's calendar for scheduled meetings
   - Pull any open tasks with upcoming deadlines from inbox files
   - Append a `## Tomorrow` section to the daily note with a short bullet list
3. If no: done
