---
description: OmniDev workflow trigger for Claude Code. Activates when /od prefix is detected. Full spec in .claude/skills/od/SKILL.md.
alwaysApply: false
---

# OmniDev — Claude Code Trigger

## Activation Rule

When any user message begins with `/od` (case-insensitive, after optional whitespace), immediately read and follow `.claude/skills/od/SKILL.md` (if installed at project-level) or `~/.claude/skills/od/SKILL.md` (if installed at user-level).

The SKILL.md is the **sole source of truth** for OmniDev workflow, phases, state files, testing discipline, MCP norms, context pruning, and self-evolution rules. Do not improvise OmniDev behavior from this trigger file alone.

## Platform Notes

- **Interactive prompts**: Use Claude's `AskUserQuestion` tool wherever SKILL.md §F.2 says "use platform interactive prompt". `allow_multiple` in cursor docs maps to `multiSelect: true` in Claude.
- **Sub-agents**: Use Claude's `Task` tool wherever SKILL.md §F.3 says "use platform sub-agent mechanism".
- **MCP**: Check `.claude/mcp.json` or `~/.claude/mcp.json` per SKILL.md §F.6.

## Non-/od Messages

If the user's message does NOT start with `/od`, do not apply OmniDev rules, do not create or update `docs/omnidev-state/**`, do not write `evolution-log.jsonl`, and do not run OmniDev phases or commands. Treat the chat as a normal coding conversation.

## Selective Activation for Non-/od Messages

`alwaysApply: false` means this trigger file only loads when `/od` is detected. Claude Code will route `/od`-prefixed messages through this rule. Non-`/od` messages skip OmniDev entirely — zero token cost for normal conversations.

## CLAUDE.md Merge Guidance

When appending this trigger reference to an existing `CLAUDE.md`:
1. Add ONLY the `## OmniDev Workflow` section (see [INSTALL.md](../../INSTALL.md)).
2. Do NOT duplicate this full trigger file into `CLAUDE.md`.
3. If `CLAUDE.md` already has conflicting rules (e.g., custom code style rules that OmniDev's B.0 or phase rules might overwrite), wrap them with clear precedence markers and let OmniDev's platform mapping respect local conventions.
