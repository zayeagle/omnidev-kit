# Agent Instructions

## OmniDev — strict trigger

→ `skills/od/engine/trigger-gate.md`

| Trigger | Load OmniDev workflow? |
|---------|------------------------|
| Message starts with `/od` or `$od` (incl. `/od 1`) | **Yes** |
| Bare `1`–`9` **and** session-log has matching `pending_decision` | **Yes** (index pick only) |
| `@od` skill attached without `/od` prefix | **No** (reference only) |
| Anything else (incl. bare `n`, `continue`, digit without pending) | **No** — if bare workflow intent, one-line tip only |

**Resume / crash recovery**: `/od re` or `$od re` — reads `session-log.md` from disk, no chat-context inference.

**Advance**: `/od n`, `/od 1`, `/od auto`, `/od ad`, `/od ch`, … (Codex: `$od n` / `$od auto`) — or bare index when pending. Native UI pick in-turn is OK. Autopilot (`/od auto`): soft gates auto-default; after hard-gate confirm, continues remaining phases without another command.

## Platform support

| Platform | Skill path | Interactive tool |
|----------|------------|------------------|
| Cursor | `.cursor/skills/od/` (project) / `~/.cursor/skills/od/` (user) | `AskQuestion` |
| Claude Code | `.claude/skills/od/` or `~/.claude/skills/od/` | `AskUserQuestion` |
| Codex | `~/.codex/skills/od/` | `request_user_input` |

Install / update: `/od up` or `/od i` — default **`project`** scope; `--scope user` for user-level. See [INSTALL.md](INSTALL.md).

Maintainers: `bash scripts/sync-skills.sh` · `bash scripts/check-compliance.sh`
