---
name: learn
description: Capture and integrate new knowledge from conversations, meetings, research, mistakes, or insights into the vault.
---

# Learn -- Capture and Integrate New Knowledge

Use this skill when you have learned something important and want to make sure it sticks in your system. This could be from a conversation, a meeting, research, a course, a mistake, or an insight.

**When to use:** After a meeting that changed how you think about something, after learning a new tool or technique, after making a mistake you do not want to repeat, or when you encounter information that connects to your existing work.

---

## Step 1: What Did You Learn?

AskUserQuestion: "What did you learn? Describe it however makes sense. A sentence, a paragraph, a brain dump."

Then classify it:

AskUserQuestion: "What kind of knowledge is this?"
Options:
- A fact or reference I want to look up later
- A decision or conclusion I reached
- A process or technique I want to remember
- A mistake or lesson learned
- A connection between things I already knew
- An insight about a person, client, or relationship

---

## Step 2: Connect It

Search the vault for related content:
- Files that mention similar topics
- Client or project files this relates to
- Existing reference material in the same domain
- Prior decisions that this new knowledge affects

Present connections: "This seems related to: [list of connected vault files with brief descriptions]"

AskUserQuestion: "Any of these connections important?"
Options:
- Yes, especially [specific file]
- These are all relevant
- None of these are related
- There is another connection I want to make

---

## Step 3: Store It

Based on the type of knowledge:

**Fact or reference:**
- Check if a relevant reference file already exists in `Resources/Reference/` or `Resources/Concepts/`
- If yes, add the new information to that file
- If no, create a new file in the appropriate Resources subfolder
- Add wiki-links to connect it to related files

**Decision or conclusion:**
- Add to the relevant client or project file under a Decisions section
- Include the date and the reasoning (not just the decision, but why)
- If it changes a previous decision, note what changed and why

**Process or technique:**
- If it is a repeatable process, offer to create a skill (`/build-skill`)
- If it is reference material, add to `Resources/Reference/`
- If it is specific to a client or project, add to that file

**Mistake or lesson learned:**
- Add a guideline to CLAUDE.md if it affects how the assistant should behave
- If it is operational (a tool gotcha, an API quirk), save to memory files
- If it is a business lesson, add to the relevant project or client file

**Connection between existing knowledge:**
- Add wiki-links between the connected files
- Update `## Related` sections where appropriate
- If the connection reveals a new concept worth tracking, create a concept page in `Resources/Concepts/`

**Insight about a person or relationship:**
- Update the person's file in `Resources/People/` (create if needed)
- Add context about the insight (what you learned, when, why it matters)

---

## Step 4: Verify It Stuck

After storing:
1. Read back the file(s) that were updated
2. Confirm the knowledge is findable: "If you search for [key terms], you will find this in [file path]"
3. Check if any other files should be updated based on this new knowledge

AskUserQuestion: "Does this capture it? Anything else to add?"
Options:
- That is good
- I want to add more detail
- Put it somewhere else
- Also update [specific file]

---

## Step 5: Surface It Later

Set up retrieval triggers so this knowledge comes back when it is relevant:

- If it relates to a client, it will surface during meeting prep and EOD processing
- If it is a guideline, CLAUDE.md ensures it is applied every session
- If it is a concept, the knowledge graph links will surface it when related topics come up
- If it is time-sensitive (expires, needs follow-up), add a task to the inbox with a date
