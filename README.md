# OmniDev Kit

[中文](README.zh-CN.md)

OmniDev Kit is an AI-driven development workflow toolkit that transforms the AI from a "typist who only writes code on command" into a **"senior R&D engineer who understands cost control, architecture design, writes their own tests, and never forgets."**

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   OmniDev (/od)                     │
│              Orchestration & Core Rules              │
│  ┌──────────┬──────────┬──────────┬──────────────┐  │
│  │ B.0      │ Context  │ Impact   │ Interactive  │  │
│  │ Ask when │ Life-    │ Analysis │ Quick-Select │  │
│  │ unsure   │ cycle    │ & Confirm│              │  │
│  └──────────┴──────────┴──────────┴──────────────┘  │
│                        │                             │
│  ┌─────────────────────▼───────────────────────────┐│
│  │    Phase Engine (load / summarize / unload)      ││
│  │  Phase 0 → Phase 1 → Phase 2 → Phase 3 → Ph.4  ││
│  │ Assess    Blueprint   Plan       Dev      Test   ││
│  └──────────────────────────────────────────────────┘│
│                        │                             │
│  ┌─────────────────────▼───────────────────────────┐│
│  │            Memory & Persistence Layer            ││
│  │  Session Memory │ User Preferences │ Stash/Pop  ││
│  └──────────────────────────────────────────────────┘│
│                        │                             │
│  ┌─────────────────────▼───────────────────────────┐│
│  │       Dynamic Skill Composition (B.9)           ││
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

### 1. First Principle — Ask When Unsure, Never Improvise (B.0)

**Highest-priority rule, applies across all phases, commands, and decision points.**

Throughout the entire workflow, whenever the AI encounters anything uncertain, unclear, ambiguous, or with multiple possibilities, it **must stop and ask the user for confirmation**. This covers: requirement analysis, technical approach selection, code style decisions, phase skip/retain, context unloading, dependency/framework choices, and code deletion/refactoring.

> Rule of thumb: If you need to say "I assume...", "I guess...", "It should be...", you are unsure — stop and ask.

Specific applications:
- **Requirement Alignment**: When requirements are vague, confirm core problem, final goal, delivery criteria, and root cause before proceeding.
- **Problem Fix Protocol**: For bug/security/behavior fixes, produce a complete solution plan with root cause analysis, compare approaches, and wait for user approval.

### 2. Context Lifecycle Management (B.5)

Three-layer mechanism to control context bloat while preserving dependency chains:

- **On-demand loading**: Each phase declares needed files via `context_requires`. `scan_limit` caps scan results.
- **Summarize-then-discard**: Large file reads (> 100 lines) are summarized to key info; Grep results (> 20 matches) are trimmed to Top 10; Shell output (> 50 lines) is reduced to key lines.
- **Persist-then-unload**: On phase exit, key outputs are written to state files (persist), then raw tool outputs are marked expired (unload). **State files and user decisions are never unloaded.**

Dependency chain protection:

```
Phase 0 → 00-project-context.md → Phase 1, 2, 3, 4 (never unload)
Phase 2 → 02-plan.md            → Phase 3, 4 (never unload)
Phase 3 → 03-progress.md        → Phase 4 (never unload)
```

### 3. Cross-Session Memory System

Three memory modules ensure the AI "never forgets":

| Module | File | Purpose |
|--------|------|---------|
| **Session Memory** (B.10) | `session-log.md` | Auto-generates structured summary on session end (goals, decisions, progress, feedback). Read on `/od re` for seamless resume. |
| **User Preferences** (B.11) | `user-preferences.md` | Passively collects behavioral patterns (code style, phase skip habits, output verbosity). Loaded on every activation (≤ 30 lines). |
| **Stash/Pop** (B.12) | `stash/` | Multi-task switching: `/od st` saves full snapshot (state files + git stash), `/od po` restores and auto-resumes. |

### 4. Lightweight Interactive Prompt (B.8)

After each phase or command completes, the AI presents **2-4 most relevant next actions** via AskQuestion dialog:

- **Focused**: No verbose command lists — only the most reasonable next steps for current state
- **Context-aware**: Intelligently recommends options based on current progress
- **Zero memory burden**: Users don't need to memorize commands — just click to continue

### 5. Dynamic Skill Composition (B.9)

OmniDev acts as an **orchestrator** that dynamically discovers and combines specialized skills:

- **Auto-detect** troubleshooting / debugging / fix intents from user input keywords.
- **Scan local skills** across 4 directories (project-level, user-level Cursor/Claude/Agents skills).
- **Rank matches**: 🎯 Direct match vs 🔧 Supporting capability.
- **User confirms** before any skill is loaded (multi-select supported). **On-demand loading to save context.**

### 6. Project Type Awareness & Adaptive Constraints

- **Legacy Projects**: The AI acts like a "sensible veteran employee", 100% following existing conventions. No forced DDD/TDD.
- **Greenfield Projects**: Full modern conventions — Spec-Driven Development, TDD/DDD, high test coverage.
- Stack detection during `/od onboard` identifies fullstack / frontend-only / backend-only / monorepo.

### 7. Adaptive Scheduling (T-Shirt Sizing)

- **S**: Fix directly, skip blueprint/plan.
- **M**: Skip blueprint → Plan → Dev → Test.
- **L/XL**: Full workflow: Blueprint → Plan → Dev → Test → Deploy.

### 8. Spec-Driven Engineering Discipline

- **Forced Brainstorming**: The AI must think about edge cases, exceptions, and UX before writing any code.
- **Pre-Development Scope Confirmation**: Before writing code, must analyze architecture, code style, call chains, identify modification boundaries and impact, present risk assessment — **user must confirm before coding begins**.
- **Post-Development Impact Confirmation**: After each task group, compare actual changes vs planned scope, flag deviations — **user must confirm before continuing**.
- **Change Management** (`/od ch`): Mid-development requirement changes trigger impact assessment, old plan archival, and new blueprint generation.
- **Auto-Checkpointing**: Git commit before any code modification.

### 9. DevSecOps & Resilience

Phase 3 enforces security and resilience coding:
- **Security by Design**: IDOR/BOLA prevention, injection prevention, SSRF/CSRF protection, sensitive data masking.
- **Standard Level**: Structured errors, timeout control, graceful failure, input validation.
- **High Level** (user-requested): Circuit breaker, retry with backoff, bulkhead isolation, graceful degradation, rate limiting.

### 10. Quality Assurance — Testing (Phase 4)

- **Dependency topology mapping** before writing any test.
- **Mock strategy hierarchy**: Interface mock → In-memory fake → Container stub → HTTP stub → MCP-driven.
- **Scenario coverage matrix**: Happy path, validation, conflict, dependency failure, security (IDOR/SQLi), concurrency.
- **System-level resilience testing**: Network latency, timeout, high concurrency (P99 < 200ms), memory pressure.
- **Coverage gate**: >= 90% statement/branch coverage.

### 11. Self-Evolution Engine

- **Continuous Phase Learning**: At every phase exit, silently captures domain knowledge, architecture patterns, and business scenarios into `00-project-context.md § Domain Knowledge`.
- **Compound Effect**: After 3-5 requirements, the AI's domain understanding approaches that of a team member who has been on the project for months — enabling significantly faster bug localization.
- **Passive Learning**: Logs corrections, patterns, error resolutions during `/od` sessions.
- **Smart Proposals**: Generates rule/skill improvement proposals when signals accumulate.
- **User-Controlled**: Rule changes require explicit approval via `/od ln`; domain knowledge accumulation is silent and observational.
- **Safety Guardrails**: Cannot weaken core rules. Full rollback via `/od ln --rb [N]`.

### 12. Enterprise Reporting & Ops

- **Weekly Reports** (`/od rp`): Management-ready reports combining git history + state files.
- **AI Governance & Cost Audit** (`/od gv`): Manually triggered audit for token/cost efficiency, process compliance, quality risks, and prioritized improvements. Supports `--scope` and `--since`.
- **Push Flow** (`/od ps`): Change impact summary → stage → commit message generation → push.
- **Efficiency Bill**: ROI metrics appended to `metrics.json` after each delivery.
- **Manual Update** (`/od up`): Preview diff before applying, user must confirm.

## Command Reference

### Core Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `/od [requirement]` | — | Guided workflow: assess complexity → recommend phases |
| `/od -f [requirement]` | — | Fast mode: skip blueprint/plan, dev directly |
| `/od -p [requirement]` | — | Plan only: output blueprint and plan, no code |
| `/od h` | `/od help` | Show all commands |
| `/od ob` | `/od onboard` | Scan project, generate context doc |
| `/od gv` | `/od governance` | AI governance & cost audit (manual trigger) |
| `/od gv --scope <...>` | — | Limit audit domain (phase3 / learning / cost / compliance / quality, etc.) |
| `/od gv --since <7d\|14d\|30d\|90d>` | — | Set audit time window (default: 14d) |
| `/od rv` | `/od review` | Code review (read-only) |
| `/od qa` | — | Dependency analysis → Mock → Test → Report |
| `/od ch [new req]` | `/od change` | Change management |
| `/od ln` | `/od learn` | Self-learning: retrospective + evolution proposals |
| `/od rp` | `/od report` | Generate weekly report |
| `/od ps` | `/od push` | Commit and push code |
| `/od re` | `/od resume` | Resume interrupted session (reads session-log) |
| `/od up` | `/od update` | Update OmniDev Kit |
| `/od i <url>` | `/od install` | Install from remote Git repo |

### Session Management

| Command | Alias | Description |
|---------|-------|-------------|
| `/od st` | `/od stash` | Stash current task (state files + git stash) |
| `/od po` | `/od pop` | Restore stashed task and auto-resume |
| `/od x` | `/od cancel` | End current session (auto-saves session-log) |

### Phase Navigation

| Command | Alias | Description |
|---------|-------|-------------|
| `/od n` | `/od next` | Continue to next phase |
| `/od ad` | `/od adj` | Revise current output |
| `/od sk` | `/od skip` | Skip a phase |
| `/od bk` | `/od back` | Go back to a phase |
| `/od al` | `/od all` | Execute all remaining phases |

### Configuration

| Command | Description |
|---------|-------------|
| `/od cfg` | View current config and user preferences |
| `/od cfg -i on\|off` | Toggle interactive mode |

## Directory Structure

```text
omnidev-kit/
├── INSTALL.md
├── README.md
├── README.zh-CN.md
├── rules/
│   └── 01-omnidev-workflow.mdc         # Lightweight trigger (alwaysApply: false)
├── scripts/
│   └── clean-cursor-state.ps1          # Utility: clean Cursor state
└── skills/
    └── od/
        ├── SKILL.md                    # Main spec — single source of truth
        ├── phases/
        │   ├── 00-assessment.md        # Phase 0: Assessment & Onboard
        │   ├── 01-02-planning.md       # Phase 1-2: Blueprint & Planning
        │   ├── 03-development.md       # Phase 3: Development & DevSecOps
        │   └── 04-testing.md           # Phase 4: Testing & Wrap-up
        └── engine/
            ├── commands.md             # Command reference (on-demand)
            ├── context-protocol.md     # Unload/transition/budget rules (on-demand)
            ├── evolution.md            # Self-evolution engine (on-demand)
            ├── governance.md           # AI governance & cost audit (on-demand)
            ├── session-memory.md       # Session memory + resume/exit flows
            ├── stash.md                # Stash/Pop implementation (on-demand)
            ├── skill-composition.md    # Dynamic skill composition (on-demand)
            ├── special-flows.md        # Push/Change/Report/Update flows
            └── user-preferences.md     # User preference collection rules
```

## Quick Start

**Option 1: Install from Remote URL (Recommended)**

```
/od install https://github.com/zayeagle/omnidev-kit.git
```

**Option 2: Install from Local Directory**

Drag `INSTALL.md` into your AI assistant chat and say: "Please help me install this toolkit."

Then type `/od` or state your requirement to begin.
