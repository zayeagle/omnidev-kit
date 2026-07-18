---
description: OmniDev trigger gate for Claude Code — /od, $od, or bare index with pending_decision. Skill invoke without /od does NOT activate.
alwaysApply: true
---

# OmniDev — Claude Code Trigger Gate

→ Spec: `skills/od/engine/trigger-gate.md` (or `.claude/skills/od/engine/trigger-gate.md`)

## ACTIVATE

1. **Signal A**: Message starts with `/od` (or `$od`) — includes `/od 1` index pick
2. **Signal A-index**: Bare `1`–`9` + session-log `pending_decision`
3. **Not a trigger**: `od` skill body without `/od` — reference only

Bare `n`/`ad`/`continue` or digit without pending → one-line tip:
`⚠️ OmniDev is not active. Use /od 1 (row index), /od n, or /od re.`

## Advance & resume

| Action | Command |
|--------|---------|
| Resume / crash recovery | `/od re` |
| Next phase | `/od n` |
| Index pick | `/od 1`…`/od 9` or bare `1`…`9` (pending) |
| Full autopilot | `/od auto` / `/od al` |
| Revise | `/od ad` |

Phase end → Handoff (next + what to do + `/od n` + skip) → `AskUserQuestion` → **STOP — WAIT** on hard gates → UI pick, `/od N`, or `/od` command; autopilot then resumes.

## DO NOT ACTIVATE

- No `/od`/`$od` / valid bare index
- Mid-sentence `/od`
- Infer from chat history alone
