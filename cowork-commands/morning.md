---
name: morning
description: Interactive morning review: walk through today's tasks client-by-client, adjust priorities, create calendar blocks.
---

# Morning Review

Interactive morning review command. Reviews Today.md client-by-client, interviews the user for gaps, then creates calendar time blocks.

---

## Step 1: Load

1. Run `date` to get today's date and day of week ([Your Timezone])
2. Read `Inbox/Today.md`
3. **Stale check**: Compare today's actual date to the date in the `# Today --` header
   - If the file is missing: offer to generate it inline (run the eod-today logic with live data)
   - If the date doesn't match today: warn "Today.md is stale (shows [file date], today is [actual date]). Want me to regenerate?"
   - If it matches: proceed
4. **Carried-forward detection**: Check the `### Carried Forward` section in `## Tasks`
   - Count how many items are there and extract their `<!-- carried:N -->` values
   - Note which clients have carried items and for how many days

---

## Step 2: Summary

Present a concise 8-10 line overview:

```
Good morning. [Day of week], [Month DD].

[N] meetings today -- first at [time], last at [time]
[Morning exceptions: N calls before 1 PM / "Full deep work block protected"]
Top priority: [#1 item from Top Priorities]
[Deadline alert if anything due today/tomorrow, or "No imminent deadlines"]

North Star this week:
  [Client A]: [goal]
  [Client B]: [goal]
```

Keep it scannable. No filler.

Then say: **"Let's walk through each client. I'll confirm what's on the plan and flag anything that looks off."**

---

## Step 3: Client Review (Batch + Select)

Present ALL clients at once in a single output, then use `AskUserQuestion` to collect feedback efficiently.

**Order**: Tier 1 clients first, then Tier 2, then others.

### 3a: Present the full picture

Show every client with items in Today.md's Top Priorities, Meeting Prep, or Deadline Radar in one batch:

```
### [Client A]
- [Task 1] -- ~30 min
- [Task 2] -- ~45 min
- Meeting: 1:30 PM [Contact Name] sync
- (warning) [Any flag: conflict, missing estimate, risk]
- Deep work needed: ~75 min

### [Client B]
- [Task 1] -- ~20 min
- Meeting: 2:00 PM [Contact Name] check-in
- Looks clean.
- Deep work needed: ~20 min

### [Client C]
...
```

**What to flag:**
- Tasks with no clear time estimate
- Tasks too ambitious for available deep work
- Meeting prep items that reference unverified things
- Conflicts between tasks competing for the same slot
- "Waiting on" items where you could unblock
- Deadlines today/tomorrow without a clear slot

Then show the capacity check:

```
Total deep work needed: ~[X] hrs
Available deep work: ~[A] hrs (DW1: [B] hrs, DW2: [C] hrs)
[Warning if overcommitted]
```

### 3b: Collect feedback via AskUserQuestion

Use `AskUserQuestion` with **multiSelect: true** to ask which clients need changes:

```
Question: "Any clients need adjustments?"
Header: "Review"
Options:
  - "All good" / "No changes needed, move to scheduling"
  - "[Client1]" / "[Brief flag summary, e.g. 'has conflict']"
  - "[Client2]" / "[Brief flag summary]"
  - "[Client3]" / "[Brief flag summary]"
```

Build the options dynamically from the clients that have items. Include up to 4 options (prioritize clients with flags). If more than 3 clients have items, group the clean ones and only list flagged clients as individual options. "Other" is always available for free-text input.

### 3c: Handle adjustments

- If "All good" is selected: proceed to Step 4 immediately.
- If specific clients are selected: for each flagged client, use another `AskUserQuestion` with common actions:
  ```
  Question: "What's the change for [Client]?"
  Header: "[Client]"
  Options:
    - "Drop a task" / "Remove lowest priority item"
    - "Push to tomorrow" / "Move a task to tomorrow's plan"
    - "Adjust time" / "Change time estimates"
    - "Add a task" / "Something's missing"
  ```
  Then apply the change. Use "Other" for anything that doesn't fit the presets.
- If "Other" is used for free-text: parse the response, apply changes, route any brain dump items to appropriate client inbox files.

### 3d: Confirm if changes were made

If any adjustments were made, show a brief diff:

```
Changes applied:
- [Client A]: dropped [task], saves ~30 min
- [Client C]: pushed [task] to tomorrow

Updated totals: ~[X] hrs needed, ~[A] hrs available.
```

No confirmation needed here, just proceed to Step 4.

---

## Step 4: Goal Check

Read each client's Company Profile `## Strategic Goals` section.

Check for staleness:
- If `*Last updated: YYYY-MM-DD*` still has the placeholder text, it's empty
- If the date is >7 days ago, it's stale
- If goals still contain placeholder text ("Goal 1", "Goal A"), it's empty

If any are empty or stale, mention which clients inline and use `AskUserQuestion`:

```
Question: "Strategic goals are stale for [Client1, Client2] (last updated [date]). Refresh now?"
Header: "Goals"
Options:
  - "Skip" / "Move on, I'll update later"
  - "Quick refresh" / "I'll dictate updated goals for each"
```

- If "Skip": proceed immediately to Step 5 (don't nag)
- If "Quick refresh": for each stale client, use `AskUserQuestion` to collect the goal, then update the Company Profile files
- If all goals are current: skip this step entirely, no output needed

---

## Step 5: Create Calendar Time Blocks

Now that the plan is confirmed, create time blocks on Google Calendar for the deep work sessions.

1. **Fetch today's calendar** to see what's already there (meetings, existing blocks, etc.)
2. **Identify open windows** between fixed events (meetings, lunch, breaks). Example skeleton:
   - Deep Work 1: 8:05 AM to first interruption
   - Deep Work 2: After last afternoon meeting to 5:30 PM wind-down
   - Buffer slots: 15 min after meeting gauntlets
3. **Assign tasks to time blocks** based on the review results:
   - Highest priority items go in Deep Work 1 (freshest energy)
   - Meeting follow-ups and async work go in Deep Work 2
   - Respect the time estimates from the review
4. **Present the proposed blocks and ask for approval via `AskUserQuestion`:**

Show the table first:

```
Proposed time blocks:

| Time | Block | Tasks |
|------|-------|-------|
| 8:05-8:20 | LinkedIn | Posts and engagement |
| 8:20-8:35 | Team priorities | Send daily priorities |
| 8:35-10:30 | Deep Work 1 | [Client A] task (~45 min), [Client C] prep (~30 min) |
| 10:30-11:45 | Deep Work 1 (cont) | [Client D] roadmap (~45 min), [Client B] prep (~15 min) |
| ... | ... | ... |
```

Then immediately use `AskUserQuestion`:

```
Question: "Create these time blocks on the calendar?"
Header: "Schedule"
Options:
  - "Create all (Recommended)" / "Add all blocks to Google Calendar as shown"
  - "Adjust first" / "I want to move or change some blocks"
  - "Skip blocks" / "Don't create calendar events today"
```

5. **Create calendar events** for each approved block.
6. **Update Today.md** with the finalized schedule table using Python read-modify-write (iCloud safety).

---

## Step 6: Send-off

Confirm the plan is locked:

```
Plan locked. [N] time blocks created.
First meeting at [time] ([title]).
[Top priority] starts now in Deep Work 1 (8:05-[first interruption]).
Have a good one.
```

If no meetings: "No meetings today. Full deep work runway. [Top priority] starts now."

---

## Notes

- Use `AskUserQuestion` for ALL interaction points. Never just ask a question in text and wait for the user to type. Every decision point must use selectable options.
- If the plan looks clean and "All good" is selected in Step 3, the entire review can complete with just 3 taps: "All good" -> "Skip"/"Create all" -> done. Minimize friction.
- Today.md is ephemeral (overwritten each EOD run). The daily note (`Work/Daily/YYYY-MM-DD.md`) is the permanent record.
- For iCloud-safe writes to Inbox files, always use Python read-modify-write (same pattern as EOD).
- **Time block granularity**: Don't create 15-minute blocks for everything. Group related small tasks into blocks of 30-90 minutes.
- **Overcommitment guard**: If total estimated work exceeds available deep work time, force a prioritization conversation in Step 3 before creating blocks.
- **Calendar cleanup**: If the user ran /morning earlier today and wants to re-run, check for existing time blocks from this morning and offer to replace them rather than duplicating.
