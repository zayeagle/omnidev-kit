# Agent Instructions

## OmniDev — strict trigger

→ `skills/od/engine/trigger-gate.md`

| Trigger | Load OmniDev? |
|---------|---------------|
| Message starts with `/od` | **Yes** |
| `@od` skill attached this turn (Cursor) | **Yes** |
| Anything else (incl. bare `1`, `n`, `continue`) | **No** |

**Resume / crash recovery**: only `/od re` — reads `session-log.md` from disk, no chat-context inference.

**Advance**: `/od n`, `/od ad`, `/od ch`, … — every step requires `/od` prefix.

## Platform support

| Platform | Skill path | Interactive tool |
|----------|------------|------------------|
| Cursor | `.cursor/skills/od/` | `AskQuestion` |
| Claude Code | `.claude/skills/od/` or `~/.claude/skills/od/` | `AskUserQuestion` |
| Codex | `~/.codex/skills/od/` | `request_user_input` |

Install: [INSTALL.md](INSTALL.md)
