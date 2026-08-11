#!/bin/sh
# install.sh — install repo skills into any agent's skills directory.
# Agent-agnostic: works for Claude Code, OpenClaw, Cursor, Hermes, and
# any agent that reads ~/.agents/skills. No credentials, no platform deps.
#
# Usage:
#   ./install.sh            auto-detect: install into every agent dir present
#   ./install.sh --all      install into ALL known agent dirs (creates them)
#   ./install.sh --copy     copy instead of symlink (default: symlink)
#   ./install.sh --list     show target dirs and install state
#
# Canonical home is this repository. Symlinks keep one source of truth;
# use --copy only for agents that cannot follow symlinks.

set -u

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MODE=symlink
ACTION=auto

for arg in "$@"; do
  case "$arg" in
    --all) ACTION=all ;;
    --copy) MODE=copy ;;
    --list) ACTION=list ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

# Known agent skills roots. Hermes uses a category subdir.
AGENT_DIRS="
$HOME/.claude/skills
$HOME/.openclaw/skills
$HOME/.agents/skills
$HOME/.cursor/skills
$HOME/.hermes/skills/productivity
"

# Collect skills: every dir under skills/ that contains SKILL.md
SKILLS=""
for d in "$REPO_DIR"/skills/*/; do
  [ -d "$d" ] || continue
  [ -f "$d/SKILL.md" ] || continue
  SKILLS="$SKILLS $d"
done

if [ -z "$SKILLS" ]; then
  echo "no skills found under $REPO_DIR/skills/" >&2
  exit 1
fi

list_state() {
  dir="$1"
  if [ -d "$dir" ]; then
    echo "PRESENT  $dir"
  else
    echo "absent   $dir"
  fi
}

install_one() {
  target_dir="$1"
  skill_dir="$2"
  name=$(basename "$skill_dir")
  dest="$target_dir/$name"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "  exists  $dest (skipped)"
    return 0
  fi
  mkdir -p "$target_dir" || { echo "  FAIL    mkdir $target_dir" >&2; return 1; }
  if [ "$MODE" = copy ]; then
    cp -R "$skill_dir" "$dest" && echo "  copied  $dest" || { echo "  FAIL    cp $skill_dir" >&2; return 1; }
  else
    ln -s "$skill_dir" "$dest" && echo "  linked  $dest" || { echo "  FAIL    ln $skill_dir" >&2; return 1; }
  fi
}

if [ "$ACTION" = list ]; then
  echo "repo: $REPO_DIR"
  echo "skills:"
  for s in $SKILLS; do echo "  - $(basename "$s")"; done
  echo "targets:"
  for d in $AGENT_DIRS; do
    [ -n "$d" ] || continue
    list_state "$d"
  done
  exit 0
fi

for d in $AGENT_DIRS; do
  [ -n "$d" ] || continue
  if [ "$ACTION" = all ] || [ -d "$d" ]; then
    echo "== $d"
    for s in $SKILLS; do
      install_one "$d" "$s"
    done
  fi
done

echo "done. Re-run after 'git pull' to pick up new skills."
