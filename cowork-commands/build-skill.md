---
name: build-skill
description: Turn a successful task into a repeatable slash command workflow.
---

# Build Skill -- Turn a Successful Task Into a Repeatable Workflow

Use this after completing a task that you want to be able to repeat. This skill interviews you about what just happened and creates a new slash command from it.

**When to use:** You just did something that worked well and you want to do it again in the future without re-explaining everything.

---

## Step 1: What Did We Just Do?

AskUserQuestion: "What task do you want to turn into a skill? Describe it in a sentence."

Then gather details:

AskUserQuestion: "How often will you run this?"
Options:
- Daily or near-daily
- Weekly
- Monthly
- On demand (whenever I need it)

AskUserQuestion: "Does this skill need any external tools or data?"
Options:
- No, it just works with vault files
- Yes, it needs [calendar, email, task manager, etc.]
- Yes, it needs an API or service
- I am not sure

---

## Step 2: Reconstruct the Process

Look at what was done in the current conversation (or ask the user to describe it):

1. What inputs were needed? (files read, data fetched, user answers)
2. What steps were taken? (in order)
3. What outputs were produced? (files created, messages sent, tasks updated)
4. Were there any decision points? (if X then Y, user choices)
5. What worked well that should be preserved?
6. What was awkward that should be smoother next time?

Present the reconstructed process:
"Here is what I think the skill should do:
1. [Step]
2. [Step]
3. [Step]"

AskUserQuestion: "Does this capture it? Anything to add or change?"
Options:
- That is right
- Missing a step
- Change the order
- Simplify it

---

## Step 3: Design the Skill

Determine the skill structure:

### Name
Suggest a short, clear name. Skills are invoked as `/name` so keep it lowercase, one or two words, hyphenated if needed.

AskUserQuestion: "What should we call this skill?"
Options:
- [your suggestion]
- [alternative suggestion]
- Let me name it

### Input Pattern
How should the skill start? Options:
- **Interview pattern**: Ask 2-3 questions before executing (good for tasks that vary each time)
- **Auto-run pattern**: Pull all context from vault and execute immediately (good for routine tasks)
- **Hybrid**: Auto-gather context, then confirm before executing

### Output Pattern
What should the skill produce?
- A file in the vault
- Changes to existing files
- Messages sent to external services
- A summary presented to the user
- Some combination

---

## Step 4: Write the Skill

Create the skill file at `.claude/commands/[name].md` with this structure:

```markdown
# [Skill Name] -- [One-line description]

[Brief description of what this skill does and when to use it.]

---

## [Steps organized logically]

[Each step with clear instructions, AskUserQuestion prompts where input is needed, and concrete actions to take.]
```

**Writing guidelines:**
- Use plain language. Write instructions as if briefing a smart colleague.
- Use `AskUserQuestion` for every point where user input is needed.
- Include specific file paths, API endpoints, or tool references.
- Reference CLAUDE.md for user-specific details (do not hardcode names, clients, or preferences).
- Handle the happy path first. Add error handling only for likely failure points.
- End with recording what was done (update relevant files, log the output).

Write the file and show the user:
"Your new skill is ready. You can run it anytime by typing `/[name]`."

### CoWork Version

**Always create a CoWork-compatible copy** alongside the Code version. Copy the file to `cowork-commands/[name].md` (in the vault root if running from a vault, or in the repo if running from the repo) and prepend YAML frontmatter:

```yaml
---
name: [skill-name]
description: [One-line description of what this skill does.]
---
```

Tell the user: "I also created a CoWork-compatible version at `cowork-commands/[name].md`. If you use Claude CoWork, upload it through the **Customize** section in settings to make it available as a slash command there."

AskUserQuestion: "Want to test it right now?"
Options:
- Yes, let us run it
- No, I will try it later
- I want to tweak something first
