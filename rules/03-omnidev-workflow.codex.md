---
description: OmniDev workflow trigger for Codex. MANDATORY when /od prefix detected. Bootstrap via engine/activation.md.
alwaysApply: false
---

# OmniDev — Codex Trigger

## Activation (HARD)

When any user message begins with `/od` (case-insensitive, after optional whitespace):

1. Read `~/.codex/skills/od/SKILL.md`
2. Execute `engine/activation.md` — tool calls FIRST
3. Load phase/engine file per activation router
4. Do NOT ad-hoc code for `/od [需求]` without workflow

Non-`/od` messages: skip OmniDev entirely.

## Interactive Prompts (主要工作模式)

**Default**: `interactive_mode: true` — popup is primary UX.

| Platform | Primary (same turn as checkpoint) | Fallback |
|----------|-----------------------------------|----------|
| Claude Code | **`AskUserQuestion`** — use `engine/interactive-prompt.md` §4 JSON templates | Pseudo-popup §E |
| Codex (Plan + Default/Code) | **`request_user_input`** — use §5 templates | Pseudo-popup §E |

### Codex Default/Code 弹窗启用

```toml
# ~/.codex/config.toml
[features]
default_mode_request_user_input = true
```

Or: `codex features enable default_mode_request_user_input` → restart Codex.

Without flag: pseudo-popup §E (structured table) — **not** a bug, but enable flag for native UI.

**Agent rule**: MUST call tool in same turn — never prose-only options when `interactive_mode=true`.

## Sub-agents & MCP

- Sub-agents: `create_thread` + `send_message_to_thread` (§F.3)
- MCP: `list_mcp_resources` → `read_mcp_resource` (§F.6)
- Compaction: §F.8 defensive state-file writes

## Platform override

If detection fails: `config.json` → `"platform_override": "codex"`
