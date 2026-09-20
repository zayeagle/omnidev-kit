#!/usr/bin/env bash
# Sync skills/od (SSOT) -> .cursor/skills/od, rules -> .cursor/rules,
# and (auto/opt-in) the DSH bundle $DSH_HOME/skills/od (default ~/.dsh/skills/od).
# Usage: bash scripts/sync-skills.sh [--dsh|--no-dsh]
#   default: sync DSH only when the DSH home directory exists
# Requires bash. Windows: run scripts/sync-skills.ps1, or this script from Git Bash / WSL.
if [ -z "${BASH_VERSION:-}" ]; then
  echo "sync-skills.sh requires bash, not sh/dash. Run: bash $0" >&2
  exit 2
fi
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
test -f "$ROOT/skills/od/SKILL.md"

SYNC_DSH=auto
for arg in "$@"; do
  case "$arg" in
    --dsh) SYNC_DSH=yes ;;
    --no-dsh) SYNC_DSH=no ;;
    *) echo "Unknown option: $arg (expected --dsh or --no-dsh)" >&2; exit 2 ;;
  esac
done

echo "Syncing skills/od -> .cursor/skills/od"
rm -rf "$ROOT/.cursor/skills/od"
mkdir -p "$ROOT/.cursor/skills"
cp -R "$ROOT/skills/od" "$ROOT/.cursor/skills/od"

echo "Syncing Cursor rules"
mkdir -p "$ROOT/.cursor/rules"
cp "$ROOT/rules/01-omnidev-workflow.mdc" "$ROOT/.cursor/rules/01-omnidev-workflow.mdc"

DSH_HOME="${DSH_HOME:-$HOME/.dsh}"
if [[ "$SYNC_DSH" == "auto" ]]; then
  if [[ -d "$DSH_HOME" ]]; then SYNC_DSH=yes; else SYNC_DSH=no; fi
fi
if [[ "$SYNC_DSH" == "yes" ]]; then
  # Full overwrite, subdirectories included: DSH discovers only <root>/<name>/SKILL.md,
  # so engine/, phases/ and templates/ must ride along as bundle resources.
  echo "Syncing skills/od -> $DSH_HOME/skills/od"
  mkdir -p "$DSH_HOME/skills"
  rm -rf "$DSH_HOME/skills/od"
  cp -R "$ROOT/skills/od" "$DSH_HOME/skills/od"
else
  echo "Skip DSH sync (pass --dsh to install into \$DSH_HOME/skills/od)"
fi

echo "OK: skills + Cursor rule synced."
echo "Next: bash scripts/check-compliance.sh"
