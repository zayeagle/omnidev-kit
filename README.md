# OmniDev Kit

[中文](README.zh-CN.md)

AI-driven **engineering workflow** for Cursor, Claude Code, and Codex. Activate with **`/od`** — not normal chat.

Turns the agent into a disciplined delivery pipeline: **assess → design → plan → dev → test → deploy**, with state on disk, layered tests, one-click deploy scripts, and session resume.

## Workflow (Phase 0–5)

```
Phase 0 Assess → Phase 1 Blueprint → Phase 2 Design+Plan → Phase 3 Dev → Phase 4 Test → Phase 5 Deploy
     S/M/L/XL complexity trims which phases run (S can skip blueprint/plan)
```

| Phase | Output (under `docs/omnidev-state/`) |
|-------|--------------------------------------|
| 0 | `00-project-context.md` |
| 1 | `01-blueprint.md` |
| 2 | `02-plan.md`, `04-design.md`, `features/*.md`, `05-test-plan.md` |
| 3 | Code + `03-progress.md` |
| 4 | `05-test-report.md` (gate) |
| 5 | `06-release-notes.md`, `Makefile`, `deploy/**` one-click scripts |

## Highlights

- **B.0** — Ask when unsure; no silent assumptions on destructive changes
- **Popup-first UX** — Native prompts (AskQuestion / AskUserQuestion / `request_user_input`) + structured fallback
- **Document history** — Each artifact: `active` + `*-history.md` (append-only audit trail)
- **Layered testing** — UNIT (blocking) · INT · E2E (Playwright) · SMK · REG — auto-composed by complexity & stack
- **One-click deploy** — `make deploy` / docker · k8s · binary; legacy projects audit-before-modify
- **Context budget** — HOT+WARM ≤300 lines; phase files loaded on demand
- **Multi-agent** — 1 Orchestrator + optional Task/Phase Workers (L/XL); state files are the handoff contract
- **Cross-session** — `/od re`, `/od re [payload]`, stash/pop, metrics & governance (`/od gv`)

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
