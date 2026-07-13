# Agent Instructions

## OmniDev — strict trigger

→ `skills/od/engine/trigger-gate.md`

| Trigger | Load OmniDev? |
|---------|---------------|
| Message starts with `/od` or `$od` | **Yes** |
| `@od` skill attached this turn (Cursor) | **Yes** |
| Anything else (incl. bare `1`, `n`, `continue`) | **No** — if bare workflow intent, one-line tip only |

**Resume / crash recovery**: `/od re` or `$od re` — reads `session-log.md` from disk, no chat-context inference.

**Advance**: `/od n`, `/od ad`, `/od ch`, … (Codex: `$od n` etc.) — every typed step needs prefix. Native UI pick in-turn is OK.

## Platform support

| Platform | Skill path | Interactive tool |
|----------|------------|------------------|
| Cursor | `.cursor/skills/od/` | `AskQuestion` |
| Claude Code | `.claude/skills/od/` or `~/.claude/skills/od/` | `AskUserQuestion` |
| Codex | `~/.codex/skills/od/` | `request_user_input` |

Install: [INSTALL.md](INSTALL.md) · Maintainers: `powershell -File scripts/sync-skills.ps1` · `powershell -File scripts/check-compliance.ps1`
