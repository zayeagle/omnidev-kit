#!/usr/bin/env bash
# Sync skills/od (SSOT) → .cursor/skills/od and rules → .cursor/rules
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
test -f "$ROOT/skills/od/SKILL.md"

echo "Syncing skills/od -> .cursor/skills/od"
rm -rf "$ROOT/.cursor/skills/od"
mkdir -p "$ROOT/.cursor/skills"
cp -R "$ROOT/skills/od" "$ROOT/.cursor/skills/od"

echo "Syncing Cursor rules"
mkdir -p "$ROOT/.cursor/rules"
cp "$ROOT/rules/01-omnidev-workflow.mdc" "$ROOT/.cursor/rules/01-omnidev-workflow.mdc"

echo "OK: skills + Cursor rule synced."
echo "Next: bash scripts/check-compliance.sh"
