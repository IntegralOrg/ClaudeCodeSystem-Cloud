# The Integral Development Process (Claude Code Playbook)

> **What this is.** A portable, self-contained onboarding guide to how we build software with
> Claude Code. It documents the skills, the workflow, the tooling, and — importantly — the *actual
> contracts* of each skill, so a developer (or an agent) reading only this file understands not just
> *that* a step exists but *how it works* and *what artifacts it produces*.
>
> **Who it's for.** Any developer joining a repo that uses this process — or bootstrapping a new one.
>
> **How to reuse it.** This file is written to be repo-agnostic. Copy it into any repo's
> `docs/guides/` verbatim. The only project-specific document is each repo's own `CLAUDE.md`
> (see [§8](#8-the-claudemd-file-per-repo)). **Before relying on it in a new repo, read
> [§9 Portability & personalization](#9-portability--personalization-read-before-copying-to-a-new-repo)**
> — some commands are personal/repo-specific and must be adapted, not copied blind.

---

## Contents

- [§0 TL;DR](#0-tldr--the-loop-in-one-breath)
- [§1 Why we work this way](#1-why-we-work-this-way)
- [§2 Prerequisites & tooling setup](#2-prerequisites--tooling-setup)
- [§3 The skills catalog (full contracts)](#3-the-skills-catalog-full-contracts)
- [§4 The end-to-end feature workflow](#4-the-end-to-end-feature-workflow)
- [§5 The local commands (actual contents)](#5-the-local-commands-actual-contents)
- [§6 Memory](#6-memory-persistent-across-sessions)
- [§7 Small changes (the lightweight path)](#7-small-changes-the-lightweight-path)
- [§8 The CLAUDE.md file (per repo)](#8-the-claudemd-file-per-repo)
- [§9 Portability & personalization](#9-portability--personalization-read-before-copying-to-a-new-repo)
- [§10 Quick-reference cheat sheet](#10-quick-reference-cheat-sheet)
- [§11 Adoption checklist](#11-adopting-this-on-a-new-repo--checklist)
- [§12 Appendix: portable `/handoff` & `/pickup` command files](#12-appendix-portable-handoff--pickup-command-files)

---

## 0. TL;DR — the loop in one breath

For any non-trivial feature:

```
brainstorm  →  slice the plan  →  per slice: plan → build (subagents) → two-stage review
            →  validation gate → open PR → CodeRabbit loop → handoff → human merge → next slice
```

Small one-off changes skip the ceremony: branch → change → gate → PR.

The whole thing runs on **skills** (reusable procedures Claude loads on demand), **git worktrees**
(isolated workspaces), **subagents** (parallel workers with isolated context), and a **validation
gate** (typecheck / lint / build / test) that must pass before any PR.

Every skill below has an explicit **contract** — the rules it enforces and the artifacts it
produces. The point of this doc is that none of those contracts is a black box.

---

## 1. Why we work this way

Three goals, in priority order:

1. **Quality.** A plan reviewed before code is written, code reviewed by two independent passes
   plus CodeRabbit, every finding verified against live code, and no completion claimed without
   running the command — this catches far more than a single human skim.
2. **Confidence.** Independent perspectives (separate review subagents, an adversarial CodeRabbit
   pass) before anything merges means we trust what lands on `main`.
3. **Speed.** Worktrees + subagents let independent work happen in parallel. A well-specced slice
   goes plan-to-merged-PR in roughly one session.

The discipline is the point. Several skills are **rigid** (TDD, systematic-debugging,
verification-before-completion) and state explicitly that *"violating the letter of the rule is
violating the spirit of the rule."* Don't adapt the discipline away.

---

## 2. Prerequisites & tooling setup

### 2.1 Claude Code

Install Claude Code (CLI, desktop app, or IDE extension). Everything below assumes you're driving
work through it. Skills are invoked with the **Skill tool** (type `/<skill-name>` or just ask for
the work and Claude loads the relevant skill).

### 2.2 The `superpowers` plugin (the skills engine)

This is the backbone. `superpowers` is an official Claude Code plugin that ships the process skills
in [§3](#3-the-skills-catalog-full-contracts). Install it once per machine (it registers globally,
not per-repo). This playbook documents **superpowers 6.0.2**; the skill list is stable across point
releases but verify against the version you install.

The entry-point skill `using-superpowers` primes every session: it teaches Claude to check for a
relevant skill *before* acting, even at a 1% chance of relevance, and to follow process skills
(brainstorming, debugging) before implementation skills. You don't invoke it manually.

> Sanity check: if `/superpowers:brainstorming` loads, the plugin is installed.

### 2.3 CodeRabbit (already on — no setup)

**Every repo in the org has CodeRabbit enabled by default.** You do **not** configure it. When you
open a PR, CodeRabbit automatically posts review threads. Your job is to *work the loop* with it
([§5.2](#52-rabbit--coderabbit-triage-repo-local)), not to install it.

### 2.4 Local commands used in the loop

These are **not** all from superpowers — know where each lives, because that determines whether it
ports to a new repo (see [§9](#9-portability--personalization-read-before-copying-to-a-new-repo)):

| Command | Source | Ports to a new repo? |
|---|---|---|
| `/code-review` | org marketplace plugin (`code-review`) | Yes — installed globally |
| `/rabbit` | **repo-local** (`.claude/commands/rabbit.md`) | Only if you copy the file; has DB-migration specifics to adapt |
| `/validate` | **repo-local** (`.claude/commands/validate.md`) | Must be **rewritten** per project (it encodes this repo's gate) |
| `/handoff`, `/pickup` | **user-level** (`~/.claude/commands/`) | Personal; contains hardcoded paths — generalize before sharing |

### 2.5 MCP servers (optional but high-leverage)

MCP (Model Context Protocol) servers give Claude typed, scoped access to external systems. Configure
the ones your repo needs:

- **A database MCP** (e.g. Supabase) — so Claude can read live schema and run migrations. This is
  what makes "verify the plan against the live schema" (a core rule below) cheap.
- **`context7`** — fetches current library/framework docs on demand. Use it instead of trusting
  model memory for any library API.
- A **project/operational MCP** if your product exposes one (read models + constrained write tools).

### 2.6 Git

Standard git + the `gh` CLI for GitHub (PRs, issues, review threads). Interactive git flags (`-i`)
are not supported in the Claude Code shell — avoid `rebase -i` / `add -i`.

---

## 3. The skills catalog (full contracts)

Skills are reusable, version-controlled procedures. **The rule: if a skill might apply, invoke it
before doing the work.** Process skills decide *how* to approach a task; implementation skills guide
execution. Each entry below gives the **trigger**, the **contract** (the rules it enforces), the
**artifacts** it produces, and the **gotchas**.

Skills are either **rigid** (follow exactly — TDD, systematic-debugging,
verification-before-completion) or **flexible** (adapt the principles). Each says which.

### 3.1 `brainstorming` — turn an idea into an approved design

**Trigger:** before ANY creative work — new feature, component, behavior change. This is the *first*
skill for "let's build X."

**Contract:**
- **HARD GATE:** do not write code, scaffold, or invoke any implementation skill until a design is
  presented and the user approves it — *every* project, regardless of perceived simplicity. The
  anti-pattern it explicitly kills: "this is too simple to need a design."
- Explore project context first (files, docs, recent commits).
- Ask clarifying questions **one at a time** (multiple-choice preferred). Don't dump a questionnaire.
- Propose **2–3 approaches** with trade-offs, leading with a recommendation.
- Present the design in sections, getting approval after each. Apply **YAGNI ruthlessly**.
- **The only skill it hands off to is `writing-plans`.** Never jump from brainstorm straight to an
  implementation/design skill.

**Artifact:** a design spec saved to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and
committed to git, followed by a **spec self-review** (placeholder scan, internal-consistency check,
scope check, ambiguity check) and a **user review gate** (you review the written spec before it
proceeds).

**Gotcha:** if the request spans multiple independent subsystems, it decomposes into sub-project
specs first — each gets its own spec → plan → implementation cycle. Don't refine details of
something that needs splitting.

> **Our adaptation:** when a PRD/spec already defines the work, do *lightweight* discovery + a short
> design pass — don't re-run the full brainstorm ceremony (it burns the context budget before
> implementation).

### 3.2 `writing-plans` — turn a spec into an executable plan

**Trigger:** you have a spec/requirements for a multi-step task, before touching code.

**Contract:** write the plan assuming the implementer "has zero context for our codebase and
questionable taste." Everything they need is in the plan: exact file paths, complete code, exact
commands with expected output. DRY, YAGNI, TDD, frequent commits. **No placeholders** — "TBD",
"add error handling", "similar to Task N", or referencing a type no task defines are all *plan
failures*.

**Artifact:** a plan saved to `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md` with this shape:

```markdown
# [Feature] Implementation Plan
> For agentic workers: REQUIRED SUB-SKILL: subagent-driven-development (or executing-plans).
**Goal:** [one sentence]
**Architecture:** [2-3 sentences]
**Tech Stack:** [key libs]
## Global Constraints
[project-wide requirements — version floors, naming/copy rules — exact values copied from the spec.
 Every task implicitly includes this section.]
---
### Task N: [Component]
**Files:**  Create / Modify (with line ranges) / Test — exact paths
**Interfaces:**
- Consumes: [what it uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact names + types]
- [ ] Step 1: Write the failing test   (actual test code)
- [ ] Step 2: Run it, verify it fails   (exact command + expected FAIL)
- [ ] Step 3: Minimal implementation     (actual code)
- [ ] Step 4: Run it, verify it passes   (exact command + expected PASS)
- [ ] Step 5: Commit                      (exact git commands)
```

Each task is "the smallest unit that carries its own test cycle and is worth a fresh reviewer's
gate." After writing, the author runs a **self-review** (spec coverage, placeholder scan, type
consistency across tasks) and fixes inline. Then it offers an **execution-handoff choice**:
subagent-driven (recommended) vs inline executing-plans.

**This is the artifact most people don't realize exists.** The `Interfaces: Consumes/Produces` block
is how a subagent that sees *only its own task* learns the exact names/types its neighbors expose.

### 3.3 `subagent-driven-development` — execute the plan, in this session

**Trigger:** executing a plan whose tasks are mostly independent, staying in the current session.
(Rigid about its review gates.)

**Contract — the machine:** a controller (you) drives this loop per task:

```
read plan + Global Constraints + create todos
  └─ per task:
       dispatch IMPLEMENTER subagent (fresh context, gets its task brief — not the whole plan)
       → implementer implements, tests, commits, self-reviews → reports status
       → controller generates a review package → dispatches TASK REVIEWER subagent
       → reviewer returns TWO verdicts: spec-compliance AND code-quality
       → Critical/Important findings → dispatch FIX subagent → re-review until clean
       → mark task complete in the progress ledger
  └─ after all tasks: dispatch FINAL whole-branch reviewer (most capable model)
  └─ hand off to finishing-a-development-branch
```

**Key rules:**
- **Fresh subagent per task.** Subagents never inherit your session history — you construct exactly
  the context they need. Hand artifacts over as **files**, not pasted text (a task brief, a report
  file, a review package), because everything you paste stays resident in your context for the rest
  of the session.
- **Two verdicts are mandatory.** A task isn't done until the reviewer reports *both* spec-compliance
  ✅ and code-quality approved. The self-review does **not** replace the actual review.
- **Never pre-judge a reviewer.** Don't tell a reviewer what not to flag or pre-rate a finding's
  severity ("treat as Minor at most"). If you think it's a false positive, let it be raised and
  adjudicate in the loop. The plan's example code is a starting point, not proof its weaknesses were
  chosen.
- **Never dispatch implementers in parallel** (they conflict). Parallelism is for *reviews* and for
  independent tasks via worktrees.
- **Implementer statuses:** `DONE` / `DONE_WITH_CONCERNS` (read the concerns) / `NEEDS_CONTEXT`
  (provide it, re-dispatch) / `BLOCKED` (give context, escalate model, split the task, or escalate to
  the human — never force the same model to retry unchanged).
- **Model selection:** use the cheapest model that fits each role. Transcription-style tasks (plan
  contains the code) → cheapest; multi-file integration → standard; the final whole-branch review →
  most capable. **Always specify the model explicitly** — omitting it inherits your (expensive)
  session model.
- **Durable progress ledger:** progress is tracked in a file (`.git/sdd/progress.md`), not just
  todos, because conversation memory doesn't survive compaction. After a compaction/resume, trust
  the ledger + `git log` over recollection — re-dispatching already-complete tasks is the single
  most expensive failure observed.

**Alternative — `executing-plans`:** same plan, executed in a *separate* session with human
checkpoints between batches (instead of subagent-per-task). Use it when subagents aren't available
or you want a human in the loop between tasks. It also ends by handing off to
`finishing-a-development-branch`.

> **Our adaptation:** parallel implementer subagents work on **disjoint file sets**; when they must
> touch the same files, give each its own worktree. **Subagents are literal** — they transcribe
> plan placeholder geometry exactly and won't make UI beautiful on their own; do a separate design
> pass for visual work.

### 3.4 `dispatching-parallel-agents` — fan out independent problems

**Trigger:** 2+ independent tasks/failures with no shared state (e.g. 3 unrelated failing test
files). (Flexible.)

**Contract:** one agent per independent problem domain, dispatched **concurrently** (multiple
dispatch calls in a single response = parallel; one per response = sequential). Each agent gets:
specific scope, a clear goal, constraints ("don't touch other code"), and a defined output ("return
a summary of root cause + changes"). When they return: read each summary, check for conflicts, run
the full suite, spot-check (agents make systematic errors).

**Don't use when** failures are related (fixing one may fix others), you need full-system context,
or agents would edit the same files.

### 3.5 `using-git-worktrees` — isolate the workspace

**Trigger:** starting feature work that needs isolation, or before executing a plan. (Flexible, but
the detection step is mandatory.)

**Contract:**
- **Step 0 — detect existing isolation first.** Compare `git rev-parse --git-dir` vs
  `--git-common-dir`; if they differ (and you're not in a submodule — guard with
  `git rev-parse --show-superproject-working-tree`), you're already in a worktree — don't create a
  nested one.
- **Prefer the harness's native worktree tool** (e.g. an `EnterWorktree` tool / `--worktree` flag)
  over raw `git worktree add`. Using raw git when a native tool exists creates phantom state the
  harness can't manage. This is the #1 mistake.
- **Fallback:** `git worktree add` into `.worktrees/` (must be gitignored — verify with
  `git check-ignore`, add + commit if not).
- Run project setup (`npm install`, etc.) and a **clean baseline test** before implementing.

**Gotchas (hard-won, these bite everyone once):**
- A fresh worktree **lacks gitignored files** like `.env` — copy `.env` / `.env.local` from the root
  or the app crashes on missing config.
- A local dev server run *inside* a worktree may still resolve the **root** repo's code/functions for
  some tooling (e.g. serverless `netlify dev`). Validate worktree code via the PR's deploy preview
  when in doubt.
- A stray old worktree with build artifacts (`dist/`) can **poison root lint** with phantom errors —
  lint the source dir explicitly (`npx eslint src/`).

### 3.6 `test-driven-development` — test first, always

**Trigger:** implementing any feature or bugfix, before writing implementation code. (**Rigid.**)

**Contract — the Iron Law:** `NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST`. If you wrote code
before the test, **delete it** ("delete means delete" — don't keep it as reference, don't adapt it).

**Red-Green-Refactor:** write one minimal failing test → **watch it fail** for the right reason
(mandatory; a test that passes immediately proves nothing) → write the minimal code to pass → watch
it pass with pristine output → refactor while green. Tests assert **real behavior**, not mock
behavior. Exceptions (throwaway prototypes, generated code, config) require the human's say-so.

### 3.7 `systematic-debugging` — root cause before fixes

**Trigger:** any bug, test failure, or unexpected behavior, before proposing a fix. (**Rigid.**)

**Contract — the Iron Law:** `NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST`. Four phases, each
completed before the next:

1. **Root cause** — read errors fully, reproduce, check recent changes, instrument component
   boundaries in multi-layer systems, trace the bad value back to its source.
2. **Pattern analysis** — find working examples, compare, list every difference.
3. **Hypothesis** — state one hypothesis, test it with the *smallest* change, one variable at a time.
4. **Implementation** — write a failing test reproducing the bug (via TDD), make one fix, verify.

**Escalation rule:** if 3+ fixes have failed, **stop and question the architecture** with the human —
that pattern (each fix reveals a new problem elsewhere) means the design is wrong, not the hypothesis.

### 3.8 `requesting-code-review` — dispatch a reviewer

**Trigger:** after each task in subagent-driven dev, after a major feature, before merge. (Flexible.)

**Contract:** dispatch a `general-purpose` reviewer subagent with *crafted* context (never your
session history), filling a template with `{DESCRIPTION}`, `{PLAN_OR_REQUIREMENTS}`, `{BASE_SHA}`,
`{HEAD_SHA}`. The reviewer returns findings graded **Critical / Important / Minor** plus an
assessment. Act: fix Critical immediately, Important before proceeding, note Minor; push back if the
reviewer is wrong (with reasoning). This is the template the final whole-branch review uses.

### 3.9 `receiving-code-review` — respond with rigor, not performance

**Trigger:** receiving review feedback (from CodeRabbit, a reviewer subagent, or a human), before
implementing it — *especially* if the feedback seems unclear or questionable. (Flexible but strict on
tone.)

**Contract — the response pattern:** READ fully → UNDERSTAND (restate or ask) → **VERIFY against
codebase reality** → EVALUATE (is it correct *for this codebase*?) → RESPOND → IMPLEMENT one at a
time, testing each.

- **External feedback = suggestions to evaluate, not orders to follow.** Verify before implementing.
- **Forbidden responses:** "You're absolutely right!", "Great point!", "Thanks for catching that!" —
  **no performative agreement and no gratitude expressions.** Just state the fix or just fix it.
- **Push back** when a suggestion breaks functionality, the reviewer lacks context, it violates
  YAGNI (grep for actual usage of "implement-properly" suggestions), it's wrong for the stack, or it
  conflicts with the human's decisions. If you can't verify, say so and ask.
- **If any item is unclear, clarify ALL items before implementing any** (items may be related).
- **GitHub:** reply in the comment thread
  (`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a top-level PR comment.

> This is the skill that powers "verify every review finding against live code before accepting it" —
> the rule that catches reviewer (and CodeRabbit) false positives.

### 3.10 `verification-before-completion` — evidence before claims

**Trigger:** about to claim work is complete/fixed/passing, before committing or opening a PR.
(**Rigid.**)

**Contract — the Iron Law:** `NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE`. If you
haven't run the verification command *in this message*, you cannot claim it passes. The gate:
identify the command that proves the claim → run it fresh and complete → read the full output and
exit code → only then state the claim *with* the evidence. "Should work", "I'm confident", "the agent
said success", "linter passed" (≠ build) are all insufficient. Trust an agent's success report only
after checking the VCS diff yourself.

### 3.11 `finishing-a-development-branch` — integrate the work

**Trigger:** implementation complete, tests pass, deciding how to integrate. This is the skill that
actually creates the PR or merge. (Flexible; menu is fixed.)

**Contract:** verify tests pass → detect environment (normal repo vs worktree vs detached HEAD) →
present **exactly these options** and execute the choice:

```
1. Merge back to <base> locally
2. Push and create a Pull Request
3. Keep the branch as-is
4. Discard this work        (requires typing "discard" to confirm)
```

(Detached HEAD gets a 3-option menu with no local-merge.) Cleanup rules: only Options 1 & 4 remove
the worktree; **Option 2 keeps the worktree alive** so you can iterate on PR feedback. Merge *before*
removing anything; only clean up worktrees you created (under `.worktrees/`); never force-push
without an explicit request.

### 3.12 `writing-skills` — author new skills (for your team's own skills)

**Trigger:** creating or editing a skill. Relevant because onboarding a team means *generating* their
own skills and `CLAUDE.md` files. (**Rigid** — it's TDD applied to documentation.)

**Contract — the Iron Law:** `NO SKILL WITHOUT A FAILING TEST FIRST`. You run a pressure scenario
against a subagent *without* the skill (RED — watch it fail, record the exact rationalizations),
write the minimal skill that counters those specific failures (GREEN), then close loopholes (REFACTOR)
until it's bulletproof.

**Key authoring rules:**
- **Frontmatter:** `name` (letters/numbers/hyphens only) + `description`. The description states
  **only when to use** ("Use when…", third person, with symptoms/keywords) — **never summarize the
  workflow**, because agents will follow the description and skip the body.
- **Match the form to the failure:** discipline failures (knows the rule, skips it) → prohibition +
  rationalization table + red-flags list + "letter = spirit". Wrong-shaped output → a positive recipe
  (state what the output IS), *not* prohibitions (prohibitions backfire on shaping problems).
- Skills are reusable techniques/patterns/references — **not narratives** about how you solved
  something once. Project-specific conventions go in `CLAUDE.md`, not a skill.
- Token-efficiency matters (frequently-loaded skills <200 words); move detail to `--help` or separate
  reference files; cross-reference other skills by name, never `@`-link them (force-loads context).

---

## 4. The end-to-end feature workflow

This ties the skills together. Follow it by default for any large feature/overhaul. **Small one-off
changes skip to [§7](#7-small-changes-the-lightweight-path).**

### Step 1 — Brainstorm once, broadly
`brainstorming` ([§3.1](#31-brainstorming--turn-an-idea-into-an-approved-design)) → approved design
spec in `docs/superpowers/specs/`. Lock decisions in a small number of question rounds.

### Step 2 — Decompose into slices
Break the spec into **dependency-ordered slices**, each sized for ONE clean review-and-merge cycle.
Write them into a slice plan (`docs/superpowers/plans/*-slices.md`) with a status marker + PR number
per slice:

- `[ ]` not started · `[~]` in progress / PR open but **not merged** · `[x]` **merged to `main`** only.

**Sizing:** prefer fewer, larger PRs over many thin ones. Batch same-kind mechanical work (all the
dialogs, all the forms) into one pass; reserve a dedicated slice only for a large/risky single
surface.

### Step 3 — Per slice: verify-vs-live, then plan, then build
1. **Verify the slice against live reality first.** Plans drift. Check it against the **live schema /
   real consumer surface** (DB MCP, grep the actual call sites) *before* writing code. This single
   habit prevents most rework.
2. `writing-plans` ([§3.2](#32-writing-plans--turn-a-spec-into-an-executable-plan)) → per-slice plan.
3. `subagent-driven-development` ([§3.3](#33-subagent-driven-development--execute-the-plan-in-this-session))
   inside an isolated worktree ([§3.5](#35-using-git-worktrees--isolate-the-workspace)). Subagents
   follow `test-driven-development` per task.

### Step 4 — Two-stage review (whole diff)
The subagent-driven loop already reviews each task (spec + quality). At the slice level, run two
independent passes over the complete diff:
1. **Spec-compliance** — does it do what the slice said?
2. **Code-quality / security.**

**Verify every finding against live code before accepting it**
([§3.9](#39-receiving-code-review--respond-with-rigor-not-performance)) — reviewers surface false
positives.

### Step 5 — Validation gate
Nothing opens a PR until the gate is green
([§3.10](#310-verification-before-completion--evidence-before-claims)). Run `/validate` or the repo's
documented commands. The gate always covers **typecheck → lint → build → tests**. **Watch coverage
gaps** — sub-packages or serverless-function dirs the root scripts don't typecheck (the repo's
`CLAUDE.md` lists these; run their gates separately).

### Step 6 — PR + CodeRabbit loop (automatic — don't wait to be asked)
As soon as a slice passes its gate + two-stage review, use
`finishing-a-development-branch` ([§3.11](#311-finishing-a-development-branch--integrate-the-work))
to open the PR, then work the CodeRabbit loop
([§5.2](#52-rabbit--coderabbit-triage-repo-local)) without being prompted.

### Step 7 — Handoff (automatic — right after the CodeRabbit loop closes)
Once every CodeRabbit thread is resolved and fixes are pushed, write the next-slice `/handoff`
([§5.4](#54-handoff--pickup--session-continuity-user-level)) without being asked.

### Step 8 — Merge (explicit human sign-off)
Merging to `main` always gets explicit human sign-off. After merge: flip the slice marker to `[x]`
+ PR number, then move to the next slice. A well-specced slice runs plan-to-merged-PR in ~one
session; only the final merge needs the human.

---

## 5. The local commands (actual contents)

These are the slash-commands the workflow leans on. Their actual behavior is documented here because
a reader without the command files installed would otherwise have no idea what they do — and because
several are **personal or repo-specific** ([§9](#9-portability--personalization-read-before-copying-to-a-new-repo)).

### 5.1 `/code-review` (org marketplace plugin)

A multi-agent PR reviewer. Mechanism: a Haiku agent checks eligibility (skip if closed/draft/trivial/
already-reviewed) → a Haiku agent lists relevant `CLAUDE.md` paths → a Haiku agent summarizes the
diff → **5 parallel Sonnet agents** each review a different lens (CLAUDE.md adherence; shallow bug
scan; git-history/blame context; prior-PR comments on these files; in-code-comment guidance) →
**per-finding Haiku confidence scoring 0–100** → **findings under 80 are filtered out** → posts a
single concise GitHub comment with cited, permalinked code. It explicitly does **not** run
build/typecheck (assumes CI does) and ignores nitpicks/pre-existing issues/lint-catchable issues.
The `ultra` variant runs a deeper multi-agent review in the cloud.

### 5.2 `/rabbit` — CodeRabbit triage (repo-local)

Works the CodeRabbit loop. Mechanism: resolve the latest commit + its PR, and confirm the commit is
actually on the remote → pull CodeRabbit review threads via GitHub GraphQL
(`pullRequest.reviewThreads`, keep `author.login` containing `coderabbit`, **keep threads where
`isResolved == false`**) → build a triage list → classify each item **Fix/Implement** (real
correctness/reliability/security/maintainability) or **Skip** (false positive / churn / conflicts
with intent), each **with a short reason** → implement the fixes → push → reply on each thread with
the fixing commit → resolve every thread (`resolveReviewThread`) → request re-review by posting
**`@coderabbitai review`** → **re-query and verify `isResolved: true`, and confirm a new review
landed, before declaring done.** If an item is ambiguous or needs product direction, it stops and
asks.

> **Three failure modes this loop has actually hit. They are why the steps above read the way they
> do (all three cost real rounds on `ClaudeCodeSystem-Cloud` PR #3):**
>
> 1. **Filter on `isResolved`, never on the HEAD commit.** CodeRabbit anchors each comment to the
>    commit it reviewed. The moment you push a fix, `HEAD` moves and every still-open comment is
>    anchored to an *older* commit, so a `comment.commit.oid == HEAD` filter matches nothing and the
>    agent concludes there is nothing left to do. The loop silently ends after round one.
> 2. **The re-review trigger is `@coderabbitai review`, not `/rabbit`.** `/rabbit` is the *local*
>    slash-command. CodeRabbit does not understand it. Posting it produces a no-op comment that looks
>    like the trigger fired when it did not.
> 3. **Rewrite the block, do not patch per-comment.** When several comments land on the same
>    interdependent region (prose rules, a config block, a state machine), applying them one at a
>    time makes each patch contradict its neighbour. CodeRabbit then correctly flags the
>    contradiction you just introduced, and the loop eats itself round after round. Read the whole
>    block, understand how the comments interact, rewrite it once.
>
> The loop is **not** complete when the code is fixed. It is complete when the fixes are on the
> remote, every thread re-queries as `isResolved: true`, and a fresh review has landed with nothing
> open. Re-review can lag 10-15 minutes; poll, do not assume.

> **Repo-specific rule baked in:** if a finding suggests changing an existing DB migration, it does
> **not** edit the old migration — it writes a **new** migration so local and remote history stay in
> sync. That rule is specific to a Supabase-migrations repo; adapt or drop it elsewhere.

### 5.3 `/validate` — the validation gate (repo-local, **rewrite per project**)

In this repo, `/validate` runs 8 phases: **(1) lint** `npm run lint` → **(2) typecheck**
`npm run typecheck` → **(3) build** `npm run build` + asset checks → **(4) Playwright E2E** against
hosted Supabase (needs `TEST_USER_EMAIL`/`TEST_USER_PASSWORD` in `.env`) → **(5–8) manual checklists**
(DB schema/RLS, env config, external-service connectivity, performance/security). Phases 1–4 are the
automated gate; 5–8 are pre-release manual checks.

> This command **encodes this repo's stack** (Vite, Supabase, Playwright, `salestool` schema, specific
> env vars). When adopting the process elsewhere, **rewrite `/validate`** to that project's real gate
> commands. The *shape* (lint → typecheck → build → test, fail fast on each) ports; the contents do
> not.

### 5.4 `/handoff` + `/pickup` — session continuity (**user-level, personal**)

Long features span multiple sessions (`/clear`, new window, context compaction). Handoff/pickup is how
the full working context survives a session boundary. **Ready-to-install, repo-agnostic versions of
both command files are in [§12](#12-appendix-portable-handoff--pickup-command-files)** — drop them in
`~/.claude/commands/` (user-level, available everywhere) or `.claude/commands/` (repo-local). The
versions in §12 already have the original author's name and hardcoded vault paths stripped.

**`/handoff <name>`** writes a self-contained briefing to `.handoffs/<name>.md` (gitignored — session
state, never part of a PR). The defining principle: **it's written to the next Claude, not the user** —
brief a smart colleague who walked in cold (file paths *with line numbers*, exact commands, the *why*
behind decisions). **Never delegate understanding** — write the actual next 1–3 actions, not "figure
out what's next." It requires a kebab-case name (won't infer one) and first captures live state
(`date`, `pwd`, `git status`, `git log`). The file's fixed structure:

| Section | Contents |
|---|---|
| Header | topic + timestamp, "read this whole file first" note, working dir |
| The Goal | the *underlying* objective, 1–2 sentences |
| Where We Are Right Now | concrete state: done / half-written (file:line) / blocked / running |
| What Has Been Tried (and Rejected) | dead ends *with reasons* |
| Decisions Made This Session | non-obvious approved choices — don't re-litigate |
| Next Steps | the actual next 1–3 actions |
| Load This Context Before Responding | exact reads/commands to run *in parallel before responding* |
| Gotchas and Constraints | looks-simple-but-isn't; already-verified; preferences |
| Open Questions | anything blocked on the human |

**`/pickup <name>`** (or bare `/pickup` to list) resumes: resolve the handoff → **freshness check**
(under 6h proceed; 6–24h note drift; over 24h warn + ask) → **load the listed context in one parallel
block** → **sanity-check against reality** (re-run `git status`, confirm line numbers, check
background processes) → report back in <200 words → **wait for the go-ahead** (it re-establishes
context; it does not auto-execute). Named `/pickup` (not `/resume`) to avoid Claude Code's built-in
`/resume`. Handoffs persist; don't delete after reading.

> Durable knowledge that should outlive the session goes into the **slice plan's standing-context
> section**, not the handoff. When committing, **stage explicit paths — never `git add -A`** (it
> sweeps untracked handoff files into the PR).

---

## 6. Memory (persistent across sessions)

Claude Code keeps a per-project file-based **memory** (notes that persist across sessions, indexed in
a `MEMORY.md`). Use it for facts that are **non-obvious and durable** but *not* already in the repo:
hard-won gotchas (the worktree/env trap, lint false-positive patterns), team/role facts, ongoing
project state, external references, confirmed approaches ("do X not Y, because Z").

**Don't** store what the repo already records (code structure, git history, `CLAUDE.md` content) or
anything that only matters to one conversation. Update the existing entry rather than duplicating;
delete entries that turn out wrong.

---

## 7. Small changes (the lightweight path)

Not everything is a multi-slice overhaul. For a focused one-off:

```
branch off main  →  make the change  →  validation gate  →  open PR  →  CodeRabbit loop  →  human merge
```

Still branch (never commit straight to `main`), still run the gate, still work CodeRabbit, still
verify before claiming done. Just skip the brainstorm/slice/plan ceremony. Outside slice work, only
commit/PR when asked.

---

## 8. The `CLAUDE.md` file (per repo)

`CLAUDE.md` at the repo root is the **one project-specific document** — the canonical source of
conventions, schema rules, and the file map that Claude loads automatically every session. This
playbook is portable; `CLAUDE.md` is not.

A good `CLAUDE.md` covers: **project overview** + stack; **critical invariants** (the easy-to-get-wrong
things — "the DB schema is X, not `public`"; "amounts in cents"; auth model); the **dev workflow**
(link to *this* file + repo-specific deviations); **dev commands** *and which gate commands don't cover
which directories*; **architecture & key concepts**; a **file map**; **constraints** (RLS, append-only
tables, trigger-enforced rules); and **environment variables** (flagging server-side-only secrets).

**Bootstrapping a new repo:** run `/init` to generate a first-draft `CLAUDE.md` from the codebase,
then refine by hand. Keep it current — when an architectural decision is made, record it there. Note
that `/code-review` reads `CLAUDE.md` as its adherence rubric, so accurate `CLAUDE.md` rules directly
improve automated review.

---

## 9. Portability & personalization (read before copying to a new repo)

Not every piece of this setup travels the same way. Here's exactly what to do per component:

| Component | Where it lives | To use it elsewhere |
|---|---|---|
| `superpowers` skills | user-level plugin (global) | Install the plugin once per machine — then available in every repo. **Portable as-is.** |
| `/code-review` | org marketplace plugin (global) | Installed globally; works in any repo. **Portable as-is.** |
| CodeRabbit | org GitHub setting | **Already on** for every org repo — nothing to do. |
| This `development-process.md` | **single canonical copy** in `IntegralOrg/ClaudeCodeSystem-Cloud` | **Do NOT copy it.** Link to it from the new repo's `CLAUDE.md`. It used to be copied per-repo; the copies drifted and the drift silently broke the CodeRabbit loop (see §5.2) for months. One copy, one place to fix it. |
| `/rabbit` | **repo-local** `.claude/commands/rabbit.md` | Copy the file **from a repo that already has the current version**, or from `~/.claude/commands/rabbit.md`. All copies must stay identical: verify with `md5` against another repo before you trust it. The DB-migration rule is conditional and safe to leave in on a non-Supabase stack. |
| `/validate` | **repo-local** `.claude/commands/validate.md` | **Rewrite.** It encodes *this* repo's gate (Vite/Supabase/Playwright/specific env vars). Keep the shape (lint→typecheck→build→test, fail-fast), replace the contents with the new project's real commands. |
| `/handoff`, `/pickup` | **user-level** `~/.claude/commands/` | The author's originals reference a personal Obsidian "Brain" vault path and name. **Use the portable versions in [§12](#12-appendix-portable-handoff--pickup-command-files)** — name and vault paths already stripped, memory resolution generalized to `~/.claude/projects/<escaped-cwd>/memory/`. Save them to `~/.claude/commands/` (everywhere) or `.claude/commands/` (this repo only). |
| `.handoffs/` | repo root, **gitignored** | Add `.handoffs/` to the new repo's `.gitignore`. |
| Spec/plan locations | `docs/superpowers/specs/`, `docs/superpowers/plans/` | superpowers defaults; create the dirs (or set a user preference to override). |
| MCP servers | Claude Code settings | Configure per repo's needs (DB MCP, `context7`, project MCP); each has its own env vars/secrets. |

**The two things most likely to silently break for a teammate on a new repo:** (1) `/validate` running
the wrong (Integral) gate — rewrite it; and (2) `/handoff`/`/pickup` pointing at the author's personal
memory path — install the portable versions from
[§12](#12-appendix-portable-handoff--pickup-command-files) instead. Fix both before handing the setup
to someone else.

---

## 10. Quick-reference cheat sheet

**Starting a big feature**
1. `brainstorming` → lock decisions → spec in `docs/superpowers/specs/`
2. Slice the plan (`[ ]`/`[~]`/`[x]` + PR# per slice)
3. Per slice: verify-vs-live → `writing-plans` → `subagent-driven-development` (in a worktree)
4. Two-stage review → verify each finding → `/validate` gate
5. `finishing-a-development-branch` → open PR → `/rabbit` loop → resolve all threads
6. `/handoff` → human merge → flip slice to `[x]`

**Always**
- Invoke the relevant skill *before* acting (process skills before implementation skills).
- Verify the plan against live schema/consumers before coding.
- Verify every review finding against live code before fixing — no performative agreement, no thanks.
- Run the command and show output before claiming anything passes.
- Test first (TDD); root-cause before fixing (systematic-debugging).
- Branch off `main`; stage explicit paths (never `git add -A`).
- Run the full gate (including sub-package gates) before any PR.

**Never**
- Commit straight to `main` · flip a slice to `[x]` before it merges.
- Write code before brainstorming approves the design, or before a failing test exists.
- Blindly implement a reviewer/CodeRabbit suggestion · pre-judge a reviewer's findings.
- Dispatch implementer subagents in parallel · make a subagent read the whole plan.
- Trust a pre-written plan over the live schema · claim done without running verification.
- Attempt a 4th fix after 3 have failed — question the architecture instead.

---

## 11. Adopting this on a new repo — checklist

- [ ] Claude Code installed.
- [ ] `superpowers` plugin installed (verify `/superpowers:brainstorming` loads).
- [ ] `/code-review` available (org marketplace plugin).
- [ ] CodeRabbit — already on by default; confirm it comments on your first PR.
- [ ] MCP servers configured (DB, `context7`, project MCP).
- [ ] `CLAUDE.md` written (`/init` then refine) with invariants, commands, file map, env vars.
- [ ] This `development-process.md` **linked** (not copied) from the new repo's `CLAUDE.md`.
- [ ] `.handoffs/` added to `.gitignore`; `docs/superpowers/specs/` + `docs/superpowers/plans/` exist.
- [ ] `/validate` **rewritten** for this repo's real gate (don't copy Integral's verbatim).
- [ ] `/rabbit` copied and its DB-migration rule adapted to this stack (or removed).
- [ ] `/handoff` + `/pickup` installed from the portable versions in [§12](#12-appendix-portable-handoff--pickup-command-files).

---

## 12. Appendix: portable `/handoff` & `/pickup` command files

These are ready-to-install, repo-agnostic versions of the two session-continuity commands described in
[§5.4](#54-handoff--pickup--session-continuity-user-level). The author's personal name and hardcoded
Obsidian-vault memory path have been removed; memory resolution uses the project-generic pattern. To
install, save each block to a `.md` file:

- **Everywhere (recommended):** `~/.claude/commands/handoff.md` and `~/.claude/commands/pickup.md`
  (user-level — available in every repo).
- **This repo only:** `.claude/commands/handoff.md` and `.claude/commands/pickup.md`.

`$ARGUMENTS` is the text the user types after the command (the handoff name). The blocks are wrapped in
four backticks so their internal code fences render literally — copy everything *between* the
four-backtick lines.

### 12.1 `handoff.md`

````markdown
# Handoff

Hand off the current conversation to a fresh Claude Code session (new window, post-clear, or after
context compaction). Writes a self-contained briefing to `.handoffs/<name>.md` that a new agent can
read cold and continue the work without losing momentum.

**Required argument:** a short name for the handoff (e.g., `/handoff workflow-fix`). This becomes the
filename. Use kebab-case or short descriptive words. Spaces are converted to hyphens automatically.

**If no name is provided, stop and ask for one.** Do not infer a name or proceed without one. The name
is how the user finds this handoff later across multiple projects.

Name: $ARGUMENTS

---

## Principles

The handoff file is written **to the next Claude**, not to the user. It should read like a briefing for
a smart colleague who just walked in: they haven't seen this conversation, don't know what's been
tried, don't know why this matters. Be specific. Include file paths with line numbers, exact commands,
and the reasoning behind decisions, not just the decisions themselves.

**Never delegate understanding.** Don't write "figure out what needs to happen next." Write what
specifically needs to happen next, with enough context that the next agent can make judgment calls.

---

## Step 0: Validate the Name

Check that the name argument is not empty.

- **If empty:** Tell the user: `Please provide a name for this handoff. Example: /handoff workflow-fix`
  and stop. Do not proceed.
- **If provided:** Sanitize the name: lowercase, replace spaces with hyphens, strip special characters
  except hyphens and underscores. This becomes `HANDOFF_NAME`.

Set the handoff path: `.handoffs/HANDOFF_NAME.md` (relative to the current working directory). Create
the `.handoffs/` directory if it does not exist.

**If a file with that name already exists**, tell the user and ask whether to overwrite it, pick a
different name, or read the existing one instead (run /pickup).

---

## Step 1: Synthesize Current State

Before writing anything, silently review the conversation and answer these for yourself:

1. **What is the goal?** One sentence — the underlying objective, not just the immediate task.
2. **What have we done so far?** Concrete actions: files edited, commands run, decisions made. Include
   file paths and line numbers.
3. **What was tried and rejected?** Dead ends the next agent should not re-explore, and *why*.
4. **What is the current state?** Half-written code? Uncommitted changes? Background processes? Open
   questions waiting on the user?
5. **What are the next concrete steps?** The actual next 1-3 actions. If blocked, on what.
6. **What context does the next agent need to pull?** Specific files, memory entries, git state,
   external systems — with exact paths and commands.
7. **What gotchas or constraints apply?** Decisions made, approaches rejected, things that look simple
   but aren't, things already verified.

If any of these are unclear, **ask the user before writing the handoff.** A vague handoff wastes the
next session's context budget on re-discovery.

## Step 2: Verify Current Environment State

Run these in parallel and include relevant output in the handoff:

- `date` — timestamp the handoff
- `pwd` — capture the working directory
- `git status` and `git log --oneline -5` — uncommitted state and recent commits
- Check for running background processes the next agent will inherit (builds, dev servers)
- If work touches a specific file, note its current length and any in-progress edits

## Step 3: Write the Handoff File

Write to `.handoffs/HANDOFF_NAME.md` in the current working directory. Use this structure:

```markdown
# Handoff -- [Topic] -- [YYYY-MM-DD HH:MM]

> **For the next Claude reading this:** The user cleared context or opened a new window. You are
> continuing work mid-stream. Read this entire file before taking any action. Then pull the context
> listed in "Load This Context" before responding. Do not ask the user to re-explain what is already
> documented here.

**Working directory:** `[cwd from pwd]`
**Project context:** [repo / area of the codebase, or "none"]

## The Goal
[One or two sentences. Why this work matters, what success looks like.]

## Where We Are Right Now
[Concrete state: done, in-progress, blocked. File paths and line numbers. If code is half-written, say
exactly where. If something runs in the background, say so. If waiting on the user, say what.]

## What Has Been Tried (and Rejected)
[Dead ends with reasons. Skip this section if nothing was rejected.]

## Decisions Made This Session
[Non-obvious choices the user approved. Things the next agent should NOT re-litigate. Include the why.]

## Next Steps
1. [First concrete action]
2. [Second concrete action]
3. [Third, or "then check in with the user before proceeding"]

## Load This Context Before Responding
Run these reads/commands in parallel at the start of your response, before saying anything:
- Read: `[path]` -- [why]
- Read: `[path]:[lineStart]-[lineEnd]` -- [why]
- Bash: `git status` in `[dir]` -- [why]
- Check memory: `[memory filename]` -- [why]
[Only list context actually needed. Don't pad.]

## Gotchas and Constraints
- [Things that look simple but aren't]
- [Things already verified so you don't need to re-verify]
- [User preferences specific to this work]
- [External state that might change]

## Open Questions
[Questions blocking progress that are waiting on the user. Omit if none.]

---
*Handoff written [timestamp]. Session topic: [topic]. If this file is older than a few hours when you
read it, verify it's still current before acting on it; state may have changed.*
```

## Step 4: Confirm With the User

After writing the file, show a compact summary:

```
Handoff saved: .handoffs/HANDOFF_NAME.md
  Goal: [one line]
  Next steps: [1-line summary of first next action]
  Context to pull: [count] files, [count] commands
To resume: /pickup HANDOFF_NAME
To see all handoffs: /pickup
```

Do not dump the full file content into the chat. The point is that the file exists and is ready for the
next session.

---

## Notes on Using This

- **When to run:** Before `/clear`, before closing a window mid-task, or when context is getting long
  and you want a checkpoint before compaction.
- **Named and persistent:** Each handoff gets its own file in `.handoffs/`. You can have many active
  handoffs across different workstreams. Old handoffs stick around until manually deleted.
- **Not for durable project state:** Ongoing project knowledge belongs in your plan/standing-context
  docs or issue tracker. Handoff is for the immediate thread of work the current session is in the
  middle of.
- **Cleanup:** Periodically review `.handoffs/` and delete stale handoffs that are no longer relevant.
````

### 12.2 `pickup.md`

````markdown
# Pickup

Pick up a handed-off conversation. Reads a named handoff from `.handoffs/` in the current working
directory, pulls the context it lists, and reports back where we left off so the user can keep moving
without re-explaining anything.

Pair with `/handoff` (which writes the file in the previous session). Named `/pickup` (not `/resume`)
to avoid shadowing Claude Code's built-in `/resume` session picker.

**Optional argument:** the name of the handoff to resume (e.g., `/pickup vault-cleanup`). This is the
filename `/handoff` wrote, minus the `.md`. If no name is given, list the available handoffs and ask
which to resume.

Name: $ARGUMENTS

---

## Step 0: Resolve Which Handoff to Read

Handoffs live in `.handoffs/<name>.md` relative to the current working directory.

**If a name is provided:** Sanitize it the same way `/handoff` does (lowercase, spaces to hyphens,
strip special characters except hyphens/underscores) → `HANDOFF_NAME`. Target: `.handoffs/HANDOFF_NAME.md`.
- If it exists, go to Step 1.
- If not, list what's actually in `.handoffs/` (`ls -t .handoffs/*.md 2>/dev/null`) and ask the user
  which one. Do not silently fall back to a different file.

**If no name is provided:** List available handoffs and ask which to resume. Run
`ls -t .handoffs/*.md 2>/dev/null` and, for each, read its `# Handoff -- [Topic] -- [timestamp]` header
to show topic + age:

```
Available handoffs in .handoffs/:
  1. [name] -- [topic] -- [relative age]
  2. [name] -- [topic] -- [relative age]
Which one? (or tell me what you're working on and I'll skip the handoff)
```

- If `.handoffs/` is empty or missing, tell the user there's nothing to resume and stop.
- If there is exactly one handoff, you may name it and proceed straight to Step 1 (still report which
  one you picked).

> **Legacy note:** Older setups wrote a single `handoff.md` at the working-directory root, or used
> `.claude/handoffs/<name>.md`. If `.handoffs/` is missing/empty but `.claude/handoffs/` has files,
> read from there and suggest moving them. Do NOT read a root `handoff.md` unless the user explicitly
> points you at it — a stale root file will hijack the resume.

## Step 1: Read the Handoff File

Read the resolved `.handoffs/HANDOFF_NAME.md`.

- **Note the "Working directory" line** from the header. If it doesn't match the current `pwd`, tell
  the user and ask whether to `cd` into the handoff's working dir or operate from the current one
  before loading any context.

## Step 2: Freshness Check

Run `date` and compare to the timestamp in the handoff header.

- **Under 6 hours old:** Fresh. Proceed.
- **6-24 hours old:** Note it (`Handoff is [N] hours old -- state may have drifted`) but proceed.
- **Over 24 hours old:** Warn explicitly and ask whether to resume from it anyway or start fresh. Wait
  for confirmation.

## Step 3: Load the Context

Parse the `## Load This Context Before Responding` section. For each item:

- **Read:** entries — use the Read tool on the exact path (and line range if given).
- **Bash:** entries — run them.
- **Check memory:** entries — Read the file from the memory directory for the current project. The path
  follows the pattern `~/.claude/projects/<escaped-cwd>/memory/<filename>`, where `<escaped-cwd>` is
  the absolute working-directory path with `/` replaced by `-`.
- **Grep/Glob:** entries — use the appropriate tool.

Run all independent reads/commands **in parallel** in a single tool-call block. If any context item
fails (file moved, command errors, memory entry missing), note it but continue — a stale pointer is
information: it tells you something changed since the handoff was written.

## Step 4: Sanity-Check Against Reality

The handoff is a snapshot. Before trusting it, verify the parts that could have changed:

- If it references uncommitted git state, run `git status` and compare.
- If it references a file at a specific line number, confirm the line numbers still match.
- If it says "waiting on the user to decide X", note that the question is still open.
- If it says something is "running in the background", check whether it actually still is.

If reality diverges in a way that affects the next steps, flag it in your summary.

## Step 5: Report Back

Give a compact resume summary. Target: under 200 words.

```
Resumed from handoff '[HANDOFF_NAME]' (written [relative time]).
**Goal:** [one line from handoff]
**Where we left off:** [2-3 sentences in your own words, not a copy-paste]
**Loaded context:** [N files, M commands] -- [one-line summary of anything surprising, or "matches handoff"]
**Next step:** [first concrete action from the handoff's Next Steps]
[If open questions for the user remain, list them as a short bulleted block. Otherwise omit.]
[If reality diverged from the handoff, flag it in 1-2 lines. Otherwise omit.]
Ready to continue. Want me to proceed with [next step], or something different?
```

Do not dump the full handoff into the chat. Your job is to prove you understood it and are ready to
pick up the thread.

## Step 6: Wait for Go-Ahead

Stop after the summary. Wait for the user to confirm or redirect before taking any action on the actual
work. Resuming re-establishes shared context; it does not auto-execute.

---

## Notes

- **Don't delete the handoff file** after reading — leave it as a fallback until it's overwritten
  (same name) or manually deleted.
- **Handoffs are named and persistent.** `.handoffs/` can hold many across workstreams. `/pickup <name>`
  targets one; `/pickup` with no args lists them.
- **If the handoff's "Working directory" differs from `pwd`**, ask whether to operate from the current
  directory or the recorded one.
- **If `.handoffs/` is empty**, don't synthesize a pickup — just say there's nothing to resume.
````

---

*Copy this file freely into any repo. The process is the product. Read §9 before trusting the
commands on a new repo.*
