# OmniDev Kit

OmniDev Kit transforms AI from a **"typist who only writes code on command"** into a **"senior R&D engineer who understands cost control, architecture design, writes their own tests, and never forgets."**

Activate with **`/od`** — a stateful delivery pipeline from intent to release. Not casual chat.

## Workflow

```
Assess → Blueprint → Design+Plan → Build → Verify → Release
```

Complexity-aware (S/M/L/XL): scale ceremony to the task, never compromise at the gate.  
All state persists under `docs/omnidev-state/` — auditable, resumable, handoff-ready.

## What You Get

- **Engineering discipline** — Think before code; confirm before change; gate before ship
- **Persistent memory** — Session resume, preference learning, task stash — context that compounds
- **Adaptive rigor** — Full pipeline for large work; lean path for small fixes
- **Quality to production** — Layered tests, coverage gates, release notes, one-click deploy
- **Continuous evolution** — Domain knowledge and workflow rules improve under your control

## Essential Commands

| Command | Description |
|---------|-------------|
| `/od [req]` | Start workflow (Phase 0) |
| `/od -f [req]` | Fast dev (S-level) |
| `/od ob` | Onboard / scan project |
| `/od board` / `start` / `next` | Flow board (default manual; start = only entry) |
| `/od n` / `/od ad` / `/od sk` | Phase navigation |
| `/od re` / `/od re [payload]` | Resume session |
| `/od ch` | Requirement change + doc sync |
| `/od qa` | Testing phase |
| `/od ps` | Commit & push (user confirms) |
| `/od al` | Run remaining phases |
| `/od h` | Full command list |

Config: `docs/omnidev-state/config.json` · Interactive mode: `/od cfg -i on|off`

## Project Layout

```text
omnidev-kit/
├── INSTALL.md
├── README.md                 # English docs (canonical)
├── rules/                    # Agent trigger rules
├── docs/omnidev-state/       # config.json & metrics template
└── skills/od/
    ├── SKILL.md              # Single source of truth
    ├── phases/               # 00-assessment … 05-deploy
    └── engine/               # activation, test-strategy, document-history, …
```

Runtime state lives in **your project**: `docs/omnidev-state/[branch]/`.

## Quick Start

```
/od install https://github.com/zayeagle/omnidev-kit.git
/od ob
/od [your requirement]
```

Or open [INSTALL.md](INSTALL.md) in your AI assistant — it auto-detects the environment and installs to the correct paths.

## Docs

- [INSTALL.md](INSTALL.md) — installation & config
- [skills/od/SKILL.md](skills/od/SKILL.md) — full specification
- [skills/od/engine/commands.md](skills/od/engine/commands.md) — all commands

**Maintainers**: edit `skills/od/` only, then `powershell -File scripts/sync-skills.ps1` && `powershell -File scripts/check-compliance.ps1`.
