# Changelog

All notable changes to the ClaudeCodeSystem project are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [2026-07-08] - Cloud Edition: Drop Obsidian and Local-Machine Framing

### Changed
- **The documentation no longer describes the system as "built on Obsidian" or as running on the user's local machine.** This is the cloud edition -- it runs in Claude Code on the web, and the vault is a Git repository of Markdown files that Claude reads and writes directly in a cloud workspace. The system is now described as **built on Claude Code and a Git-backed Markdown vault**.
- **`README.md`**: rewrote the tagline, "What you will need," and Get Started sections for the cloud edition; removed the Windows local-install section (Git Bash / Developer Mode / Virtual Machine Platform); relabeled the architecture diagram's "Obsidian Vault" box to "Git-Backed Vault (Markdown)"; replaced the iCloud atomic-write note; updated the Windows/Linux and cost FAQs.
- **`docs/onboarding-guide.md`**: dropped the "Pick Your Claude Interface" (Desktop vs CLI) step and the "Install Obsidian" step; reframed requirements, permission descriptions, the `/connect` and morning steps, and the glossary for the cloud edition.
- **`docs/vault-design-guide.md`**: retitled and rewrote "Why Obsidian?" as "Why a Git-backed Markdown vault?"; updated the core-idea, template-placeholder, atomic-writes, and "what makes this different" sections.
- **`docs/integration-architecture.md`**, **`docs/daily-workflow.md`**, **`templates/CLAUDE.md`**: relabeled the vault, dropped the Desktop/CoWork/CLI trichotomy and iCloud/Dropbox sync-race rationale, and reframed wiki-links as the graph convention (not "clickable in Obsidian").
- **Commands** (`onboard`, `train`, `finish`, `graph-sync`, `graph-daily`, `eod-gather`, `eod-sync`, `monthly-review`, `brain-dump`, `morning`) and their `cowork-commands/` mirrors: removed "Open Obsidian" instructions, the "nothing is in the cloud / on your machine" framing, `.obsidian/` exclusions, and the iCloud atomic-write rule.
- **Repo `CLAUDE.md`**: bootstrap detection no longer keys on `.obsidian/`; it now detects an existing vault by its contents (`CLAUDE.md`, `Inbox/`, `Work/`).

---

## [2026-06-18] - Single Command Folder: Removed examples/commands/, Unconditional Install

### Fixed
- **Commands were silently dropped during onboarding.** `onboard.md` Phase 6E used a hand-enumerated, conditional install list: `morning.md`/`eod.md`/`daily-note.md`/`brain-dump.md` only installed if the user picked the matching Phase 5 workflow preference, and the five EOD phase commands (`eod-gather`, `eod-sync`, `eod-time`, `eod-note`, `eod-today`) were never installed at all. Because `/eod` and its phase commands reference each other, a half-installed pipeline broke mid-run after the user invoked a slash command.

### Changed
- **Phase 6E now installs every command unconditionally** via a glob copy of `.claude/commands/*.md` (minus `onboard.md`), in both the CLI and CoWork paths. Workflow preferences only affect which command is *recommended* and how tool-specific ones are *customized*, never whether a file is installed. There is no longer any hand-maintained install list to fall out of sync.
- **Removed the `examples/commands/` folder.** Its 10 commands (`eod`, `eod-gather`, `eod-sync`, `eod-time`, `eod-note`, `eod-today`, `morning`, `monthly-review`, `brain-dump`, `daily-note`) moved into `.claude/commands/` via `git mv`. There is now exactly one source folder for Code commands. The "examples" framing was the root cause of the drift: it made shipped commands look optional. `examples/` retains only `settings*.json` and `scripts/`.
- **Docs updated**: repo `CLAUDE.md` (Dual-Format table + maintenance rule), `README.md` (repository-structure tree), `docs/vault-design-guide.md`, and `finish.md` (both Code + CoWork copies) no longer reference `examples/commands/`.

---

## [2026-06-10] - Handoffs Moved Out of .claude/ to .handoffs/

### Changed
- **Handoff storage moved from `.claude/handoffs/` to `.handoffs/` at the working-directory root** (`/handoff`, `/pickup`, `/onboard` Phase 6E, README — both `.claude/commands/` and `cowork-commands/` copies). Claude Code's hardcoded sensitive-file guard prompts on EVERY Write/Edit under `.claude/` directories and cannot be suppressed by permission allow rules, PreToolUse hooks, or PermissionRequest hooks (verified empirically; known open bug anthropics/claude-code#41615, including the dialog's non-persisting "always allow" option). Moving the directory out of `.claude/` is the only way to make handoff writes prompt-free.
- **`/pickup` legacy fallback extended**: if `.handoffs/` is missing or empty but `.claude/handoffs/` has files, read from there and suggest migrating them (covers projects not yet moved).

### Migration
- Per project: `mv .claude/handoffs .handoffs` and gitignore `.handoffs/` (keep the old `.claude/handoffs/` ignore line for stragglers).

---

## [2026-06-03] - Remove Legacy /resume Command

### Removed
- **`/resume` deleted** (`examples/commands/resume.md` + `cowork-commands/resume.md`) and dropped from the onboard Phase 6E install lists. It drove the obsolete single global `~/.claude/handoff.md` pattern that `/pickup`'s legacy note warns against. Use `/handoff` + `/pickup` (named, per-project, multiple active handoffs) instead.

---

## [2026-06-03] - Handoff/Pickup Promoted to the Standard Command Set

### Changed
- **`/handoff` and `/pickup` moved from `examples/commands/` into the standard set `.claude/commands/`.** They are now core commands every user receives during setup (like `/onboard`, `/strategy`, `/learn`), not optional examples. One source of truth per command.
- **`/pickup` updated to the latest functionality**: explicit "Step 0: Resolve Which Handoff to Read" (lists actual handoffs and asks rather than silently falling back), a legacy-note guard against stale root `handoff.md` orphans hijacking a resume, and split Read / Freshness-check steps.
- **`onboard.md` Phase 6E**: handoff/pickup now install from `.claude/commands/` under an "Always copy these session-continuity skills (every user gets these)" block, with rationale on why they exist (context + task management, hand off / pick up conversations, persistent track record in the vault).
- **`cowork-commands/handoff.md` and `pickup.md`** synced to the new bodies (YAML frontmatter preserved).
- **README**: added a "Session Continuity (`/handoff` and `/pickup`)" key-concept section and listed both in the repository-structure tree under `.claude/commands/`.

### Removed
- `examples/commands/handoff.md` and `examples/commands/pickup.md` (moved to the standard set; no longer duplicated in examples).

---

## [2026-04-28] - Brainstorming Skill + Local Handoff Files

### Added
- **Brainstorming community skill** installed during onboarding via `npx skills add https://github.com/obra/superpowers --skill brainstorming`
- Added `/brainstorming` to the strategy skills walkthrough in `train.md`

### Changed
- **Handoff/Pickup now write to the current working directory** instead of global `~/.claude/handoff.md`. Each project gets its own `handoff.md`, so multiple projects can have independent active handoffs.

---

## [2026-04-24] - Handoff and Pickup Improvements
`d1b93a3`

### Changed
- Revised `examples/commands/handoff.md` for improved clarity

### Added
- New `examples/commands/pickup.md` skill for resuming work across sessions

---

## [2026-04-15] - License Change
`d30f875`

### Changed
- **License switched from MIT to CC BY-NC-ND 4.0** — the project is no longer permissively licensed; commercial use, modifications, and derivatives are restricted
- README updated to reflect the new license

---

## [2026-04-11] - Task Management Refactor
`713fbad`

### Added
- `examples/commands/handoff.md` — new skill for session handoff documentation
- `examples/commands/resume.md` — new skill for resuming previous sessions

### Changed
- Restructured task management documentation across `daily-workflow.md`, `vault-design-guide.md`, and template `CLAUDE.md`
- Simplified `eod-sync.md` and `eod-gather.md` example skills
- Minor fixes to `finish.md`, `onboard.md`, `optimize.md`, and `monthly-review.md`

---

## [2026-04-10] - Knowledge Graph in Vault Docs
`b457201`

### Changed
- Added knowledge graph integration guidance to `docs/vault-design-guide.md` and `templates/CLAUDE.md`

---

## [2026-04-08] - Knowledge Management Skills
`8f33a98` / `cc7e9fe`

### Added
- **Six new skills moved to `.claude/commands/`** (previously in `examples/`):
  - `build-skill.md` — turn a successful task into a repeatable workflow
  - `graph-daily.md` — incremental daily knowledge graph sync
  - `graph-sync.md` — full vault knowledge graph rebuild
  - `learn.md` — capture and integrate new knowledge
  - `optimize.md` — audit and improve existing setup
  - `strategy.md` — structured problem-solving with Integral methodology
- `templates/integral-methodology.md` — Integral methodology reference document
- Enhanced `onboard.md` and `train.md` with knowledge graph and skill creation sections

---

## [2026-03-31] - Vault Path Fix
`6638d87`

### Changed
- Minor fix to `onboard.md` for vault path determination logic

---

## [2026-03-27] - "Slash Commands" Renamed to "Skills"
`084a77b`

### Changed
- **Terminology change across the entire project**: all references to "slash commands" replaced with "skills"
- Affected 12 files including all setup skills, README, docs, and templates
- This was a deliberate naming decision to improve clarity for non-technical users

---

## [2026-03-24] - Daily Workflow and Permissions
`d81222d` / `ef1bb8b` / `6d619e6`

### Added
- New permissions added to `examples/settings.json`

### Changed
- Expanded `docs/daily-workflow.md` with task management guidance
- Improved `eod-gather.md`, `eod-sync.md`, and `eod-today.md` example skills
- Enhanced `connect.md` and `onboard.md` setup skills with better instructions
- Updated `docs/onboarding-guide.md` and `docs/vault-design-guide.md`
- Refined `templates/CLAUDE.md`

---

## [2026-03-23] - Setup Commands and Example Skills
`4976cf6` / `449e415`

### Added
- **Core setup skills**: `connect.md`, `finish.md`, `train.md` in `.claude/commands/`
- **Project-level `CLAUDE.md`** with bootstrap detection and setup instructions
- **Eight new example skills**:
  - `brain-dump.md`, `daily-note.md`, `eod-note.md`, `eod-sync.md`
  - `eod-time.md`, `eod-today.md`, `eod.md`, `monthly-review.md`
- `examples/scripts/md-to-gdoc.py` — Markdown-to-Google-Doc conversion script

### Changed
- Major rewrite of `onboard.md` with improved flow and file path handling
- Simplified and restructured all four docs files
- Updated `templates/.env.example` and `templates/CLAUDE.md`
- Consolidated `README.md` with clearer project overview

---

## [2026-03-20] - Onboarding Skill and Docs
`e906471`

### Added
- `.claude/commands/onboard.md` — the first setup skill (385 lines)
- `docs/onboarding-guide.md` — step-by-step onboarding reference

### Changed
- README rewritten with onboarding instructions and system overview
- Expanded `docs/integration-architecture.md` with additional integration details
- Refined `docs/vault-design-guide.md` structure
- Updated `.gitignore` and example settings files

---

## [2026-03-19] - Initial Release
`7479fd7`

### Added
- **Project scaffolding**: `.gitignore`, MIT `LICENSE`, `README.md`
- **Core documentation**:
  - `docs/daily-workflow.md` — daily usage patterns
  - `docs/integration-architecture.md` — system architecture reference
  - `docs/vault-design-guide.md` — Obsidian vault structure guide
- **Example skills**: `eod-gather.md`, `morning.md`
- **Example scripts**: `eod-cron.sh`, `eod-runner.sh`, LaunchAgent plist
- **Example settings**: `settings.json`, `settings.local.json`
- **Templates**: `.env.example`, `CLAUDE.md` template
