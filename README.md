# OmniDev Kit

[中文](README.zh-CN.md)

OmniDev Kit is an AI-driven development workflow toolkit that transforms the AI from a "typist who only writes code on command" into a **"senior R&D engineer who understands cost control, architecture design, writes their own tests, and never forgets."**

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   OmniDev (/od)                     │
│              Orchestration & Core Rules              │
│  ┌───────────┬──────────┬───────────┬────────────┐  │
│  │ First     │ i18n     │ Lazy      │ Interactive│  │
│  │ Principles│ (zh/en)  │ Loading   │ Mode       │  │
│  └───────────┴──────────┴───────────┴────────────┘  │
│                        │                             │
│  ┌─────────────────────▼───────────────────────────┐│
│  │         Phase Engine (on-demand loading)         ││
│  │  Phase 0 → Phase 1 → Phase 2 → Phase 3 → Ph.4  ││
│  │ Assess    Blueprint   Plan       Dev      Test   ││
│  └──────────────────────────────────────────────────┘│
│                        │                             │
│  ┌─────────────────────▼───────────────────────────┐│
│  │       Dynamic Skill Composition (B.11)          ││
│  │  Detect intent → Scan local skills → Confirm    ││
│  │  → Load & execute → Bridge back to OmniDev      ││
│  └──────────────────────────────────────────────────┘│
│                        │                             │
│  ┌─────────────────────▼───────────────────────────┐│
│  │            Self-Evolution Engine                 ││
│  │  Observe → Learn → Propose → Apply (with user)  ││
│  └──────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────┘
```

## Core Features

### 1. First Principles — Safety Guardrails

Two fundamental rules that govern all AI behavior, preventing reckless execution:

- **Requirement Alignment (B.3)**: When requirements are vague, ambiguous, or missing key info, the AI is **prohibited** from guessing or self-interpreting. It must proactively confirm the core problem, final goal, delivery criteria, and root cause with the user before proceeding.
- **Problem Fix Protocol (B.4)**: For any bug fix, security patch, or behavior correction, the AI is **prohibited** from shipping a quick patch. It must first produce a complete solution plan with root cause analysis, impact scope, and regression risk. When multiple approaches exist, it ranks them with clear justification and waits for user approval.

### 2. Internationalization (i18n)

Full bilingual support (Chinese / English), switchable at runtime:

- **`/od cfg -l zh`** / **`/od cfg -l en`** to switch languages.
- Phase instruction files are organized under `phases/{locale}/` and `engine/{locale}/`. Only **one locale is loaded at a time** — never both, saving tokens.
- All user-facing output (checkpoints, prompts, reports, Q&A menus) adapts to the active locale.

### 3. Dynamic Skill Composition (B.11)

OmniDev is not a monolith — it acts as an **orchestrator** that dynamically discovers and combines specialized skills:

- **Auto-detect** troubleshooting / debugging / fix intents from user input keywords.
- **Scan local skills** across 4 directories (project-level, user-level Cursor/Claude/Agents skills).
- **Rank matches**: 🎯 Direct match (full troubleshooting workflow) vs 🔧 Supporting (log query, pod status, etc.).
- **User confirms** before any skill is loaded (multi-select supported).
- **Seamless bridge**: After external skill completes, user can transition into OmniDev dev workflow for the fix.

### 4. Project Type Awareness & Adaptive Constraints

- **Legacy Projects**: The AI acts like a "sensible veteran employee", 100% following existing conventions. No forced DDD/TDD.
- **Greenfield Projects**: Full modern conventions — Spec-Driven Development, TDD/DDD, high test coverage.
- Stack detection during `/od onboard` identifies fullstack / frontend-only / backend-only / monorepo.

### 5. Adaptive Scheduling (T-Shirt Sizing)

- **S**: Fix directly, skip blueprint/plan.
- **M**: Skip blueprint → Plan → Dev → Test.
- **L/XL**: Full workflow: Blueprint → Plan → Dev → Test → Deploy.

### 6. Spec-Driven Engineering Discipline

- **Forced Brainstorming**: The AI must think about edge cases, exceptions, and UX before writing any code.
- **Change Management** (`/od ch`): Mid-development requirement changes trigger impact assessment, old plan archival, and new blueprint generation.
- **Auto-Checkpointing**: Git commit before any code modification.

### 7. Cross-Session Memory & State Persistence

- **Dual-State Storage**: `YAML Frontmatter + Markdown` — machine-precise and human-readable.
- **Context Pruning**: Auto-archive when state files exceed 200 lines, preventing hallucinations.
- **Session Recovery**: `/od resume` restores context from state files + git status comparison.

### 8. Lazy Context Loading (B.7)

Every phase declares exactly what files it needs via `context_requires`. The AI:
- Loads only the listed files, skips everything else.
- Caches across phases within the same session.
- Never pre-reads downstream artifacts.
- Token usage stays proportional to the current phase's actual needs.

### 9. Interactive Mode & Auto Q&A Loop

- **Interactive Mode** (default on): Structured choice UI via `AskQuestion` tool at all decision points — saves a round-trip.
- **Auto Q&A Loop** (default on): After every `/od` command, the AI presents context-adaptive next actions instead of silently stopping.
- Both can be toggled with `/od cfg -i on|off`.

### 10. DevSecOps & Resilience

Phase 3 enforces security and resilience coding:
- **Security by Design**: IDOR/BOLA prevention, injection prevention, SSRF/CSRF protection, sensitive data masking.
- **Standard Level**: Structured errors, timeout control, graceful failure, input validation.
- **High Level** (user-requested): Circuit breaker, retry with backoff, bulkhead isolation, graceful degradation, rate limiting.

### 11. Quality Assurance — Testing (Phase 4)

- **Dependency topology mapping** before writing any test.
- **Mock strategy hierarchy**: Interface mock → In-memory fake → Container stub → HTTP stub → MCP-driven.
- **Scenario coverage matrix**: Happy path, validation, conflict, dependency failure, security (IDOR/SQLi), concurrency.
- **System-level resilience testing**: Network latency, timeout, high concurrency (P99 < 200ms), memory pressure.
- **Coverage gate**: >= 90% statement/branch coverage.

### 12. Self-Evolution Engine

- **Passive Learning**: Logs corrections, patterns, error resolutions during `/od` sessions.
- **Smart Proposals**: Generates rule/skill improvement proposals when signals accumulate.
- **User-Controlled**: All changes require explicit approval via `/od ln`.
- **Safety Guardrails**: Cannot weaken core rules. Full rollback via `/od ln --rb [N]`.

### 13. Enterprise Reporting & Ops

- **Weekly Reports** (`/od rp`): Management-ready reports combining git history + state files.
- **Push Flow** (`/od ps`): Change impact summary → stage → commit message generation → push.
- **Efficiency Bill**: ROI metrics appended to `metrics.json` after each delivery.
- **Manual Update** (`/od up`): Preview diff before applying, user must confirm.

## Command Reference

| Command | Alias | Description |
|---------|-------|-------------|
| `/od [requirement]` | — | Guided workflow: assess complexity → recommend phases |
| `/od -f [requirement]` | — | Fast mode: skip blueprint/plan, dev directly |
| `/od -p [requirement]` | — | Plan only: output blueprint and plan, no code |
| `/od h` | `/od help` | Show all commands |
| `/od ob` | `/od onboard` | Scan project, generate context doc |
| `/od rv` | `/od review` | Code review (read-only) |
| `/od qa` | — | Dependency analysis → Mock → Test → Report |
| `/od ch [new req]` | `/od change` | Change management |
| `/od ln` | `/od learn` | Self-learning: retrospective + evolution proposals |
| `/od rp` | `/od report` | Generate weekly report |
| `/od ps` | `/od push` | Commit and push code |
| `/od re` | `/od resume` | Resume interrupted session |
| `/od up` | `/od update` | Update OmniDev Kit |
| `/od i <url>` | `/od install` | Install from remote Git repo |
| `/od cfg` | `/od config` | View/edit configuration |
| `/od cfg -l zh\|en` | — | Switch language |
| `/od cfg -i on\|off` | — | Toggle interactive + auto Q&A mode |
| `/od st` | `/od stash` | Stash current task context |
| `/od po` | `/od pop` | Restore stashed context |
| `/od sy` | `/od sync` | Sync output to Jira/GitHub Issue |
| `/od db` | `/od dashboard` | Generate efficiency ROI dashboard |

## Directory Structure

```text
omnidev-kit/
├── INSTALL.md
├── README.md
├── README.zh-CN.md
├── rules/
│   └── 01-omnidev-workflow.mdc       # Lightweight trigger (alwaysApply: false)
└── skills/
    └── od/
        ├── SKILL.md                  # Main spec — single source of truth
        ├── phases/
        │   ├── 00-assessment.md      # Root-level fallback
        │   ├── 01-02-planning.md
        │   ├── 03-development.md
        │   ├── 04-testing.md
        │   ├── zh/                   # Chinese locale
        │   │   ├── 00-assessment.md
        │   │   ├── 01-02-planning.md
        │   │   ├── 03-development.md
        │   │   └── 04-testing.md
        │   └── en/                   # English locale
        │       ├── 00-assessment.md
        │       ├── 01-02-planning.md
        │       ├── 03-development.md
        │       └── 04-testing.md
        └── engine/
            ├── evolution.md          # Root-level fallback
            ├── special-flows.md
            ├── zh/
            │   ├── evolution.md
            │   └── special-flows.md
            └── en/
                ├── evolution.md
                └── special-flows.md
```

## Quick Start

**Option 1: Install from Remote URL (Recommended)**

```
/od install https://github.com/zayeagle/omnidev-kit.git
```

**Option 2: Install from Local Directory**

Drag `INSTALL.md` into your AI assistant chat and say: "Please help me install this toolkit."

Then type `/od` or state your requirement to begin.
