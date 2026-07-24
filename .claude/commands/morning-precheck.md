# Morning Pre-check (headless / cloud-scheduled)

**Purpose:** Do the heavy "what's actually still open" research BEFORE you run `/morning`, so the interactive command stays light and never has to be told which tasks are already done. Runs as a scheduled [Routine](https://code.claude.com/docs/en/routines) in Claude Code on the web (~6:00-7:00 AM in your local timezone, weekdays).

---

## Hard constraints (read first)

- **HEADLESS. Never call `AskUserQuestion` or block on input.** If you would normally ask, instead write the item to the `## Confirm` section of the state file and move on.
- **Create NO calendar blocks.** This command only researches and writes a state file. All scheduling happens later in the interactive `/morning` command.
- **Never delete, defer, or reschedule a task.** You may only (a) mark a task done in the vault when evidence is HIGH, or (b) flag for the user's confirmation.
- **Never send anything** (no email, no Slack message, no SMS).
- **If a data source errors, log it in `## Notes` and continue.** Never abort the whole run over one failed API.
- **Conservative bias:** when torn between HIGH and MEDIUM confidence, choose MEDIUM (flag, don't auto-mark).
- **Done-by-anyone counts.** A task is complete if it has been resolved by *anyone*, not just the user. A teammate delivering the work, or the client themselves resolving the underlying request, makes the task done. Do NOT require the user's own action to mark done. *(Past failure mode: already-done tasks stayed open for days because the checks only looked for the user's own actions.)*
- **Verify at the source.** Every task should carry a provenance note (e.g. `*from Email: [Contact], 6/1*`, `*from Slack: [Client A] DM*`, `*from Fathom: [Meeting name] MM/DD*`). That note tells you EXACTLY which thread/DM/transcript to open. Route each task to the subagent that owns its source and read the WHOLE thread, not just one side of it.

---

## Step 1: Stamp time + window

1. Run `date` and record today's day-of-week + `HH:MM` in your local timezone.
2. **Look-back window start** = 8:00 AM the previous workday (Friday if today is Monday). Compute its Unix timestamp for Slack queries. The cloud container usually runs in UTC, so anchor the computation to your real timezone explicitly:

   ```bash
   python3 <<'PY'
   import datetime, zoneinfo
   TZ = zoneinfo.ZoneInfo("[YOUR_IANA_TIMEZONE]")  # replace with your IANA timezone name, e.g. America/New_York, America/Los_Angeles, Europe/London, Asia/Kolkata
   today_local = datetime.datetime.now(TZ).date()
   offset_days = 3 if today_local.weekday() == 0 else 1  # Monday looks back to Friday
   prev = today_local - datetime.timedelta(days=offset_days)
   start = datetime.datetime.combine(prev, datetime.time(8, 0), tzinfo=TZ)
   print(int(start.timestamp()))
   PY
   ```

## Step 2: Collect open tasks

- Read every `Inbox/<Client>.md` and `Inbox/[YourCompany].md` file. From each, extract the `## Open Tasks` list.
- For each open task, capture: the file it lives in, the visible task text, and its provenance note (`*from <source>*`) if present.
- Build one flat list. This is the work-list the subagents verify against. **Route each task to a subagent by its source prefix**:
  - `Email:` -> Gmail subagent
  - `Slack:` -> Slack subagent (note the named DM/channel)
  - `Fathom:` or `transcript:` -> Transcript subagent
  - Tasks with no provenance (or an unrecognized prefix) go to BOTH Gmail + Slack.

## Step 3: Spawn one subagent per data source (in parallel)

Source `.env` first. Dispatch these as parallel agents (Task tool). Each gets the open-task list and returns **structured findings**: `[{task_id, source, evidence, confidence}]` where `confidence ∈ {high, medium, low, moot}`.

### 3.1 Gmail subagent

*This is a check that has failed before; it must run thoroughly.*

Search BOTH the inbox and sent mail (not sent-only) on `[Your Primary Email]` and any secondary/role inboxes you have connected (e.g. a hiring inbox), since the window start.

- **Read the FULL thread, both sides.** For any task whose provenance names an email thread (or that references a person/client/subject), find that thread and read the most recent messages from EVERYONE on it. A reply that resolves the request -- *from anyone*, including a teammate or the client -- is a completion signal. Do NOT require the user to be the sender.
- **Don't gate on email-phrased wording.** A task like "add data field X" or "fix Y" can be resolved on an email thread even though it isn't phrased as "reply/send." If the task names a person or cites an email thread, open it.
- **Completion language to treat as done:** "added", "done", "shipped", "deployed", "sent", "fixed", "live", "taken care of", "handled". Match the task by recipient/sender name, subject keyword, client domain, or the specific identifier in the task (SKU, invoice #, doc name).
- A clear in-thread resolution = **HIGH**. Ambiguous / partial = **MEDIUM**.

### 3.2 Slack subagent

Across connected workspaces (`SLACK_TOKEN_*`), use `conversations.history` and `conversations.replies` (NOT `search.messages` unless your token has the `search:read` scope) with Unix `oldest` / `latest`.

- **Always open the key DMs/channels named in task provenance**, plus any standing high-signal DMs (your primary teammate, dev lead, PM, etc.) -- approvals and sign-offs often live in these threads. Use `conversations.list` (`types=im,public_channel,private_channel`) to resolve any DM/channel not in your standing list.
- **Two kinds of completion, both count:**
  1. Signals FROM the user (sent, done, delivered, shared, scheduled, set up, created, fixed, approved, "looks great") matching a task -> **HIGH/MEDIUM**.
  2. **A teammate resolving the user's task** (e.g. "Added", "shipped/deployed/done") -> **HIGH/MEDIUM** done-for-user -- do NOT require the user's own message.
  3. Inbound "all set / never mind / already handled / no longer needed" -> **MOOT**.
- Read thread replies, not just top-level channel messages -- approvals and "done" often live in a thread.

### 3.3 Calendar subagent

Pull today's REAL events live (Google Calendar API, OAuth refresh in `.env`). Return the full list. Also: for any task that is meeting-prep for a meeting that already happened (exists + not cancelled), mark the prep **MEDIUM**-done.

### 3.4 Transcript subagent *(only if any task is phrased "discuss X in call with Y")*

Check today's meeting-transcript folder(s) (e.g. `Work/Clients/*/Transcripts/`, `Work/Transcripts/`, `[YourCompany]/Transcripts/`); if the topic appears in the summary, mark **MEDIUM**-done.

---

## Step 4: Classify + act

Merge subagent findings per task (take the strongest evidence). A finding that the task was resolved by a **teammate or the client** (not just the user) is valid HIGH/MEDIUM evidence -- weigh it the same as a user action.

- **HIGH** -> mark the task done in the vault. Read the file, change `- [ ]` to `- [x]`, append ` -- verified via [source] [HH:MM]` to the line, write it back.
  - Match on the EXACT task line (full-text identity check, not a bare keyword). *(Past failure mode: keyword matching wrongly checked off the wrong item -- the fix is to match the full task line.)*
  - If two open tasks match, downgrade to MEDIUM and flag both -- do NOT guess.
- **MEDIUM / LOW** -> add to `## Confirm` in the state file with the evidence. Do NOT edit the client file.
- **MOOT** -> add to `## Confirm`, flagged: `appears moot -- "<inbound quote>"`.

---

## Step 5: Write the state file

Write `Inbox/Morning Precheck.md` (overwrite). Use this shape:

```markdown
# Morning Pre-check -- <Weekday, Month D, YYYY>
*Generated headless at <HH:MM> [TZ]. Read by /morning. Creates no calendar blocks.*

## Auto-marked Done (HIGH confidence)
- [x] **[Client A]** <task> -- <evidence> (<source>)
  ...or "_None._"

## Confirm (medium/low/moot -- /morning will ask)
- **[Client B]** <task> -- <evidence>, confidence: medium
- **[Client C]** <task> -- appears MOOT: "<inbound quote>"
  ...or "_None._"

## Live Calendar (today)
| Time | Event | In Today.md? |
|------|-------|--------------|
| 12:30-1:00 | [Client A] x Team | yes |
| 1:00-1:30 | Agency Check-in | (warning) NO -- surfaced by precheck |

## Notes
- <API failures, skipped sources, anything /morning should know>
```

The **"In Today.md?"** column is critical: it catches meetings that the previous night's plan missed. *(Past failure mode: 3 afternoon meetings were invisible to the plan because the previous EOD ran before they landed on the calendar.)*

---

## Step 6: Commit and push

Commit `Inbox/Morning Precheck.md` and any client files you marked done in Step 4:

```bash
git add -A && git commit -m "Morning precheck YYYY-MM-DD" && git push
```

The vault runs in a temporary cloud workspace; unpushed changes are lost when the session ends. If the push is rejected because the remote moved, run `git pull --rebase`, then push again. If nothing changed, skip silently.

## Step 7: One-line status

Print exactly one line:

```
Pre-check complete: N auto-marked done, M to confirm, K meetings today (J not in Today.md).
```

---

## Deployment (how the user schedules this)

Create a [Routine](https://code.claude.com/docs/en/routines) in Claude Code on the web:

- **Repository:** your vault repository
- **Prompt:** `/morning-precheck`
- **Schedule:** something like `30 6 * * 1-5` (6:30 AM weekdays in the routine's configured timezone) -- pick a time that lands ~30 minutes before the user's usual morning review.

The routine runs in the cloud, writes `Inbox/Morning Precheck.md`, and pushes. When the user runs `/morning` later that morning, it reads the pre-check and skips the heavy research pass.

---

## Notes

- If the routine misses a day (API outage, service issue), the `/morning` command should fall back to its own inline verification. This command's job is to make the morning fast, not to be a hard dependency.
- Never call `AskUserQuestion`. Anything ambiguous goes to `## Confirm` for `/morning` to ask about later.
- The state file lives at `Inbox/Morning Precheck.md` so `/morning` (which reads `Inbox/Today.md`) can find it in the same folder without extra configuration.
