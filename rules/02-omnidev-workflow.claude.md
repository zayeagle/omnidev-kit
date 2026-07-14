---
description: OmniDev trigger gate for Claude Code — /od or $od line-start prefix only. Skill invoke without /od does NOT activate.
alwaysApply: true
---

# OmniDev — Claude Code Trigger Gate

→ Spec: `skills/od/engine/trigger-gate.md` (or `.claude/skills/od/engine/trigger-gate.md`)

## ACTIVATE — Signal A only

1. **Signal A**: Message starts with `/od` (or `$od`)
2. **Not a trigger**: `od` skill body in context without `/od` prefix — reference only

No session-context inference. No bare `1`/`n`/`continue`.

Bare workflow-looking replies → one-line tip only: `⚠️ OmniDev is not active. Send /od n (or /od re).`

## Advance & resume

| Action | Command |
|--------|---------|
| Resume / crash recovery | `/od re` |
| Next phase | `/od n` |
| Revise | `/od ad` |

Checkpoint → `AskUserQuestion` → **STOP — WAIT** → UI pick or `/od` command.

## DO NOT ACTIVATE

Normal chat without `/od`/`$od` prefix. Do not touch `docs/omnidev-state/**` as OmniDev session.

## Platform notes

- Sub-agents: `Task` tool (SKILL.md §F.3)
- MCP: `.claude/mcp.json` or `~/.claude/mcp.json` (§F.6)
