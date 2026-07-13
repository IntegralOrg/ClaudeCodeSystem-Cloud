Work the CodeRabbit review loop on the current PR: fetch open review threads, triage each one, fix what is real, then close the loop on GitHub and verify it closed.

## Non-optional completion rule

The loop is NOT complete when the code is fixed. It is complete when:
- Every targeted thread reports `isResolved: true` on a re-query, or is explicitly documented as intentionally unresolved with a reason, AND
- The fixes are pushed to the remote, AND
- A re-review has been requested and has landed.

Fixing code and not resolving the thread is the most common failure of this loop. Pushing a fix and not requesting re-review is the second most common. Do not declare success without re-querying.

## Workflow

1. **Resolve the PR and the pushed state first.**
   - Commit: `git rev-parse HEAD`
   - Confirm it is actually on the remote: `git rev-parse origin/<branch>` must equal `HEAD`, and `git status --porcelain` must be empty. If not, commit and push before anything else. Work that is not on the remote cannot be reviewed.
   - PR for commit: `gh api repos/{owner}/{repo}/commits/{sha}/pulls`

2. **Fetch OPEN review threads.**
   - GraphQL `pullRequest.reviewThreads`, keep threads where `isResolved == false` and the first comment's `author.login` contains `coderabbit`.
   - **Filter on `isResolved == false`. Never filter on `comment.commit.oid == HEAD`.** CodeRabbit anchors each comment to the commit it reviewed. The moment you push a fix, `HEAD` moves and every open comment is anchored to an older commit, so a commit-equality filter matches nothing and you will wrongly conclude there is nothing left to do. Open is open regardless of which commit it was raised against.

3. **Triage.** Map each thread to its file and lines, then classify:
   - `Fix/Implement`: a real correctness, reliability, security, data-integrity, or meaningful maintainability issue.
   - `Skip`: false positive, redundant, low-value churn, or conflicts with current architecture or product intent.

   Verify every finding against the live code before accepting it. CodeRabbit produces false positives, and a finding that was true two commits ago may already be fixed.

4. **For each item, give a short reason for the decision.** If an item is ambiguous, risky, or needs product direction, stop and ask targeted questions before implementing.

5. **Implement the approved fixes.**

   **Rewrite the block, do not patch per-comment.** When several comments land on the same interdependent region (prose rules, a config block, a state machine), do NOT apply them one at a time. Interacting rules patched individually contradict each other, CodeRabbit correctly flags the new contradiction, and the loop eats itself for round after round. Read the whole block, understand how the comments interact, and rewrite it coherently once.

6. **Push.** Verify `origin/<branch>` equals `HEAD` afterward. A rejected or forgotten push silently ends the loop.

7. **Close the loop on GitHub, in this order:**
   - Reply on each thread with what fixed it and the commit SHA: `POST /repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}/replies`
   - Resolve each thread: GraphQL `resolveReviewThread(input:{threadId})`
   - Request re-review by posting an issue comment with the body **`@coderabbitai review`**.

     **The trigger is `@coderabbitai review`. It is NOT `/rabbit`.** `/rabbit` is this local command; CodeRabbit does not understand it, and posting it produces a no-op comment that looks like the trigger fired when it did not. CodeRabbit is incremental and will only review commits it has not seen, so push before you trigger.

8. **Verify.** Re-query the same thread IDs and confirm `isResolved: true` on every one. Then confirm a new CodeRabbit review has landed on the current commit. Re-review can lag by 10 to 15 minutes; poll, do not assume.

9. **Repeat** from step 2 until a review lands with zero open threads. Then stop. Merging is an explicit human decision, never yours.

10. If no open CodeRabbit threads are found, say so explicitly and stop. Never ask for a manual `rabbit.md` paste.

## Migration rule (strict, applies where the repo has DB migrations)

If a finding suggests changing an existing migration in `supabase/migrations`, do not edit the old migration file. Create a NEW migration that applies the fix, so remote and local migration history stay in sync.

## Output format

- `Fix/Implement`: bullets with file paths and the actual change made.
- `Skip`: bullets with a short rationale each.
- `Questions`: only when a decision is needed before proceeding.
- `Source`: PR URL, commit SHA, and the comment links used for triage.
- `Loop status`: threads resolved (n/n), push confirmed, re-review requested, re-review result.

## Auth notes

- These repos are private; unauthenticated API calls return 404.
- Prefer `gh` CLI. If unavailable, get credentials with `printf 'protocol=https\nhost=github.com\n\n' | git credential fill` and call REST/GraphQL with `Authorization: Basic <base64(user:token)>`.
