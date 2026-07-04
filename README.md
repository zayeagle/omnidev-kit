# OmniDev Kit

[中文](README.zh-CN.md)

**The AI conductor for software development.** Activate with **`/od`** — not normal chat.

Turns any coding agent into a disciplined delivery pipeline: **assess → design → plan → build → test → deploy** — with state on disk, quality gates, deploy-ready output, and session resume.

## Workflow (Phase 0–5)

```
Assess → Blueprint → Design+Plan → Build → Verify → Release
```

State and artifacts live under `docs/omnidev-state/` — the single source of truth across sessions, agents, and handoffs.

## Highlights

- **Governance first** — Human-in-the-loop by default; no silent destructive actions
- **Quality gates** — Layered testing and phase checkpoints before anything ships
- **Deploy-ready** — Release notes, scripts, and one-click paths out of the box
- **Multi-agent ready** — One orchestrator, optional workers; state files are the contract
- **Cross-session** — Pause, resume, evolve requirements — context never lost

## Platforms (PAL)

| | Cursor | Claude Code | Codex |
|---|:---:|:---:|:---:|
| Trigger | `/od` prefix | `/od` prefix | `/od` prefix |
| Prompts | `AskQuestion` | `AskUserQuestion` | `request_user_input` (+ pseudo-popup fallback) |
| Workers | Built-in | `Task` | `create_thread` |
| Skills | `.cursor/skills/od/` | `.claude/skills/` | `~/.codex/skills/od/` |

Details: [SKILL.md §F](skills/od/SKILL.md#f-platform-abstraction-layer-pal)

## Essential Commands

| Command | Description |
|---------|-------------|
| `/od [req]` | Start workflow (Phase 0) |
| `/od -f [req]` | Fast dev (S-level) |
| `/od ob` | Onboard / scan project |
| `/od n` / `/od ad` / `/od sk` | Phase navigation |
| `/od re` / `/od re [payload]` | Resume session (+ optional intent) |
| `/od ch` | Requirement change + doc sync |
| `/od qa` | Testing phase |
| `/od ps` | Commit & push (user confirms) |
| `/od al` | Run remaining phases (full deploy autonomy) |
| `/od h` | Full command list |

Config: `docs/omnidev-state/config.json` · Toggle prompts: `/od cfg -i on|off`

## Project Layout

```text
omnidev-kit/
├── INSTALL.md
├── README.md / README.zh-CN.md
├── rules/                    # Cursor / Claude / Codex triggers
├── docs/omnidev-state/       # config.json & metrics template
└── skills/od/
    ├── SKILL.md              # Single source of truth
    ├── phases/               # 00-assessment … 05-deploy
    └── engine/               # activation, test-strategy, document-history, …
```

Runtime state lives in **your project**: `docs/omnidev-state/[branch]/`.

## Quick Start

**Install**

```
/od install https://github.com/zayeagle/omnidev-kit.git
```

Or open [INSTALL.md](INSTALL.md) in your agent and ask it to install for your platform.

**Run**

```
/od ob          # first time: scan project
/od [requirement]
```

| Platform | Install target |
|----------|----------------|
| Cursor | `.cursor/skills/od/` + `.cursor/rules/` |
| Claude Code | `.claude/skills/od/` or `~/.claude/skills/od/` |
| Codex | `~/.codex/skills/od/` (+ optional `rules/03-omnidev-workflow.codex.md`) |

**Codex popup in Default mode** — add to `~/.codex/config.toml`:

```toml
[features]
default_mode_request_user_input = true
```

## Docs

- [INSTALL.md](INSTALL.md) — installation & config template
- [skills/od/SKILL.md](skills/od/SKILL.md) — full rules
- [skills/od/engine/commands.md](skills/od/engine/commands.md) — all commands
