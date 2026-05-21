# Onboarding Guide: Setting Up Your Personal Assistant

This guide is a reference for what the setup process covers. **You do not need to follow these steps manually.** Instead, open Claude Code in the repository folder and type:

```
/onboard
```

Claude will interview you using a friendly question-and-answer format with selectable options (no typing required for most questions). It will first ask whether you are using the Claude Desktop app or the Claude Code CLI, then ask about your name, tools, schedule, and preferences, and build everything for you in about 20 minutes.

The setup has 4 parts:

| Step | Command | What It Does | Time |
|------|---------|-------------|------|
| 1 | `/onboard` | Detect Desktop vs CLI, learn about you, build your notes folder and files | ~20 min |
| 2 | `/train` | Walk through Obsidian, your vault, skills, and the daily loop | ~15 min |
| 3 | `/connect` | Connect each of your tools (calendar, email, tasks, etc.) one by one | ~20 min |
| 4 | `/finish` | Live demo with real data, improvement tips, how to maximize the system | ~10 min |

The steps below explain what each part sets up, so you can understand what each piece does or make changes later.

**What you will need:**
- A Mac or PC
- [Obsidian](https://obsidian.md) (free)
- A [Claude Max subscription](https://claude.ai) ($100/month -- includes Claude Code)

**Windows users -- do these steps before opening Claude for the first time:**
1. Create a **Brain** folder in your Documents folder
2. **Enable Developer Mode** -- Settings > System > For developers
3. **Install Git Bash** -- Download from [git-scm.com](https://git-scm.com), accept all defaults
4. **Install Claude** -- Download from [claude.ai/download](https://claude.ai/download). Open it once and let it install **Virtual Machine Platform** (a Windows component it needs)
5. **Restart your computer** -- One restart covers Git, Developer Mode, and Virtual Machine Platform
6. Open Claude, navigate to this folder, and type `/onboard`

These must be done before `/onboard` because Claude Code cannot run properly without them.

**What you are building:** A personal assistant that lives in your notes folder. It reads your calendar, processes your email, tracks your tasks, and builds tomorrow's plan while you sleep. By the end of all 4 steps, you will have a working daily system.

---

## Step 1: Pick Your Claude Interface

The setup works in two environments:
- **Claude Desktop app** -- most likely if you downloaded Claude from the web and use the app UI
- **Claude Code CLI** -- if you opened Terminal and ran `claude`
- **Both** -- if you move between the app and terminal

This matters because built-in integrations are configured differently:
- **Desktop** -- use the app's **Customize** section in settings
- **CLI** -- use Claude Code settings files
- **Both** -- use the **Customize** section for Desktop, and only add CLI config for tools you need in terminal sessions

Claude asks this during `/onboard` and records it in your CLAUDE.md so later setup steps know which path to use.

## Step 2: Give Claude Permission to Help You

Before Claude can do anything, it needs permission to read and write files, run commands, and connect to your tools. There are two permission files: one for global settings (applies everywhere) and one for local settings (applies only inside your notes folder).

**Important:** the settings-file path below is for CLI users only. If you are using Claude Desktop or CoWork, direct connections (MCP servers) can only be configured by you through the app's UI -- Claude cannot set these up itself. `.env` still works in both environments for API-based tools and scripts.

### Global Settings

This file lives at `~/.claude/settings.json` (your home folder, inside the `.claude` folder). It controls what Claude can do everywhere on your computer.

Copy and paste this into the file:

```json
{
  "permissions": {
    "allow": [
      "Read",
      "LS",
      "Glob",
      "Grep",
      "Edit",
      "Write",
      "NotebookEdit",
      "Bash(*)",
      "WebSearch",
      "mcp__context7__*"
    ],
    "additionalDirectories": [
      "/private/tmp",
      "$HOME/Desktop",
      "$HOME/Downloads",
      "$HOME/Library/LaunchAgents",
      "$HOME/scripts"
    ]
  },
  "alwaysThinkingEnabled": true,
  "effortLevel": "high"
}
```

**What each permission means:**

| Permission | What it allows |
|---|---|
| `Read` | Claude can read files on your computer |
| `LS` | Claude can list folders on your computer |
| `Glob` | Claude can find files by name or pattern |
| `Grep` | Claude can search file contents on your computer |
| `Edit` | Claude can make changes to existing files |
| `Write` | Claude can create new files |
| `NotebookEdit` | Claude can work with notebook files |
| `Bash(*)` | Claude can run terminal commands |
| `WebSearch` | Claude can search the web for current information |
| `mcp__context7__*` | Claude can look up documentation |

**Adding more tools:** This is mainly for CLI users. Each tool Claude connects to needs its own permission line. When you run `/connect`, Claude will add these automatically for the CLI path. The pattern is always `mcp__` followed by the tool name and `__*`. For example, if you connect ClickUp, Claude adds `"mcp__clickup__*"` to the allow list. If you connect Claude to Gmail or Google Calendar through Claude.ai, CLI users add lines like `"mcp__claude_ai_Gmail__*"` and `"mcp__claude_ai_Google_Calendar__*"` to the allow list. Desktop users do not need to manage this manually for integrations added through the **Customize** section.

**Additional directories** are folders outside your notes folder that Claude can access. The defaults cover your Desktop, Downloads, temporary files, scheduled tasks, and scripts.

### Local Settings

This file lives at `.claude/settings.local.json` inside your notes folder (the vault). It controls what Claude can do when working in that specific folder.

Copy and paste this into the file:

```json
{
  "permissions": {
    "allow": [
      "Bash(*)",
      "Read(/tmp/**)",
      "WebSearch",
      "WebFetch(*)"
    ]
  }
}
```

**What each permission means:**

| Permission | What it allows |
|---|---|
| `Bash(*)` | Claude can run terminal commands |
| `Read(/tmp/**)` | Claude can read temporary files |
| `WebSearch` | Claude can search the web for current information |
| `WebFetch(*)` | Claude can visit web pages to get information |

You do not need to duplicate permissions from the global file here. The global settings already cover file reading, editing, writing, and tool connections.

---

## Step 3: Install Obsidian and Create Your Notes Folder

Obsidian is a notes app where your notes live on your computer as plain text files instead of on someone else's server. Claude can read files on your computer instantly, which makes Obsidian a perfect workspace.

### Download and Install

1. Go to [obsidian.md](https://obsidian.md) and download the app for your computer
2. Install and open it
3. Choose **"Create new vault"**
4. Name it something like **"Brain"** (or whatever you prefer)
5. Choose where to save it (your Documents folder works fine)

### Create Your Starter Folders

Inside your new notes folder, create these three folders:

```
Brain/
├── Inbox/       (where new items go)
├── Work/        (professional projects)
└── Resources/   (reference material)
```

You can create more folders later. These three are enough to start.

For a detailed guide on folder structure and how everything fits together, see the [Vault Design Guide](vault-design-guide.md).

---

## Step 4: Create Claude's Instruction Manual

The instruction manual (called `CLAUDE.md`) is the most important file in the system. Claude reads it every session to know how you want things done.

1. Copy the template from `templates/CLAUDE.md` in this repository
2. Paste it into a new file called `CLAUDE.md` at the root of your notes folder
3. Customize it:
   - Replace `[Your Name]` with your name
   - Replace `[Your Timezone]` with your timezone
   - Replace `[YourCompany]` with your company name (or remove those sections if not applicable)
   - Update the client list and priority tiers to match your situation
   - Adjust the daily schedule skeleton to match your routine

**You do not need to fill in everything right now.** Start with your name, timezone, and daily schedule. Add integrations and workflows as you connect tools.

The template includes sections for:
- **What Claude should do first** every session (startup checklist)
- **Where things go** in your notes folder (quick reference)
- **What tools are connected** (integrations)
- **How Claude should behave** (guidelines and preferences)
- **Common workflows** (step-by-step routines)

---

## Step 5: Connect Your Tools (`/connect`)

The `/connect` command walks you through connecting each tool one by one, testing each connection with real data before moving on. It uses a different strategy depending on whether you are on Desktop or CLI.

**Recommended first connections:**
- **Google Calendar** -- Know what is coming tomorrow, create time blocks
- **Your task manager** (ClickUp, Asana, Todoist, etc.) -- Track and update tasks
- **Gmail** -- Surface emails needing responses

For Google services, `/connect` offers two paths:
- **Easy way:** Sign in through Claude.ai's settings page (2 minutes, no technical setup)
- **Full control way:** Use the `gws` CLI to set up Google access (recommended for custom Google Drive/Docs workflows). Cloud Console is the fallback if the CLI is unavailable.

For other built-in integrations:
- **Desktop users** add them through the **Customize** section in settings
- **CLI users** can use local Claude Code config where supported
- **Both** can do both, but only if they need the integration in both places

See [Integration Architecture](integration-architecture.md) for the full technical reference on how each tool connects, including credential types and API details.

---

## Step 6: Learn the System (`/train`)

The `/train` command gives you a guided tour of everything `/onboard` built: your folder structure, CLAUDE.md instruction manual, skills, and the daily loop. It takes about 15 minutes and is designed as a show-and-tell (not a lecture).

Key things you will learn:
- What each folder is for
- How CLAUDE.md works and how to edit it
- How skills work (they are just text files)
- The daily loop: EOD processing, morning review, day, repeat

---

## Step 7: Take It for a Spin (`/finish`)

The `/finish` command is the payoff. Claude pulls real data from your connected tools and shows you the system working:

- Tomorrow's calendar and schedule
- Emails needing attention
- Open tasks from your task manager
- Meeting prep for upcoming calls
- A generated plan for tomorrow (`Inbox/Today.md`)

It also covers:
- How to add rules when Claude makes a mistake
- How to turn successful tasks into skills
- The monthly review process
- Power tips specific to your setup

---

## What a Typical Day Looks Like

### The Night Before

If you ran `/eod` the day before, Claude has already processed your calls, emails, and messages and built today's plan in `Inbox/Today.md`.

If you did not run `/eod` yet, you can run it now, or start fresh and run it tonight.

### Morning (5 minutes)

1. Open Obsidian and read `Inbox/Today.md`
2. Open Claude Code in your notes folder
3. Type `/morning`
4. Claude walks you through the plan and helps you adjust if needed
5. Confirm the plan. You are ready to start.

### During the Day

Use Claude whenever you need help:
- "Draft a reply to [Contact]'s email about the timeline"
- "What do I have with [Client] this week?"
- "Add a task to follow up with [Name] by Friday"
- "Summarize the notes from yesterday's call with [Client]"

### End of Day

Run `/eod` before wrapping up. Claude processes the day and generates tomorrow's plan while you walk away.

### Over Time

The system improves as you use it:
- When Claude makes a mistake, add a guideline to CLAUDE.md
- When you repeat a process manually, turn it into a skill
- When a tool connection would save time, add it
- Run `/monthly-review` once a month to clean up and improve

---

## Glossary

Plain-language definitions for terms you will see in the documentation.

| Term | What It Means |
|---|---|
| **Vault** | Your notes folder. Obsidian calls it a "vault" but it is just a folder of text files on your computer. |
| **CLAUDE.md** | Claude's instruction manual. A text file at the root of your notes folder that Claude reads every session. |
| **Skill** | A successful task turned into a repeatable routine. A text file in `.claude/commands/` that tells Claude how to run a multi-step process. You type `/name` to run it. Your skills library grows over time from your actual work. |
| **MCP server** | A direct connection between Claude and a tool (like ClickUp or Google Calendar). Once set up, Claude can use the tool without going through a browser. |
| **API** | A way for software to talk to other software. When Claude "calls an API," it is asking another service for information or telling it to do something. |
| **OAuth** | A secure login handshake. Instead of giving Claude your password, OAuth lets you approve access once and Claude gets a special key to use going forward. |
| **.env file** | Your password keychain file. A text file that stores all the login information Claude needs for your tools. It never leaves your computer. |
| **Manifest** | A tracking list. During long processes, Claude writes down every item it finds so nothing gets lost. |
| **EOD pipeline** | The end-of-day routine. A multi-step process that collects everything from your day and builds tomorrow's plan. |
| **Sub-agent** | A separate Claude session launched from within your current session. The `/eod` command uses sub-agents so each phase gets a fresh context window. You do not need to do anything special; it happens automatically when you run `/eod`. |
| **Context window** | Claude's working memory for a single conversation. Claude can hold a lot of information at once, but very long sessions may compress older details. That is why important things get written to files. |
