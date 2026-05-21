---
name: pickup
description: Resume from a previous handoff. Lists available handoffs, loads context, and reports where you left off.
---

# Pickup

Pick up a handed-off conversation. Reads a handoff file from `.claude/handoffs/`, pulls the context it lists, and reports back where we left off so the user can keep moving without re-explaining anything.

Pair with `/handoff` (which writes the file in the previous session). Named `/pickup` (not `/resume`) to avoid shadowing Claude Code's built-in `/resume` session picker.

Optional argument: the name of a specific handoff to resume (e.g., `/pickup trussi-workflow-fix`). If omitted, lists available handoffs and lets the user choose.

Name: $ARGUMENTS

---

## Step 1: Find the Handoff

Check if `.claude/handoffs/` exists in the current working directory.

**If the directory does not exist or is empty:**
Tell the user: `No handoffs found in this directory. Nothing to resume. Either run /handoff <name> in a previous session first, or just tell me what you're working on.` Stop.

**If `$ARGUMENTS` is provided:**
Sanitize the name (lowercase, spaces to hyphens). Look for `.claude/handoffs/HANDOFF_NAME.md`.
- If found: proceed to Step 2 with that file.
- If not found: list available handoffs and tell the user: `No handoff named '[name]' found. Available handoffs:` then list them. Stop and let the user pick.

**If `$ARGUMENTS` is empty:**
List all `.md` files in `.claude/handoffs/`, sorted by modification time (newest first). Show each with its name and the date from the first line of the file (the `# Handoff -- [Topic] -- [date]` header).

- **If only one handoff exists:** Use it automatically. Tell the user which one you're loading.
- **If multiple exist:** Present the list and ask:

AskUserQuestion: "Which handoff do you want to resume?"
Options:
- [List up to 4 most recent handoffs by name and date, newest first]

Proceed with the selected file.

## Step 2: Read and Freshness Check

Read the selected handoff file.

Run `date` and compare to the timestamp in the handoff's `# Handoff -- [Topic] -- [YYYY-MM-DD HH:MM ET]` header.

- **Under 6 hours old**: Fresh. Proceed.
- **6-24 hours old**: Note in the summary (`Handoff is [N] hours old; state may have drifted`) but proceed.
- **Over 24 hours old**: Warn explicitly before loading context: `Handoff is [N] days old. State has almost certainly drifted since then. Want me to resume from it anyway, or start fresh?` Wait for confirmation.

**Note the "Working directory" line** from the handoff header. If it doesn't match the current `pwd`, tell the user and ask whether to `cd` into the handoff's working dir or operate from the current one before loading any context.

## Step 3: Load the Context

Parse the `## Load This Context Before Responding` section of the handoff file. For each listed item:

- **Read:** entries -- use the Read tool on the exact path (and line range if given)
- **Bash:** entries -- run via Bash tool
- **Check memory:** entries -- Read the file from the memory directory for the project. The path follows the pattern `~/.claude/projects/<escaped-cwd>/memory/[filename]`.
- **Grep/Glob:** entries -- use the appropriate tool

Run all independent reads/commands **in parallel** in a single tool-call block. Do not serialize them.

If any context item fails (file moved, command errors, memory entry missing), note it but continue. Don't abort the resume. A stale pointer is information: it tells you something changed since the handoff was written.

## Step 4: Sanity-Check Against Reality

The handoff is a snapshot. Before trusting it, verify the parts that could have changed:

- If the handoff references uncommitted git state, run `git status` and compare
- If it references a file at a specific line number, confirm the line numbers still match after your Read
- If it says "waiting on the user to decide X", note that the question is still open
- If it says something is "running in the background", check whether it actually still is

If reality diverges from the handoff in a way that affects the next steps, flag it in your summary.

## Step 5: Report Back

Give the user a compact resume summary. Target: under 200 words. Format:

```
Resumed from handoff "[HANDOFF_NAME]" written [relative time, e.g., "2h ago" or "yesterday 4:30 PM"].

**Goal:** [one line from handoff]

**Where we left off:** [2-3 sentences synthesizing current state -- your own words, not a copy-paste from the file]

**Loaded context:** [N files, M commands] -- [one-line summary of anything surprising you found, or "matches handoff" if nothing changed]

**Next step:** [first concrete action from the handoff's Next Steps list]

[If there are open questions from the handoff, list them here as a short bulleted block. Otherwise omit.]

[If reality diverged from the handoff, flag it here in 1-2 lines. Otherwise omit.]

Ready to continue. Want me to proceed with [next step], or something different?
```

Do not dump the full handoff into the chat. The user wrote it (via the previous session); they don't need to re-read it. Your job is to prove you understood it and are ready to pick up the thread.

## Step 6: Wait for Go-Ahead

Stop after the summary. Wait for the user to confirm or redirect before taking any action on the actual work. Resuming is about re-establishing shared context, not auto-executing. The user may want to change direction.

---

## Notes

- **Don't delete the handoff file** after reading. Leave it in place as a reference. The user can clean up `.claude/handoffs/` periodically.
- **If the handoff's "Working directory" differs from `pwd`**, the handoff was written from a different location. Ask the user whether to operate from the current directory or the one recorded in the handoff.
- **If the user runs `/pickup` with no handoffs available**, don't try to synthesize a pickup from thin air. Just tell them there's nothing to resume.
