---
name: strategy
description: Think through a business or technology decision using Integral's structured framework. Use when evaluating tools, planning projects, deciding between approaches, or prioritizing competing demands.
---

# Strategy -- Think Through a Problem Like Integral

Use this skill when you need to make a business or technology decision. It applies a structured thinking framework to cut through complexity and reach a clear recommendation.

**When to use:** Evaluating a new tool, planning a project, deciding between approaches, assessing whether to build or buy, prioritizing competing demands.

---

## Step 1: Define the Problem

AskUserQuestion: "What are you trying to figure out? Describe the decision or problem in a sentence or two."

Then clarify scope:

AskUserQuestion: "What kind of decision is this?"
Options:
- Should I add a new tool or system?
- Should I change how something works?
- How should I prioritize competing tasks?
- How should I approach a project or initiative?
- Something else (let me describe it)

---

## Step 2: Gather Context

Before analyzing, pull relevant context from the vault:
- Read CLAUDE.md for current tools, integrations, and preferences
- Read relevant client profiles or project files
- Check inbox files for related open tasks
- Search vault for prior decisions or notes on this topic

Present what you found: "Here is what I know about this area: [summary of relevant context]"

AskUserQuestion: "Anything I am missing? Any constraints I should know about?"
Options:
- That covers it
- Let me add some context
- You are missing something important

---

## Step 3: Apply Integral's Thinking Framework

Work through these lenses in order. Not all will apply to every decision. Skip any that are not relevant.

### Maximize Before You Add
Before recommending anything new, ask: what do you already have that could solve this? Existing tools represent sunk cost, team training, and institutional knowledge. Can an existing tool be configured, extended, or better utilized before adding a new one?

### The Reversibility Test
If you make this change and it does not work, can you undo it? Reversible decisions can be made quickly. Irreversible decisions need more analysis. Classify the decision:
- **Easily reversible** (configuration change, new workflow, trial subscription) -- move fast
- **Hard to reverse** (data migration, new platform, team restructuring) -- slow down, prototype first
- **Irreversible** (contract commitment, public launch, data deletion) -- get it right

### Crawl, Walk, Run
What is the simplest version of this that proves the concept? Define three stages:
- **Crawl**: minimum viable version, manual where needed, validates the idea
- **Walk**: automate the manual parts, add integrations, refine based on real usage
- **Run**: full implementation, scaled, optimized

### Who Benefits and How
- Does this help the top line (revenue, sales, growth)?
- Does this help the bottom line (efficiency, cost reduction, time savings)?
- Who specifically benefits? (you, your team, your clients, your customers)
- What is the cost of NOT doing this?

### Long-Term Trajectory
Where does this decision put you in 6 months? In a year? Does it open doors or close them? Does it create dependency on a specific vendor, person, or process?

---

## Step 4: Recommendation

Present your analysis as a clear recommendation:

1. **Recommendation**: one sentence on what to do
2. **Why**: the strongest 2-3 reasons
3. **Risk**: what could go wrong and how to mitigate it
4. **First step**: the immediate next action (crawl stage)
5. **Decision type**: reversible or irreversible, and what that means for speed

AskUserQuestion: "Does this recommendation make sense? Want me to adjust anything or start on the first step?"
Options:
- Makes sense, let us do it
- I disagree with [specific part]
- I need to think about it
- What about [alternative]?

If they want to proceed, help them execute the first step immediately. Do not just leave them with a recommendation.

---

## Step 5: Record the Decision

After a decision is made, log it:
1. Add a brief note to the relevant client or project file: what was decided, why, and when
2. If it created action items, route them to the appropriate inbox file
3. If it changed a tool or process, update CLAUDE.md

Decisions that are not recorded get re-litigated. Write it down.
