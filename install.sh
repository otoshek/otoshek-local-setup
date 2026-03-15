#!/bin/bash
# Installs the otoshek-local-setup skill globally for Claude Code.
# Run this after pulling changes from the repo.
#
# Usage: ./install.sh

SKILL_SRC="$(cd "$(dirname "$0")/skills/otoshek-local-setup" && pwd)"
SKILL_DEST="$HOME/.claude/skills/otoshek-local-setup"

mkdir -p "$SKILL_DEST"
cp -r "$SKILL_SRC/." "$SKILL_DEST/"
echo "Skill installed to $SKILL_DEST"
