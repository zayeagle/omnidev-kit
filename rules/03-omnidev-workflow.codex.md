---
description: OmniDev trigger gate for Codex — /od, $od, or bare index with pending_decision. Skill invoke without prefix does NOT activate.
alwaysApply: true
---

# OmniDev — Codex Trigger Gate

→ Spec: `~/.codex/skills/od/engine/trigger-gate.md`

## ACTIVATE

1. **Signal A**: Message starts with `/od` **or** `$od` (equivalent) — includes `/od 1` / `$od 1`
2. **Signal A-index**: Bare `1`–`9` + session-log `pending_decision`
3. **Not a trigger**: od skill invoke without `/od`/`$od` — reference only

Bare `n`/`ad`/`continue` or digit without pending → one-line tip:
`⚠️ OmniDev is not active. Use /od 1 or $od 1 (row index), /od n, or /od re.`

## Advance & resume

| Action | Command |
|--------|---------|
| Resume / crash recovery | `/od re` or `$od re` |
| Flow board (manual default) | `$od board` / `$od board start` / `$od board next` |
| Next phase | `/od n` or `$od n` |
| Index pick | `/od 1`…`/od 9` / `$od 1`… or bare `1`…`9` (pending) |
| Full autopilot | `/od auto` / `$od auto` / `/od al` |
| Revise | `/od ad` or `$od ad` |

Checkpoint → `request_user_input` → **STOP — WAIT** on hard gates → UI pick, `$od N`, or `/od`/`$od` command; autopilot then resumes.

## DO NOT ACTIVATE

- No `/od`/`$od` / valid bare index
- Mid-sentence prefix
- Infer from chat history alone
