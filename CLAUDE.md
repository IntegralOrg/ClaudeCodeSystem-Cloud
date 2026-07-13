# ClaudeCodeSystem Setup Repo

This is the setup repository for the Claude Code Personal Assistant System. It is NOT a vault -- it contains the templates, examples, and setup commands used to build a vault.

## If the user opens Claude Code in this folder

Guide them to type `/onboard` to begin setup. The skills are in `.claude/commands/` and are ready to use.

## If this folder is nested inside an existing vault (bootstrap mode)

The user may have added this repo inside their existing vault. Detect this by checking:
1. Does a parent directory look like a vault (contains a `CLAUDE.md` with vault content, `Inbox/`, `Work/`, or similar vault files)?
2. Is this folder nested (e.g., `Brain/ClaudeCodeSystem-main/` or `Brain/ClaudeCodeSystem/`)?

If yes, **bootstrap automatically**:

1. Identify the vault root (the nearest parent that looks like a vault root).
2. Copy all files from this repo's `.claude/commands/` to the vault root's `.claude/commands/`:
   ```
   mkdir -p <vault_root>/.claude/commands/
   cp .claude/commands/*.md <vault_root>/.claude/commands/
   ```
3. Tell the user: "I found the setup files and copied the commands to your vault. You can now type `/onboard` to begin, or I can start it for you."
4. Offer to start `/onboard` immediately.

## If the user just says "set me up" or "help me get started"

Read `.claude/commands/onboard.md` from this repo and execute it directly. The user does not need to know about skills to get started.

## Dual-Format Slash Commands (Code vs CoWork)

Slash commands exist in **two formats** to support both Claude Code and Claude CoWork:

| Format | Location | Frontmatter | How Users Get Them |
|--------|----------|-------------|-------------------|
| Claude Code | `.claude/commands/` | None needed | Auto-discovered by Claude Code; copied to vault during `/onboard` Phase 6E |
| Claude CoWork | `cowork-commands/` | YAML `---` block with `name:` and `description:` | Manually uploaded by user through the **Customize** section in CoWork settings |

**Maintenance rule: when you create or modify a slash command, you MUST update both versions.** The CoWork version is identical to the Code version except for the YAML frontmatter block at the top of the file:

```yaml
---
name: command-name
description: One-line description of what the command does.
---
```

The `name` field should match the filename (without `.md`). The `description` should be a clear one-liner that helps the user understand when to use the command.

**There is exactly one folder of Code commands: `.claude/commands/`.** (The old `examples/commands/` folder was removed -- it created the illusion that some commands were optional examples, which is how they kept getting dropped during onboarding. All commands are first-class and shipped.)

**To add a new command:**
1. Create the Code version in `.claude/commands/`
2. Copy it to `cowork-commands/` and prepend the YAML frontmatter

That is it. **You do NOT need to register the command anywhere in `onboard.md`.** Phase 6E installs *every* `.md` from `.claude/commands/` with an unconditional glob copy (and copies all of `cowork-commands/` into the vault for users who also use Cowork -- those files are upload-ready mirrors the user adds through Cowork's **Customize** section). Any command you add to those folders ships to every user automatically. There is deliberately no hand-maintained install list, because that list is what kept dropping commands during onboarding.

**To modify an existing command:**
1. Edit the Code version (the source of truth)
2. Copy the changes to the matching file in `cowork-commands/` (preserve the YAML frontmatter)

## After setup is complete

This repo is no longer needed. Everything gets copied into the user's vault during `/onboard`. The `/finish` command offers to archive this folder.

---

## Developing THIS repo (Integral team, not vault users)

Everything above is for a user setting up their vault. If you are an Integral developer changing this repo, follow the **Integral development playbook**. This repo is its canonical home:

> `docs/guides/development-process.md`
> ([permalink](https://github.com/IntegralOrg/ClaudeCodeSystem-Cloud/blob/main/docs/guides/development-process.md))

That file is the **single copy** for every Integral repo. Other repos link to it and must not hold their own copy: it used to be duplicated around, the copies drifted, and the drift silently broke the CodeRabbit loop for months. Fix it here and every repo gets the fix.
