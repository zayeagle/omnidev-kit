---
description: OmniDev trigger gate for Claude Code — /od prefix OR explicit skill invoke only. Resume via /od re only.
alwaysApply: true
---

# OmniDev — Claude Code Trigger Gate

→ Spec: `skills/od/engine/trigger-gate.md` (or `.claude/skills/od/engine/trigger-gate.md`)

## ACTIVATE — Signal A or B only

1. **Signal A**: Message starts with `/od`
2. **Signal B**: `od/SKILL.md` loaded into active context this turn

No session-context inference. No bare `1`/`n`/`continue`.

## Advance & resume

| Action | Command |
|--------|---------|
| Resume / crash recovery | `/od re` |
| Next phase | `/od n` |
| Revise | `/od ad` |

Checkpoint → `AskUserQuestion` → STOP → user sends `/od` command or UI pick.

## DO NOT ACTIVATE

Normal chat without `/od` and without skill invoke. Do not touch `docs/omnidev-state/**`.

## Platform notes

- Sub-agents: `Task` tool (SKILL.md §F.3)
- MCP: `.claude/mcp.json` or `~/.claude/mcp.json` (§F.6)
