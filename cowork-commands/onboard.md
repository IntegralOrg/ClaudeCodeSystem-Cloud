---
name: onboard
description: Part 1 of 4 setup: permissions, user profiling, vault creation, and file customization.
---

# Onboard: Set Up Your Personal Assistant

You are setting up the Claude Code Personal Assistant system for a new user. This is Part 1 of a 4-part setup process:

1. **`/onboard`** (you are here) -- Permissions, learn about the user, build the vault and all files
2. **`/train`** -- Learn how the system works (Obsidian, vault, skills, daily loop)
3. **`/connect`** -- Connect all your tools (calendar, email, task manager, etc.)
4. **`/finish`** -- Take it for a spin, learn how to improve it over time

**Voice:** Friendly, patient, non-technical. Explain everything in plain language. Use technical terms only in parentheses after the plain version.

**Important:** Use `AskUserQuestion` for EVERY question. Present 2-4 options with descriptions. Allow free-text input only when truly necessary (like entering a name). Never dump a wall of text -- keep each step short and focused.

---

## Phase 0: Detect Environment

Before doing anything, figure out where you are running.

1. **Check if this is the repo folder or a vault.** Look for `templates/CLAUDE.md` and `docs/` in the current directory or its children.
   - If found in the current directory: you are inside the setup repo. Note the repo path. **But before assuming the vault needs to be created elsewhere, check parent directories** (up to 3 levels) for `.obsidian/` or other vault indicators (like an existing `CLAUDE.md` with vault content, `Inbox/`, `Work/`). If a parent vault is found, set `VAULT_PATH` to that parent directory and treat this like the subfolder case below (the user opened Claude inside the repo folder instead of the vault root). Only if no parent vault is found should you defer to Phase 6A.
   - If found in a subfolder (e.g., `ClaudeCodeSystem/` or `ClaudeCodeSystem-main/`): the user dropped the repo inside their vault (or a folder that will become their vault). Note the repo subfolder path. The current directory is the vault root. Set `VAULT_PATH` to the current directory immediately.

2. **Locate the reference files.** Set `REPO_PATH` to wherever `templates/CLAUDE.md` lives. All template reads, example reads, and file copies will reference this path.

3. **If the setup commands aren't at the project root yet** (i.e., you are running from a vault and the commands are in a subfolder): This means the user probably said "set me up" and Claude read this file from the repo's CLAUDE.md. The commands are already loaded. Proceed normally.

Proceed to Phase 0B.

---

## Phase 0B: Verify Windows Prerequisites (Windows only)

**Skip this phase entirely if the user is on macOS or Linux.** Detect the platform by running `uname -s` or checking for Windows-specific paths.

Windows users should have completed the prerequisite steps from the README before opening Claude (Git Bash, Developer Mode, Virtual Machine Platform, and a restart). This phase does a quick verification. Run checks silently and only surface issues.

### Verify Git
Run: `git --version 2>&1`

If Git is not found: "It looks like Git is not installed yet. The README has Windows setup steps that need to be done before we can continue. Here is the quick version:"
1. "Go to **git-scm.com** and click **Download for Windows**."
2. "Run the installer and accept all defaults."
3. "After installing, you will need to **restart your computer**, then open Claude again and type `/onboard`."

Stop here if Git is missing -- the restart is required.

### Note Windows vault default
On Windows, default the vault location to `Documents\Brain` (i.e., `C:\Users\<username>\Documents\Brain`). This will be used later in Phase 6A if the user does not specify a custom location.

**If Git is present**, proceed to Phase 1.

---

## Phase 1: Permissions

**Before permissions, determine how they use Claude.** The setup path is different in Claude Desktop vs the Claude Code CLI.

AskUserQuestion: "How are you using Claude right now?"
Options:
- Claude Desktop app (most likely if you downloaded Claude from the web)
- Claude Code in the terminal / command line
- Both

Record this as `CLAUDE_RUNTIME`.

**If Claude Desktop app:**
- Tell the user: "You are using the Desktop app, so direct tool connections (like Google Calendar or your task manager) will be set up later through the app's settings by you. I cannot configure those connections myself. I will still create your `.env` file for API-based tools and scripts."
- Skip `~/.claude/settings.json` edits unless they explicitly say they also use the CLI.

**If Claude Code CLI or Both:**
Tell the user:
"Before we get started, I need to set up permissions so I can work without asking you to approve every little thing. I am going to update your Claude Code settings file now."

**Action:** Read `~/.claude/settings.json` (it may not exist yet).

- If the file does not exist, create it with the contents from `examples/settings.json` in this repository.
- If it exists, **merge** permissions: add any missing entries from `examples/settings.json` to the existing `allow` array and `additionalDirectories` array without removing anything. Preserve any other settings (like `mcpServers`).

After writing: "Done. Permissions are set. You will not see approval prompts during setup."

---

Give a brief welcome:
- What this system does (2-3 sentences, plain language: "I am going to build you a personal assistant that lives in a notes folder on your computer. It connects to your calendar, email, and task manager, and runs daily routines to keep you organized.")
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
- In my Documents folder (~/Documents/Brain on Mac/Linux, Documents\Brain on Windows)
- On my Desktop (~/Desktop/Brain)
- Next to this repo (../Brain)
- Somewhere else (let me specify)

On Windows, default to `C:\Users\<username>\Documents\Brain` if they choose Documents.

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
- Replace `[Claude Runtime]` with `Claude Desktop`, `Claude Code CLI`, or `Both`
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

If `CLAUDE_RUNTIME` includes CLI, write `VAULT_PATH/.claude/settings.local.json` using `examples/settings.local.json` as the base.

If `CLAUDE_RUNTIME` includes CLI, update `~/.claude/settings.json` to add any MCP permissions for tools they selected that are not already in the allow list.

If `CLAUDE_RUNTIME` is Desktop only, skip CLI-specific settings files and note in the summary that integrations will be configured later in the app's **Customize** section instead.

### 6E: Skills

**The skill installation path depends on `CLAUDE_RUNTIME`:**

#### If CLI or Both: Auto-Install Skills

Create skills in `VAULT_PATH/.claude/commands/`:

Based on workflow preferences:
- If they chose morning review -> `morning.md` based on `examples/commands/morning.md`
- If they chose full EOD processing -> `eod.md` based on `examples/commands/eod.md` (customize sections to their tools; skip time tracking if they do not use a time tracker)
- If they chose simple daily note -> `daily-note.md`
- If they chose manual brain dump -> `brain-dump.md`

Customize skill content with their specific tools, clients, and schedule.

**Also copy these setup skills** into `VAULT_PATH/.claude/commands/`:
- `train.md` (from this repo's `.claude/commands/train.md`)
- `connect.md` (from this repo's `.claude/commands/connect.md`)
- `finish.md` (from this repo's `.claude/commands/finish.md`)

**Always copy these Integral skills** (every user gets these):
- `strategy.md` (from this repo's `.claude/commands/strategy.md`) -- structured decision-making framework
- `optimize.md` (from this repo's `.claude/commands/optimize.md`) -- audit and improve existing tools/processes
- `build-skill.md` (from this repo's `.claude/commands/build-skill.md`) -- turn a successful task into a repeatable skill
- `learn.md` (from this repo's `.claude/commands/learn.md`) -- capture and integrate new knowledge into the vault

**Copy these graph maintenance skills:**
- `graph-sync.md` (from this repo's `.claude/commands/graph-sync.md`) -- full vault knowledge graph rebuild
- `graph-daily.md` (from this repo's `.claude/commands/graph-daily.md`) -- daily incremental graph sync

**Always copy these session-continuity skills** (every user gets these -- they are core, not optional):
- `handoff.md` (from this repo's `.claude/commands/handoff.md`) -- save the current work state to a named briefing file so a fresh session can pick it up cold
- `pickup.md` (from this repo's `.claude/commands/pickup.md`) -- resume from a named handoff: load the listed context and report where we left off

These two are the backbone of context and task management. A single Claude session has a finite context window; once it fills up (or the user runs `/clear`, closes the window, or hits compaction), everything not written down is lost. `/handoff` checkpoints the live thread of work into `VAULT_PATH/.claude/handoffs/<name>.md` -- the goal, what's been done, what was tried and rejected, the exact next steps, and which files/commands to reload. `/pickup` reads that file in the next session and re-establishes shared context in seconds instead of the user re-explaining everything. Because each handoff is a named, persistent file in the vault, they also double as a track record of in-flight workstreams. **Install both for every user**, exactly like the setup and Integral skills above.

**Copy these other pre-built utility commands** from `examples/commands/` into `VAULT_PATH/.claude/commands/`:
- `monthly-review.md` -- periodic system health check and vault cleanup

Also create the handoff storage directory: `VAULT_PATH/.claude/handoffs/` (the `/handoff` command stores named handoff files here).

**Install the Brainstorming community skill:**

Run this command in the vault directory:
```
npx skills add https://github.com/obra/superpowers --skill brainstorming
```

This installs an interactive brainstorming skill that helps users think through ideas, problems, and creative challenges. It works like the strategy skills but is focused on generative thinking rather than structured decision-making.

If the install fails (e.g., Node.js is not available), note it as a task in `Inbox/[YourCompany].md` for later and continue. Do not block setup on this.

If the user chose full EOD processing, the daily graph sync is already included as Phase 6 of `/eod`. The standalone `/graph-daily` is available for manual runs.

#### If Desktop Only (CoWork): Manual Skill Upload

Claude CoWork does not auto-discover `.claude/commands/` files. Skills must be uploaded manually by the user through the **Customize** section in the CoWork app settings. Each skill file needs YAML frontmatter to be recognized.

**Still copy skills to `VAULT_PATH/.claude/commands/`** (the CLI versions serve as the source of truth and work if the user later adopts the CLI). But also walk the user through uploading their core skills to CoWork:

1. Tell the user: "Skills in CoWork work a little differently than in the CLI. You need to upload each one through the app. I will walk you through it."

2. Copy the CoWork-formatted skill files from `cowork-commands/` in this repo to `VAULT_PATH/cowork-commands/` so the user has them locally:
   - Copy all `.md` files from `REPO_PATH/cowork-commands/` to `VAULT_PATH/cowork-commands/`

3. Walk through uploading the essential skills first. Use AskUserQuestion at each step:
   - "Open the CoWork app settings. Look for the **Customize** section."
   - "Find the option to add a custom skill or instruction. Click it."
   - "Upload the file from your vault at `cowork-commands/morning.md` (or paste its contents)."
   - Confirm: "Does it show up as an available skill?"

4. Prioritize these skills for initial upload (the user can add more later):
   - `morning.md` -- daily driver
   - `eod.md` -- daily driver
   - `strategy.md` -- most useful on-demand skill
   - `handoff.md` + `pickup.md` -- session continuity
   - `train.md`, `connect.md`, `finish.md` -- needed to continue setup

5. Note remaining skills as a task: "You have [N] more skills available in `cowork-commands/`. Upload them through **Customize** whenever you want to add more."

6. Add a note in CLAUDE.md under Available Integrations or a new Skills section: "CoWork skills are uploaded through the **Customize** section. Source files with YAML frontmatter are in `cowork-commands/`. To add a new skill, upload the file from that folder."

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

"Your notes folder is built and your instruction manual is customized. Before we continue, open a fresh Claude session in your vault so it picks up your new files. If you are using the CLI, restarting also picks up your new permissions."

Walk them through it step by step:

1. "Open Obsidian. If you have not installed it yet, download it from obsidian.md."
2. "In Obsidian, make sure your vault is the folder at [vault_path]. If this is a brand new setup, choose **Open folder as vault** and pick that folder. If you were already in an existing vault, you can stay right where you are."
3. "You should see your folder structure in the left sidebar. Take a moment to click around -- these are all just text files."

AskUserQuestion: "Can you see your folders in Obsidian?"
Options:
- Yes, I can see Inbox, Work, Resources, etc.
- I need help installing Obsidian first
- Something does not look right

4. Walk through the session handoff explicitly. This is a common sticking point, so be very literal:

   If `CLAUDE_RUNTIME` is Desktop:
   - "Here is exactly what to do next. I will walk you through it one step at a time."
   - "Step 1: Close this conversation. Click the X or use the menu to close it."
   - "Step 2: In Claude Desktop, start a brand new conversation."
   - "Step 3: In the new conversation, click the paperclip or attachment icon and add your vault folder: **[vault_path]**"
   - "Step 4: Once your vault is attached, type exactly this into the chat: `/train`"
   - "That is it. `/train` is the next step and it will walk you through how the system works."

   If `CLAUDE_RUNTIME` includes CLI:
   - "Here is exactly what to do next. I will walk you through it one step at a time."
   - "Step 1: Close this session. You can type `/exit` or press Ctrl+C."
   - "Step 2: In your terminal, copy and paste this exact command:"
     ```
     cd [vault_path] && claude
     ```
   - "Step 3: Once the new session opens, type exactly this: `/train`"
   - "That is it. `/train` is the next step and it will walk you through how the system works."

   AskUserQuestion: "Do you know what to do next?"
   Options:
   - Yes, close this and open a new session in my vault, then type /train
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
