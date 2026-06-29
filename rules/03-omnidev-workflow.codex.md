---
description: OmniDev workflow trigger for Codex. Activates when /od prefix is detected. Full spec in ~/.codex/skills/od/SKILL.md.
alwaysApply: false
---

# OmniDev — Codex Trigger

## Activation Rule

When any user message begins with `/od` (case-insensitive, after optional whitespace), immediately read and follow `~/.codex/skills/od/SKILL.md`.

The SKILL.md is the **sole source of truth** for OmniDev workflow, phases, state files, testing discipline, MCP norms, context pruning, and self-evolution rules. Do not improvise OmniDev behavior from this trigger file alone.

## Platform Notes

- **Interactive prompts**: Use Codex's `request_user_input` tool wherever SKILL.md §F.2 says "use platform interactive prompt". If `request_user_input` is NOT available (non-Plan mode), fall back to numbered text prompts per §F.2 CLI/Other pattern.
- **Multi-select**: Codex has no native multi-select. Use numbered text prompts with comma-separated reply parsing per SKILL.md §F.2.1.
- **Sub-agents**: Use Codex's thread-based multi-agent model — `create_thread` + `send_message_to_thread` — per SKILL.md §F.3 "Codex Thread-Agent Dispatch Protocol".
- **MCP**: Use `list_mcp_resources` → `list_mcp_resource_templates` → `read_mcp_resource` per SKILL.md §F.6 "Codex MCP Discovery Protocol".
- **Context compaction**: Codex auto-compacts conversations. Follow the defensive writing and resume protocols in SKILL.md §F.8 and session-memory.md §9.
- **Platform detection**: `codex_app__load_workspace_dependencies` presence = Codex Desktop (SKILL.md §F.1). Set `OMNIDEV_PLATFORM=codex` or `config.json` `platform_override: "codex"` if auto-detection fails.

## Non-/od Messages

If the user's message does NOT start with `/od`, do not apply OmniDev rules, do not create or update `docs/omnidev-state/**`, do not write `evolution-log.jsonl`, and do not run OmniDev phases or commands. Treat the chat as a normal coding conversation.
