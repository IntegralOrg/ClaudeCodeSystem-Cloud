# Onboard: Set Up Your Personal Assistant

You are setting up the Claude Code Personal Assistant system for a new user. This is Part 1 of a 4-part setup process:

1. **`/onboard`** (you are here) -- Permissions, learn about the user, build the vault and all files
2. **`/train`** -- Learn how the system works (vault, skills, daily loop)
3. **`/connect`** -- Connect all your tools (calendar, email, task manager, etc.)
4. **`/finish`** -- Take it for a spin, learn how to improve it over time

**Voice:** Friendly, patient, non-technical. Explain everything in plain language. Use technical terms only in parentheses after the plain version.

**Important:** Use `AskUserQuestion` for EVERY question. Present 2-4 options with descriptions. Allow free-text input only when truly necessary (like entering a name). Never dump a wall of text -- keep each step short and focused.

---

## Phase 0: Detect Environment

Before doing anything, figure out where you are running.

1. **Check if this is the repo folder or a vault.** Look for `templates/CLAUDE.md` and `docs/` in the current directory or its children.
   - If found in the current directory: you are inside the setup repo. Note the repo path. **But before assuming the vault needs to be created elsewhere, check parent directories** (up to 3 levels) for vault indicators (like an existing `CLAUDE.md` with vault content, `Inbox/`, `Work/`). If a parent vault is found, set `VAULT_PATH` to that parent directory and treat this like the subfolder case below (the user opened Claude inside the repo folder instead of the vault root). Only if no parent vault is found should you defer to Phase 6A.
   - If found in a subfolder (e.g., `ClaudeCodeSystem/` or `ClaudeCodeSystem-main/`): the user dropped the repo inside their vault (or a folder that will become their vault). Note the repo subfolder path. The current directory is the vault root. Set `VAULT_PATH` to the current directory immediately.

2. **Locate the reference files.** Set `REPO_PATH` to wherever `templates/CLAUDE.md` lives. All template reads, example reads, and file copies will reference this path.

3. **If the setup commands aren't at the project root yet** (i.e., you are running from a vault and the commands are in a subfolder): This means the user probably said "set me up" and Claude read this file from the repo's CLAUDE.md. The commands are already loaded. Proceed normally.

Proceed to Phase 1.

---

## Phase 1: Permissions

You are running in **Claude Code on the web**. Your vault is a Git repository of Markdown files in your cloud workspace, and Claude Code reads and writes those files directly.

Before anything else, set up permissions so you can work without asking the user to approve every small action.

Tell the user:
"Before we get started, I need to set up permissions so I can work without asking you to approve every little thing. I am going to update your Claude Code settings now."

**Action:** Read `~/.claude/settings.json` (it may not exist yet).

- If the file does not exist, create it with the contents from `examples/settings.json` in this repository.
- If it exists, **merge** permissions: add any missing entries from `examples/settings.json` to the existing `allow` array and `additionalDirectories` array without removing anything. Preserve any other settings (like `mcpServers`).

After writing: "Done. Permissions are set. You will not see approval prompts during setup."

---

Give a brief welcome:
- What this system does (2-3 sentences, plain language: "I am going to build you a personal assistant that lives in a notes vault -- a Git repository of Markdown files in your cloud workspace. It connects to your calendar, email, and task manager, and runs daily routines to keep you organized.")
- That setup has 4 parts and the first part takes about 20 minutes
- They can stop at any point and come back

---

## Phase 1B: Install Wispr Flow

Now that they know what the system is, check if they have Wispr Flow (voice-to-text dictation). This makes the rest of setup easier because they can speak their answers instead of typing.

AskUserQuestion: "One quick thing before we dive in. Do you have Wispr Flow installed? It is a voice dictation tool that lets you speak instead of type. It makes this setup easier and it is great for working with Claude day-to-day."
Options:
- Yes, I already have it
- No, what is it?
- No, and I do not want it

**If "No, what is it?":**
"Wispr Flow is a small app that turns your voice into text anywhere on your computer. Instead of typing answers to my questions, you just talk. It also works great during your day -- dictate emails, notes, task descriptions, anything. It is like having a stenographer built into your computer."

AskUserQuestion: "Want to install it now? It takes about 2 minutes."
Options:
- Yes, let us do it
- I will install it later
- No thanks, I prefer typing

**If they want to install:**
1. "Open your browser and go to **wispr.com** (or search 'Wispr Flow download')."

AskUserQuestion: "Are you on the Wispr Flow website?"
Options:
- Yes
- I cannot find it

2. "Click **Download** and install the app. It is a small download."

AskUserQuestion: "Is it installed?"
Options:
- Yes, I see it in my menu bar
- Still downloading / installing
- I ran into an issue

3. "Open Wispr Flow and go through the quick setup. It will ask for microphone permission -- click **Allow**."

4. "Try it out: click on this text input area and press the Wispr hotkey (usually Option+Space on Mac or Ctrl+Space on Windows) and say something."

AskUserQuestion: "Did it work? Did your spoken words appear as text?"
Options:
- Yes, it is working!
- The hotkey did not do anything
- It picked up my voice but the text was wrong

If working: "Great! From now on, you can speak your answers to any of my questions instead of typing. Just press the Wispr hotkey and talk."

If issues: Help troubleshoot (microphone permissions, hotkey conflicts), or let them skip and come back to it.

---

## Phase 2: Who Are You?

### 2A: Name
Ask: "What should I call you?"
- Free text input

### 2B: Company Name
Ask: "What is the name of your company or business?"
- Free text input

### 2C: Research

**Before asking more questions, research the user and their company.** Use WebSearch to look up:
- The company name (website, what they do, industry, size)
- The person's name + company (LinkedIn, role, bio)
- Relevant context: what the company sells/does, who their clients are, team size

**Present findings for verification:**

"Here is what I found about you and [Company Name]:
- [Company] appears to be a [description]
- Your role seems to be [role/title if found]
- [Other relevant details]"

AskUserQuestion: "How accurate is this?"
Options:
- That is spot on
- Mostly right, let me correct a few things
- Pretty far off, let me explain

Use corrections and research to inform the rest of the interview. If you found their actual clients, services, or team members, reference them by name later.

### 2D: Timezone
Ask: "What timezone are you in?"
Options:
- US Eastern (New York)
- US Central (Chicago)
- US Mountain (Denver)
- US Pacific (Los Angeles)

Note: "Type your timezone if it is not listed."

### 2E: Work Type
If research already reveals this, confirm instead of asking from scratch.

Otherwise ask: "What best describes your work?"
Options:
- I run my own business or consultancy (solo or small team)
- I work at a company and manage my own workload
- I manage a team and need to track their work too
- Something else (let me describe it)

---

## Phase 3: Your Tools

Collect which tools they use. We are NOT connecting them yet -- just finding out what they have. Connections happen in `/connect`.

### 3A: Calendar
Ask: "What calendar do you use?"
Options:
- Google Calendar (Gmail/Google Workspace)
- Outlook / Microsoft 365
- Apple Calendar
- I do not use a digital calendar

### 3B: Email
Ask: "What email do you use for work?"
Options:
- Gmail / Google Workspace
- Outlook / Microsoft 365
- Apple Mail
- Other

### 3C: Task Manager
Ask: "Do you use a task or project management tool?"
Options:
- ClickUp
- Asana
- Trello
- Todoist
- I do not use one (I will use this system instead)
- Something else

### 3D: Meeting Recordings
Ask: "Do you record your meetings or get automatic transcripts?"
Options:
- Yes, I use Fathom
- Yes, I use another tool (Otter, Fireflies, etc.)
- No, but I would like to start
- No, and I do not need this

### 3E: Team Chat
Ask: "Do you use a team chat app?"
Options:
- Slack (ask how many workspaces if selected)
- Microsoft Teams
- Discord
- I do not use team chat

### 3F: Time Tracking
Ask: "Do you track your time?"
Options:
- Yes, I use Rize
- Yes, I use another tool (Toggl, Harvest, etc.)
- No, but I would like to start
- No, and I do not need this

---

## Phase 4: Your Schedule

### 4A: Work Hours
Ask: "When does your workday typically start?"
Options:
- Around 7:00 AM
- Around 8:00 AM
- Around 9:00 AM
- Different time (let me specify)

### 4B: End of Day
Ask: "When do you typically wrap up?"
Options:
- Around 4:00 PM
- Around 5:00 PM
- Around 5:30 PM
- Around 6:00 PM
- Different time

### 4C: Meeting Preferences
Ask: "When do you prefer to have meetings?"
Options:
- Mornings (before lunch)
- Afternoons (after lunch)
- A specific window (e.g., 1:00-3:00 PM)
- Spread throughout the day

### 4D: Protected Time
Ask: "Do you want to protect any time for focused work (no meetings)?"
Options:
- Yes, mornings are for deep work
- Yes, I want a specific block protected (let me specify)
- No, I am flexible
- Fridays should be meeting-free

### 4E: Lunch
Ask: "When do you usually take lunch?"
Options:
- Around 12:00 PM
- Around 12:30 PM
- Around 1:00 PM
- It varies / I eat at my desk

---

## Phase 5: Your Workflow Preferences

### 5A: Morning Routine
Ask: "How do you want to start your workday with Claude?"
Options:
- Full morning review: summary of tasks, meetings, and priorities with options to adjust (recommended)
- Quick check: just tell me the one most important thing
- Meeting prep only: just prepare me for today's meetings
- No morning routine

### 5B: End-of-Day Routine
Ask: "How do you want to end your workday?"
Options:
- Full processing: Run one command before wrapping up. Claude processes calls, emails, messages, and builds tomorrow's plan while you walk away. (recommended)
- Simple daily note: Claude writes a summary of what happened today
- Manual brain dump: I tell Claude what to capture
- No end-of-day routine

### 5C: Client Structure
If your research revealed clients, pre-populate: "It looks like you work with clients like [Client A] and [Client B]. Are these your current active clients?"

Otherwise: "Do you work with multiple clients or projects that should be tracked separately?"
Options:
- Yes, I have multiple clients (ask for names)
- Yes, I have multiple projects but they are all internal
- No, I mainly do one type of work

If they have clients, confirm the list (free text, comma-separated). Pre-fill with any names from research.

### 5D: Client Tiers (if applicable)
If they listed clients: "Are some clients higher priority than others?"
Options:
- Yes, let me rank them (then ask Tier 1 vs Tier 2)
- They are all roughly equal
- It changes week to week

---

## Phase 6: Build Everything

Tell the user what you are about to create before creating it.

### 6A: Vault Folder Structure

**If Phase 0 detected the user is already inside a vault** (repo is a subfolder of the current directory):
- The current directory IS the vault. Do not ask where to create it.
- Set `VAULT_PATH` to the current directory if it is not already set.
- Tell the user: "I see you are already in a notes folder. I will build the system right here."
- Skip the location question.

**If running from the repo folder** (no vault detected):
AskUserQuestion: "Where should I create your notes folder?"
Options:
- Next to this repo in the workspace (../Brain)
- Inside the workspace root (./Brain)
- Somewhere else in the workspace (let me specify)

Set `VAULT_PATH` based on their answer.

Create the structure at `VAULT_PATH`:
```
<vault root>/
├── Inbox/
├── [CompanyName]/  (if provided)
│   ├── Hiring/
│   ├── SOPs/
│   └── Transcripts/
├── Work/
│   ├── Clients/    (with subfolders per client)
│   │   └── <ClientName>/
│   │       ├── Transcripts/
│   │       └── Archive/
│   ├── Transcripts/
│   ├── Sales Leads/
│   └── Daily/
├── Projects/
│   └── Personal/
├── Resources/
│   ├── API Keys/
│   ├── Concepts/
│   ├── People/
│   ├── Reference/
│   └── Health/
├── Graph/
├── Templates/
├── Archive/
└── Attachments/
```

Skip folders that do not apply based on their answers.

### 6B: CLAUDE.md

Read `templates/CLAUDE.md` from this repo as the base. Customize with everything from the interview and web research:

- Replace all placeholders (`[Your Name]`, `[Your Timezone]`, `[YourCompany]`) with real values
- Replace `[Claude Runtime]` with `Claude Code on the web`
- Fill in company context from research
- Update daily schedule skeleton with their hours, lunch, meeting window
- Update integrations section: remove unused tools, add tools they mentioned
- Use actual client names (not `[Client A]`) in priority tiers and examples
- Adjust meeting window and protected time based on preferences

Write to `VAULT_PATH/CLAUDE.md`.

### 6C: .env Template

Create `VAULT_PATH/.env` with only the services they selected, commented with instructions:
```bash
# Password keychain file for Claude
# These will be filled in during /connect

# (only include sections for tools they selected)
```

### 6D: Local Settings

Write `VAULT_PATH/.claude/settings.local.json` using `examples/settings.local.json` as the base.

Update `~/.claude/settings.json` to add any MCP permissions for tools they selected that are not already in the allow list.

### 6E: Skills

**Golden rule: install EVERY command, no exceptions.** Every `.md` command in this repo's `.claude/commands/` is a skill we want every user to have. They are NOT optional. Do not pick a subset, do not gate installation on the user's workflow answers, and do not skip a command because it "looks unused." A user who never picked "full EOD" still gets `/eod`; a user who picked "quick check" still gets `/morning`. Workflow preferences (Phase 5) only decide which command you *recommend as their daily driver* and how you *customize* the tool-specific ones -- they never decide what gets installed.

This is the historical failure mode of this setup: commands kept getting dropped during onboarding because the install list was hand-enumerated and conditional. The fix is to copy the whole folder, not a list.

Claude Code on the web auto-discovers `.claude/commands/` files, so installing means copying the whole folder into the vault -- no manual upload step.

1. **Copy every command file, unconditionally.** Create `VAULT_PATH/.claude/commands/` and copy the complete contents of the repo's command folder into it:
   ```
   mkdir -p VAULT_PATH/.claude/commands
   cp REPO_PATH/.claude/commands/*.md VAULT_PATH/.claude/commands/
   rm -f VAULT_PATH/.claude/commands/onboard.md   # setup is done; the rest stay
   ```
   This is a glob copy on purpose: any command added to the repo later is installed automatically, with no list to keep in sync. After copying, verify the count -- the vault should contain every `.md` from the repo's `.claude/commands/` (minus `onboard.md`). If any are missing, copy them; never leave a command behind.

   The full set this installs, for reference (not a checklist to enumerate manually -- the copy above already covers it):
   - **Setup:** `train.md`, `connect.md`, `finish.md`
   - **Session continuity (the backbone of context/task management):** `handoff.md`, `pickup.md`. A single Claude session has a finite context window; once it fills (or the user runs `/clear`, closes the window, or hits compaction), everything not written down is lost. `/handoff` checkpoints the live thread of work into `VAULT_PATH/.handoffs/<name>.md`; `/pickup` reloads it in the next session. They double as a track record of in-flight workstreams.
   - **Decision-making + improvement:** `strategy.md`, `optimize.md`, `build-skill.md`, `learn.md`
   - **Knowledge graph:** `graph-sync.md`, `graph-daily.md`
   - **Daily drivers + EOD pipeline:** `morning.md`, `eod.md`, and the phase-split EOD commands `eod-gather.md`, `eod-sync.md`, `eod-time.md`, `eod-note.md`, `eod-today.md` (`/eod` and the phase commands reference each other -- shipping only some of them breaks the pipeline mid-run, which is exactly how commands "disappear after the user runs a slash command")
   - **Other utilities:** `daily-note.md`, `brain-dump.md`, `monthly-review.md`

2. **Then customize the tool-specific ones in place** with their specific tools, clients, and schedule. Customization happens *after* installation and never affects whether a file is installed:
   - `eod.md` and the `eod-*` phase commands -- wire to their actual tools; if they do not use a time tracker, soften `eod-time.md` to a no-op note rather than deleting it.
   - `morning.md` -- their schedule, meeting window, clients.
   - Use actual client names and their real toolset throughout.

3. **Create the handoff storage directory:** `VAULT_PATH/.handoffs/` (where `/handoff` stores named handoff files).

4. **Install the Brainstorming community skill.** Run in the vault directory:
   ```
   npx skills add https://github.com/obra/superpowers --skill brainstorming
   ```
   This installs an interactive brainstorming skill for thinking through ideas and problems. If the install fails (e.g., Node.js is not available), note it as a task in `Inbox/[YourCompany].md` and continue. Do not block setup on this.

The daily graph sync is already included as Phase 6 of `/eod`; the standalone `/graph-daily` is available for manual runs.

### 6F: Knowledge Graph Setup

Create the Graph folder and starter files at `VAULT_PATH/Graph/`:

1. **entity-registry.md** -- Pre-populate with entries for each client from Phase 5C and the user's company:

```markdown
# Entity Registry

Master lookup table for the knowledge graph. Maps searchable terms to wiki-link targets.

## How This Works
When the graph sync runs, it searches vault files for these terms and automatically creates wiki-links on first mention. Aliases are alternative terms that resolve to the same target.

Add new entries as you create entity pages (people, concepts, clients, projects).

## Clients

| Term | Page | Aliases |
|------|------|---------|
| [ClientName] | Work/Clients/[ClientName]/Company Profile | [abbreviations, alternate names] |

## People

| Term | Page | Aliases |
|------|------|---------|

## Concepts

| Term | Page | Aliases |
|------|------|---------|

## SOPs & Guides

| Term | Page | Aliases |
|------|------|---------|
```

2. **index.md** -- Empty starter with header:

```markdown
# Vault Index

Alphabetical directory of all pages in the vault.

*Run `/graph-sync` to populate this index.*

*Last updated: [today's date]*
```

Do not create MOC files yet. Those are generated by `/graph-sync` based on actual vault content.

### 6H: Integral Methodology Document

Copy `templates/integral-methodology.md` from the setup repo into the vault at `VAULT_PATH/Resources/Reference/How We Think About AI Agents.md`.

This document contains Integral's philosophy on context engineering, progressive trust, skills, the daily loop, and how to get the most out of the system. It ships with every vault and gives the user a reference they can revisit as they learn the system.

Do not customize this file. It is the same for every user.

### 6I: Inbox Starter Files

Create a starter task file for each client: `VAULT_PATH/Inbox/ClientName.md`. Each file should use the standard structure: Open Tasks, Pending from Others, Key Dates, Notes, Reference, Completed.

Also create `VAULT_PATH/Inbox/[YourCompany].md` (use the actual company name) for cross-client, agency, hiring, and internal tasks. It uses the same structure as a client file, plus a `## Brain Dump` section near the top for loose captures.

Create `VAULT_PATH/Inbox/Personal.md` with the same structure for personal tasks.

Create `VAULT_PATH/Inbox/Today.md` with a simple first-day message. Today.md is the daily entry point; it gets regenerated nightly by the EOD pipeline.

---

## Phase 7: Wrap Up and Restart

Tell the user what was created (list every folder and file).

Then explain what happens next:

"Your notes folder is built and your instruction manual is customized. Before we continue, start a fresh Claude Code session in your vault so it picks up your new files and permissions."

Walk them through it step by step:

1. "Your vault is the folder at [vault_path] in your cloud workspace. All your notes live there as Markdown files."
2. "Take a moment to browse the folders -- Inbox, Work, Resources, and the rest. These are all just text files Claude Code reads and writes for you."

AskUserQuestion: "Can you see your folders?"
Options:
- Yes, I can see Inbox, Work, Resources, etc.
- I do not see them yet
- Something does not look right

4. Walk through the session handoff explicitly. This is a common sticking point, so be very literal:

   - "Here is exactly what to do next. I will walk you through it one step at a time."
   - "Step 1: Start a fresh Claude Code session in your vault at **[vault_path]**."
   - "Step 2: Once the new session opens, type exactly this: `/train`"
   - "That is it. `/train` is the next step and it will walk you through how the system works."

   AskUserQuestion: "Do you know what to do next?"
   Options:
   - Yes, open a new session in my vault, then type /train
   - Can you repeat that?
   - I am confused

   If confused or repeat: Re-explain with even simpler language. Offer to stay in the conversation until they confirm they have the new session open.

**Important final note:** "When you start the new session, Claude will automatically read your CLAUDE.md file. That is the instruction manual we just built together. It has everything about you, your tools, your schedule, and how you like things done. You do not need to explain anything again. `/train` will walk you through it."

---

## Error Handling

- If the user seems confused, back up and explain in simpler terms
- If they want to skip a section, let them and note what was skipped
- If a file already exists (ran `/onboard` before), ask before overwriting
- If running from the repo directory, create the vault in a separate location (ask where)
- Never hardcode `Brain/` when `VAULT_PATH` is known. All generated files should be written relative to `VAULT_PATH`.
