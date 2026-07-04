---
description: OmniDev workflow trigger for Claude Code. MANDATORY when /od prefix detected. Bootstrap via engine/activation.md.
alwaysApply: false
---

# OmniDev — Claude Code Trigger

## Activation (HARD)

When any user message begins with `/od` (case-insensitive, after optional whitespace):

1. Read `.claude/skills/od/SKILL.md` or `~/.claude/skills/od/SKILL.md`
2. Execute `engine/activation.md` — tool calls FIRST
3. Load phase/engine file per activation router
4. Do NOT ad-hoc code for `/od [需求]` without workflow

Non-`/od` messages: skip OmniDev entirely.

## Interactive Prompts (主要工作模式)

**Default**: `interactive_mode: true`. Popup is primary UX in **all collaboration modes**.

- **Primary**: `AskUserQuestion` — **MUST invoke tool same turn** as checkpoint
- **Templates**: `engine/interactive-prompt.md` §4 (copy-paste JSON for checkpoint, Phase 0, resume, change, B.0)
- **Fallback**: Pseudo-popup §E if tool fails — structured table, not plain prose

**Forbidden**: Describing options in chat without calling `AskUserQuestion`.

`multiSelect: true` / `allow_multiple: true` when multi-select needed (skill-composition, stash).

## Sub-agents & MCP

- Sub-agents: `Task` tool (SKILL.md §F.3)
- MCP: `.claude/mcp.json` or `~/.claude/mcp.json` (§F.6)
