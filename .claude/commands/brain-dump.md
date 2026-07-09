# Brain Dump

Manual brain dump command. The user dictates everything on their mind and the assistant parses, classifies, and routes each item to the correct location in the vault.

**The vault is a Git repository in your cloud workspace.** There is no background file sync, so the built-in editor is safe for reads and writes -- read a file, modify it, and write it back with the Edit or Write tool.

**Critical rule: Tasks are flat bullets.** Do NOT create `### New from <source>` subsection headers for tasks. Append new tasks directly under `## Open Tasks` as flat bullets. Source context lives in the italic suffix at the end of each task (e.g., `*from Brain Dump MM/DD*`). Only `### Notes from <source>` headers under `## Notes` are allowed -- meeting notes benefit from source grouping, tasks do not.

---

## Step 1: Collect Brain Dump

1. Use AskUserQuestion: "Go ahead -- dump everything on your mind. Tasks, notes, ideas, reminders, personal stuff, anything. I'll sort it all out."
2. Wait for the full response. If the user seems to have more, ask: "Anything else, or is that everything?"

---

## Step 2: Parse and Classify

1. Break the response into individual items (one per bullet or distinct thought)
2. Classify each item along two dimensions:
   - **Client**: [Client A], [Client B], etc., Cross-Client, or Personal
   - **Type**: `task` (clear next action), `note` (information/context), `idea` (brainstorm/someday), `personal` (non-work)
3. Use contact names, tool names, and project context to infer client when not explicit
4. Flag any items that cannot be confidently classified

---

## Step 3: Route Items

1. For each classified item, route by editing the target file directly:
   - **Client tasks** -> `Inbox/<Client>.md` under `## Open Tasks` as `- [ ]` items
   - **Client notes** -> `Inbox/<Client>.md` under `## Notes` as plain bullets
   - **Cross-client tasks/notes** -> `Inbox/[YourCompany].md` under `## Open Tasks` or `## Notes`
   - **Ideas** -> `Inbox/[YourCompany].md` under `## Brain Dump` (keep as-is)
   - **Personal items** -> `Inbox/Personal.md` under `## Open Tasks` (or `## Brain Dump` if it's a loose thought)
2. Dedup check: before adding a task, verify it does not already exist in the target file
3. If any items could not be classified, present them to the user and ask where they should go

---

## Step 4: Log to Manifest

1. If an EOD manifest exists at `/tmp/eod-manifest-TODAY.md`, append rows for each routed item with Source = "Brain Dump"
2. If no manifest exists, skip this step (brain dump can run standalone)

---

## Step 5: Summary

1. Print a table of what was routed and where:
   - Item description | Client | Type | Routed To
2. Call out any items left unrouted or flagged for user decision
3. Print totals: tasks created, notes filed, ideas saved, personal items parked

---

## Step 6: Persist to Git

Routed items only survive this cloud session if they are pushed:

`git add -A && git commit -m "Brain dump YYYY-MM-DD" && git push`

If the working tree is clean after routing (everything deduped away), say so and skip the commit/push. If the push is rejected because the remote moved, run `git pull --rebase`, then push again. Report "pushed" (or the failure, plainly) as the last line of the summary.
