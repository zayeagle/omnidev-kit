---
description: OmniDev trigger gate for Codex — /od or $od line-start prefix only. Skill invoke without prefix does NOT activate.
alwaysApply: true
---

# OmniDev — Codex Trigger Gate

→ Spec: `~/.codex/skills/od/engine/trigger-gate.md`

## ACTIVATE — Signal A only

1. **Signal A**: Message starts with `/od` **or** `$od` (equivalent)
2. **Not a trigger**: od skill invoke / SKILL body without `/od`/`$od` prefix — reference only

No session-context inference. No bare `1`/`n`/`continue`.

Bare workflow-looking replies → one-line tip only:
`⚠️ OmniDev is not active. Send /od n or $od n. Resume with /od re.`

## Advance & resume

| Action | Command |
|--------|---------|
| Resume / crash recovery | `/od re` or `$od re` |
| Next phase | `/od n` or `$od n` |
| Revise | `/od ad` or `$od ad` |

Checkpoint → `request_user_input` → **STOP — WAIT** → UI pick or `/od`/`$od` command.

## DO NOT ACTIVATE

Normal chat without `/od`/`$od` prefix. Do not touch `docs/omnidev-state/**` as OmniDev session.

## Platform notes

- Sub-agents: `create_thread` + `send_message_to_thread` (§F.3)
- MCP: `list_mcp_resources` → `read_mcp_resource` (§F.6)
- Compaction: §F.8 — persist state files before long tool runs
- Enable: `[features] default_mode_request_user_input = true` in `~/.codex/config.toml`
