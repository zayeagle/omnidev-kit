---
description: OmniDev trigger gate for Codex — /od prefix OR explicit skill invoke only. Resume via /od re only.
alwaysApply: true
---

# OmniDev — Codex Trigger Gate

→ Spec: `~/.codex/skills/od/engine/trigger-gate.md`

## ACTIVATE — Signal A or B only

1. **Signal A**: Message starts with `/od`
2. **Signal B**: od skill invoked for this message

No session-context inference. No bare `1`/`n`/`continue`.

## Advance & resume

| Action | Command |
|--------|---------|
| Resume / crash recovery | `/od re` |
| Next phase | `/od n` |
| Revise | `/od ad` |

Checkpoint → `request_user_input` → STOP → user sends `/od` command or UI pick.

## DO NOT ACTIVATE

Normal chat without `/od` and without skill invoke. Do not touch `docs/omnidev-state/**`.

## Platform notes

- Sub-agents: `create_thread` + `send_message_to_thread` (§F.3)
- MCP: `list_mcp_resources` → `read_mcp_resource` (§F.6)
- Compaction: §F.8 — persist state files before long tool runs
- Enable: `[features] default_mode_request_user_input = true` in `~/.codex/config.toml`
