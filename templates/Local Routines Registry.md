---
type: reference
status: active
canonical: true
created: YYYY-MM-DD
tags: [routines, desktop, backup, disaster-recovery]
aliases: ["Local routines", "Desktop scheduled tasks backup"]
summary: "Every Claude desktop LOCAL scheduled task on your machines, with the settings the app does not export, so a new computer can recreate them exactly. Prompts are mirrored by scripts/local-routines-backup.sh."
---

# Local Routines Registry

**Rule (CLAUDE.md, Assistant Guidelines):** any routine that runs locally (Claude Desktop, Routines page, kind Local) is backed up here. A local task lives only on its machine: the prompt sits at `~/.claude/scheduled-tasks/<name>/SKILL.md`, and the schedule, folder, model, permission mode, worktree toggle, and "always allow" approvals sit in the Desktop app's private state, which nothing exports. Local tasks do not appear in your account's cloud routine list. A crashed or replaced computer loses them. Cloud routines (kind Remote) need nothing here; they belong to your account.

**Two halves of the backup:**
1. **Prompts (automatic):** `bash scripts/local-routines-backup.sh` mirrors every `SKILL.md` to `Resources/Reference/Local Routines/<device>/<task>.SKILL.md` and removes mirrors of deleted tasks. Run it after creating, editing, pausing, or deleting any local task.
2. **Settings (by hand, this file):** one row per task below with everything the app does not write to disk. Update the row in the same session as the change.

**Restore on a new computer:** for each row, open Claude Desktop, Code tab, Routines, New routine, Local; paste the mirrored prompt as Instructions; set the fields from the row; click Run now once and choose "always allow" for the listed command(s); then run the backup script on the new machine and update the Device column. Where a deploy script is listed, run it first; it installs the local files the task depends on.

## Tasks

| Task name | Device | State | Schedule | Folder | Worktree | Model | Permissions | Command the task runs (always-allow this) | Depends on (run first) | Since |
|---|---|---|---|---|---|---|---|---|---|---|
| `example-daily-brief` | `my-laptop` | active | weekdays 08:00 | `/path/to/vault` | off | Haiku | Auto | `python3 scripts/example.py --quiet` | none | YYYY-MM-DD |

## Machine-side state that is NOT a routine but is also per-machine

List anything a rebuild needs in the same pass: local git clones, `~/scripts/` helpers, local data folders that never enter the vault, the `.env` file (restore from your password manager), and `~/.claude/settings.json` allow rules.

## Log

- YYYY-MM-DD: registry created.
