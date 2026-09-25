#!/usr/bin/env bash
# local-routines-backup.sh: mirror this machine's Claude desktop LOCAL scheduled
# tasks into the vault so a new machine can recreate them.
#
# WHY: a local scheduled task (Claude Desktop > Routines > New routine > Local)
# lives only on the machine that created it. The prompt is on disk at
# ~/.claude/scheduled-tasks/<name>/SKILL.md; the schedule, working folder, model,
# permission mode, worktree toggle, and "always allow" approvals live in the
# app's private state and are not exported anywhere, and the task does not
# appear in your account's cloud routine list. A crashed or replaced computer
# loses it. Cloud routines (kind Remote) belong to your account and need none
# of this.
#
# WHAT: copies every SKILL.md to
#   Resources/Reference/Local Routines/<device>/<task-name>.SKILL.md
# and removes mirrors of tasks that no longer exist, then prints the task names
# so you update the settings rows in
#   Resources/Reference/Local Routines Registry.md   (the human-maintained half)
#
# RUN (from the vault root) after creating, editing, pausing, or deleting any
# local task:
#   bash scripts/local-routines-backup.sh
# Reads app state only; writes only under the vault folder above. Works on
# macOS and Linux (no macOS-only tools required).
set -uo pipefail

VAULT="${VAULT_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SRC="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/scheduled-tasks"
raw="${LOCAL_ROUTINES_DEVICE:-$(scutil --get LocalHostName 2>/dev/null || hostname -s 2>/dev/null || hostname)}"
DEVICE="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed -E 's/-+/-/g; s/^-//; s/-$//')"
[ -n "$DEVICE" ] || DEVICE="unknown-device"
DEST="$VAULT/Resources/Reference/Local Routines/$DEVICE"

if [ ! -d "$SRC" ]; then
  echo "no local scheduled tasks on this machine ($SRC missing)"; exit 0
fi

mkdir -p "$DEST"
n=0
for d in "$SRC"/*/; do
  [ -f "$d/SKILL.md" ] || continue
  name="$(basename "$d")"
  cp "$d/SKILL.md" "$DEST/$name.SKILL.md" && n=$((n+1))
  echo "backed up: $name -> Resources/Reference/Local Routines/$DEVICE/$name.SKILL.md"
done
for f in "$DEST"/*.SKILL.md; do
  [ -e "$f" ] || continue
  name="$(basename "$f" .SKILL.md)"
  [ -d "$SRC/$name" ] || { rm -f "$f"; echo "removed stale mirror: $name"; }
done
echo "$n task prompt(s) mirrored for device '$DEVICE'."
echo "NOW update the schedule/folder/model/permission row for each task in:"
echo "  Resources/Reference/Local Routines Registry.md"
