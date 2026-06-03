# Pickup

Pick up a handed-off conversation. Reads a named handoff from `.claude/handoffs/` in the current working directory, pulls the context it lists, and reports back where we left off so the user can keep moving without re-explaining anything.

Pair with `/handoff` (which writes the file in the previous session). Named `/pickup` (not `/resume`) to avoid shadowing Claude Code's built-in `/resume` session picker.

**Optional argument:** the name of the handoff to resume (e.g., `/pickup vault-cleanup`). This is the filename `/handoff` wrote, minus the `.md`. If no name is given, list the available handoffs and ask which to resume.

Name: $ARGUMENTS

---

## Step 0: Resolve Which Handoff to Read

Handoffs live in `.claude/handoffs/<name>.md` relative to the current working directory (this is where `/handoff` writes them).

**If `$ARGUMENTS` is provided:**

Sanitize it the same way `/handoff` does: lowercase, replace spaces with hyphens, strip special characters except hyphens and underscores. This is `HANDOFF_NAME`. The target file is `.claude/handoffs/HANDOFF_NAME.md`.

- If that file exists, go to Step 1.
- If it does NOT exist, list what's actually in `.claude/handoffs/` (run `ls -t .claude/handoffs/*.md 2>/dev/null`) and tell the user: `No handoff named '[HANDOFF_NAME]'. Available handoffs: [list with relative ages]. Which one?` Wait for their answer, then proceed. Do not silently fall back to a different file.

**If `$ARGUMENTS` is empty:**

List the available handoffs and ask which to resume. Run `ls -t .claude/handoffs/*.md 2>/dev/null` and, for each, read its `# Handoff -- [Topic] -- [timestamp]` header line to show topic + age. Present:

```
Available handoffs in .claude/handoffs/:

  1. [name] -- [topic] -- [relative age, e.g. "5 min ago"]
  2. [name] -- [topic] -- [relative age]

Which one? (or tell me what you're working on and I'll skip the handoff)
```

- If `.claude/handoffs/` is empty or missing, tell the user: `No handoffs found in .claude/handoffs/. Nothing to resume -- either run /handoff in a previous session first, or just tell me what you're working on.` Stop.
- If there is exactly **one** handoff, you may name it and proceed straight to Step 1 (still report which one you picked), rather than making them choose from a list of one.

> **Legacy note:** Older sessions may have written a single `handoff.md` at the working-directory root (and, older still, `~/.claude/handoff.md`). The current system is the named `.claude/handoffs/<name>.md` directory. Do NOT read a root `handoff.md` unless the user explicitly points you at it -- a stale root file is almost certainly an orphan from the old system and will hijack the resume.

## Step 1: Read the Handoff File

Read the resolved `.claude/handoffs/HANDOFF_NAME.md`.

- **Note the "Working directory" line** from the handoff header. If it doesn't match the current `pwd`, tell the user and ask whether to `cd` into the handoff's working dir or operate from the current one before loading any context.

## Step 2: Freshness Check

Run `date` and compare to the timestamp in the handoff's `# Handoff -- [Topic] -- [YYYY-MM-DD HH:MM ET]` header.

- **Under 6 hours old**: Fresh. Proceed.
- **6-24 hours old**: Note this to the user in the summary (`Handoff is [N] hours old -- state may have drifted`) but proceed.
- **Over 24 hours old**: Warn the user explicitly before loading context: `Handoff is [N] days old. State has almost certainly drifted since then. Want me to resume from it anyway, or start fresh?` Wait for confirmation.

## Step 3: Load the Context

Parse the `## Load This Context Before Responding` section of the handoff file. For each listed item:

- **Read:** entries -- use the Read tool on the exact path (and line range if given)
- **Bash:** entries -- run via Bash tool
- **Check memory:** entries -- Read the file from the memory directory for the project named in the handoff's "Working directory" line. The path follows the pattern `~/.claude/projects/<escaped-cwd>/memory/[filename]`, where `<escaped-cwd>` is the working directory with slashes and dots replaced by hyphens.
- **Grep/Glob:** entries -- use the appropriate tool

Run all independent reads/commands **in parallel** in a single tool-call block. Do not serialize them.

If any context item fails (file moved, command errors, memory entry missing), note it but continue -- don't abort the resume. A stale pointer is information: it tells you something changed since the handoff was written.

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
Resumed from handoff '[HANDOFF_NAME]' (written [relative time, e.g., "5 min ago" or "yesterday 4:30 PM"]).

**Goal:** [one line from handoff]

**Where we left off:** [2-3 sentences synthesizing current state -- your own words, not a copy-paste from the file]

**Loaded context:** [N files, M commands] -- [one-line summary of anything surprising you found, or "matches handoff" if nothing changed]

**Next step:** [first concrete action from the handoff's Next Steps list]

[If there are open questions for the user from the handoff, list them here as a short bulleted block. Otherwise omit.]

[If reality diverged from the handoff, flag it here in 1-2 lines. Otherwise omit.]

Ready to continue. Want me to proceed with [next step], or something different?
```

Do not dump the full handoff into the chat. The user wrote it (via the previous session) -- they don't need to re-read it. Your job is to prove you understood it and are ready to pick up the thread.

## Step 6: Wait for Go-Ahead

Stop after the summary. Wait for the user to confirm or redirect before taking any action on the actual work. Resuming is about re-establishing shared context, not auto-executing. The user may want to change direction now that they're back in the chair.

---

## Notes

- **Don't delete the handoff file** after reading. Leave it in place -- if the user clears again mid-session, it's still there as a fallback until they run `/handoff` with the same name (which overwrites) or delete it.
- **Handoffs are named and persistent.** `.claude/handoffs/` can hold many handoffs across different workstreams. `/pickup <name>` targets one; `/pickup` with no args lists them.
- **If the handoff's "Working directory" differs from `pwd`**, the handoff was written from a different location. Ask the user whether to operate from the current directory or the one recorded in the handoff.
- **If `.claude/handoffs/` is empty**, don't try to synthesize a pickup from thin air -- just tell them there's nothing to resume.
