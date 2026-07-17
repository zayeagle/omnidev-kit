#!/usr/bin/env bash
# OmniDev kit compliance checks (static)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0
fail() { echo "FAIL: $*" >&2; FAILED=$((FAILED+1)); }
ok() { echo "OK:   $*"; }

SRC="$ROOT/skills/od"
DST="$ROOT/.cursor/skills/od"

if [[ ! -f "$SRC/SKILL.md" ]]; then fail "skills/od/SKILL.md missing"; exit 1; fi

if [[ ! -d "$DST" ]]; then
  fail ".cursor/skills/od missing — run scripts/sync-skills.sh"
else
  while IFS= read -r -d '' f; do
    rel="${f#$SRC/}"
    other="$DST/$rel"
    if [[ ! -f "$other" ]]; then
      fail "Missing in .cursor: $rel"
    elif ! cmp -s "$f" "$other"; then
      fail "Drift: $rel"
    fi
  done < <(find "$SRC" -type f -print0)
  while IFS= read -r -d '' f; do
    rel="${f#$DST/}"
    if [[ ! -f "$SRC/$rel" ]]; then
      fail "Extra in .cursor: $rel"
    fi
  done < <(find "$DST" -type f -print0)
  [[ $FAILED -eq 0 ]] && ok "skills/od ↔ .cursor/skills/od identical" || true
fi

R1="$ROOT/rules/01-omnidev-workflow.mdc"
R2="$ROOT/.cursor/rules/01-omnidev-workflow.mdc"
if [[ ! -f "$R2" ]]; then fail ".cursor/rules/01 missing"
elif ! cmp -s "$R1" "$R2"; then fail "rules/01 ↔ .cursor/rules/01 drift"
else ok "Cursor trigger rule synced"
fi

check_pat() {
  local file="$1"; shift
  local text
  text=$(cat "$ROOT/$file")
  local miss=()
  for pat in "$@"; do
    if ! grep -qE "$pat" <<<"$text"; then miss+=("$pat"); fi
  done
  if [[ ${#miss[@]} -gt 0 ]]; then fail "$file missing: ${miss[*]}"
  else ok "$file fixtures"
  fi
}

check_pat "skills/od/engine/trigger-gate.md" '\[\\/\$\]od' 'Explicit non-activation feedback' 'STOP' 'pending_decision' 'A-index'
check_pat "skills/od/engine/activation.md" '\[\\/\$\]od' 'STOP' 'AskUserQuestion' 'WAIT'
check_pat "skills/od/engine/interactive-prompt.md" 'STOP' 'WAIT' 'AskQuestion' 'phase0_s_fastpath' 'Decision Matrix' 'deploy_consent' 'Markdown Fallback Table' 'box-drawing' 'pending_decision'
check_pat "skills/od/phases/00-assessment.md" 'phase0_s_fastpath'
check_pat "skills/od/engine/board.md" 'autopilot' 'Resume-after-confirm' 'Hard gates' '/od auto'
check_pat "skills/od/phases/02-planning.md" 'phase2_plan_ready'
check_pat "skills/od/phases/05-deploy.md" 'deploy_consent' 'deploy_prod'
check_pat "docs/omnidev-state/config.json" 'codex_auto_resolve'
check_pat "skills/od/SKILL.md" '\$od' '/od'
check_pat "rules/03-omnidev-workflow.codex.md" '\$od' '/od'
check_pat "AGENTS.md" '\$od' '/od'

LINES=$(wc -l < "$ROOT/skills/od/engine/interactive-prompt.md" | tr -d ' ')
if [[ "$LINES" -gt 320 ]]; then fail "interactive-prompt.md too large ($LINES lines; budget 320)"
else ok "interactive-prompt.md size ($LINES lines)"
fi

if grep -qE '非阻塞（checkpoint / skill / phase0）：`autoResolutionMs`' "$ROOT/skills/od/engine/interactive-prompt.md"; then
  fail "interactive-prompt.md still recommends autoResolutionMs for non-blocking"
elif ! grep -qE 'do not set.*autoResolutionMs|forbid.*autoResolutionMs|Omit the field' "$ROOT/skills/od/engine/interactive-prompt.md"; then
  fail "interactive-prompt.md missing default-off autoResolution rule"
else
  ok "autoResolutionMs default-off"
fi

if grep -q 'Skip popup entirely' "$ROOT/skills/od/phases/00-assessment.md"; then
  fail "00-assessment.md still skips S-level popup"
else
  ok "S-level popup required"
fi

for f in skills/od/engine/interactive-prompt.md skills/od/engine/activation.md; do
  if grep -qE 'auto-continue default|自动继续默认' "$ROOT/$f" 2>/dev/null; then
    # Only fail on the Chinese phrase if present
    if grep -qP '[\x{4e00}-\x{9fff}]' "$ROOT/$f" 2>/dev/null || grep -qF $'自动继续默认' "$ROOT/$f" 2>/dev/null; then
      : # checked below in CJK scan
    fi
  fi
  ok "$f scanned"
done

# No CJK in SSOT
CJK_HITS=$(find "$ROOT/skills/od" "$ROOT/rules" -type f \( -name '*.md' -o -name '*.mdc' \) -print0 | xargs -0 grep -lP '[\x{4e00}-\x{9fff}]' 2>/dev/null || true)
if [[ -n "$CJK_HITS" ]]; then
  fail "CJK characters found in: $CJK_HITS"
else
  ok "No CJK in skills/od or rules"
fi

if [[ $FAILED -gt 0 ]]; then
  echo ""
  echo "$FAILED check(s) failed. Run: bash scripts/sync-skills.sh" >&2
  exit 1
fi
echo ""
echo "All compliance checks passed."
exit 0
