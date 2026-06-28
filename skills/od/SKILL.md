---
name: od
description: >-
  OmniDev AI-driven development workflow. Use ONLY when the user's message starts with /od
  (e.g. /od h, /od re, /od ob, /od rp, /od rv, /od qa, /od ch, /od ln, /od gv).
  Do not load or follow this skill for normal chat without the /od prefix.
---

# OmniDev Workflow Skill

**Single source of truth for OmniDev rules. Applies ONLY on `/od`-prefixed messages.**

---

## A. Command Reference

→ Full reference in [engine/commands.md](engine/commands.md). Load only on `/od h` or `/od help`.

---

## B. Core Rules

### B.0 First Principle — 不确定就问，禁止自我发挥

**最高优先级规则。任何不确定、歧义、多种可能的情况 → 停下来向用户确认，禁止猜测/假设/自我发挥。** 判断标准：如果你需要说"我假设/猜测/应该是/大概是"—停下来问。需求模糊、多技术方案、代码风格不确定、删改现有代码时尤其适用。
→ Execution protocol: [engine/context-protocol.md](engine/context-protocol.md) §1

### B.1 Activation & Tool Execution
- OmniDev activates **only** on `/od` prefix. First action MUST be a tool call — zero text before tools.
- Ad-hoc requests → find file, edit, apply directly. Image attachments: tool calls FIRST, then explain.

### B.2 Workflow Philosophy
Phase order: **Blueprint → Design & Plan → Dev → Test → Deploy**. Forward only, any phase skippable. Complexity (S/M/L/XL) provides recommendations, not mandates.

### B.3 State File Isolation
- Global: `docs/omnidev-state/` (`00-project-context.md`, `metrics.json`, `config.json`, `user-preferences.md`)
- Branch: `docs/omnidev-state/[branch]/` (`01-blueprint.md` ~ `06-release-notes.md`, `features/*.md`, `session-log.md`)
- Stash: `docs/omnidev-state/stash/`

### B.4 Interactive Quick-Select & Decision Points
When `interactive_mode=true`: use AskQuestion with Chinese labels at decision points (phase checkpoints, pre-dev scope, post-dev impact, change management, doc sync). User can always reply with any `/od` command.
→ [engine/special-flows.md](engine/special-flows.md) §3.1

### B.5 Context Lifecycle (Load / Summarize / Unload)
三层占用模型：HOT ≤150 · WARM ≤250 · COLD 磁盘按需。阶段结束强制 Purge；对话中用路径指针代替粘贴 state 全文。
→ [engine/context-occupancy.md](engine/context-occupancy.md), [engine/context-protocol.md](engine/context-protocol.md)

### B.6 Configuration
`/od cfg` display; `/od cfg -i on|off` toggle interactive. Defaults: `interactive_mode: true`, `ask_mode_after_od: true`, `auto_checkpoint: false`.
→ [engine/user-preferences.md](engine/user-preferences.md), [engine/commands.md](engine/commands.md) Config Options

### B.8 Next-Step Prompt Format
After phase checkpoint: present 2-4 next actions as AskQuestion choices, `/od h` as last option. MUST STOP and WAIT.
→ [engine/special-flows.md](engine/special-flows.md) §3.1

### B.9 Progress Tracking
After every task: append `[✅/🔄/⏳] [Task ID] [Description] — [Time]` to `03-progress.md`. Archive completed tasks to `archive/progress-archive-[date].md` before pruning snapshot.
→ [phases/03-development.md](phases/03-development.md) §1

### B.10 Error Handling
Log error details → diagnose root cause → propose fix with impact scope → confirm before executing (B.0).
→ [engine/special-flows.md](engine/special-flows.md) §5

### B.11 Session Memory
`/od re` recalls prior session context; `/od x` saves current context for future recall.
→ [engine/session-memory.md](engine/session-memory.md)

### B.12 Stash & Pop
`/od st` stashes working state; `/od po` restores it.
→ [engine/stash.md](engine/stash.md)

### B.13 AI Governance
`/od gv` runs cost audit: token usage, efficiency scores, optimization suggestions.
→ [engine/governance.md](engine/governance.md)

### B.14 Document Sync
Requirements changes in any user input MUST trigger proactive doc sync: identify change → confirm (B.0) → scan existing state files → update affected files → output sync report.
→ [engine/special-flows.md](engine/special-flows.md) §2

### B.15 Confirmation Throttling (by Complexity)
Reduce STOP/WAIT fatigue without sacrificing safety on large changes:
- **S** / `/od -f`: skip Pre-Dev and per-group Change Impact; optional summary at end
- **M**: Pre-Dev once; Change Impact at phase end (or on scope deviation)
- **L/XL**: full Pre-Dev + per-group Change Impact
Override via `config.json` → `"confirmation_level": "full" | "reduced" | "minimal"`
→ [phases/03-development.md](phases/03-development.md) §1.1

### B.16 Metrics & Git Safety
- Append events to `metrics.json` at phase/task boundaries — silent, no user prompt.
→ [engine/metrics.md](engine/metrics.md)
- **Never auto-commit** unless user explicitly requests via `/od ps` or direct instruction. Phase 3 may `git stash` only when `auto_checkpoint: true`.

### B.17 Token Optimization
→ [engine/token-optimization.md](engine/token-optimization.md)

### B.18 Context Occupancy (上下文占用)
同一时刻 HOT+WARM ≤300 行。按 phase 加载切片；Checkpoint ≤12 行；禁止在对话中重复 state 全文。
→ [engine/context-occupancy.md](engine/context-occupancy.md)

---

## C. Phase Execution Protocol

### C.0 Phase & Engine File Loading

| Target | File to Load |
|--------|-------------|
| Phase 0 / `/od onboard` | [phases/00-assessment.md](phases/00-assessment.md) |
| Phase 1 | [phases/01-blueprint.md](phases/01-blueprint.md) |
| Phase 2 | [phases/02-planning.md](phases/02-planning.md) |
| Phase 3 | [phases/03-development.md](phases/03-development.md) |
| Phase 4 / `/od qa` | [phases/04-testing.md](phases/04-testing.md) |
| Phase 5 / Deploy | [phases/05-deploy.md](phases/05-deploy.md) |
| `/od push`, `/od change`, `/od report`, `/od compress`, `/od up`, `/od i` | [engine/special-flows.md](engine/special-flows.md) |
| `/od sy`, `/od db` | [engine/special-flows.md](engine/special-flows.md) §7–§8 |
| `/od gv`, `/od governance` | [engine/governance.md](engine/governance.md) |
| `/od learn`, `/od ln` | [engine/evolution.md](engine/evolution.md) |
| `/od h`, `/od help` | [engine/commands.md](engine/commands.md) |
| `/od st`, `/od po` | [engine/stash.md](engine/stash.md) |
| `/od x`, `/od re` | [engine/session-memory.md](engine/session-memory.md) |
| Phase transition (exit/enter) | [engine/context-protocol.md](engine/context-protocol.md) + [engine/context-occupancy.md](engine/context-occupancy.md) |
| Token optimization / cost | [engine/token-optimization.md](engine/token-optimization.md) |
| Troubleshooting/diagnosis | [engine/skill-composition.md](engine/skill-composition.md) |

After reading the instruction file, follow its `context_requires` to load project state files.

### C.1 Phase Exit — Checkpoint & Learning

After each phase, **first execute silent learning, then output checkpoint**.

**Silent Learning**: Reflect on domain knowledge/architecture patterns → append to `00-project-context.md` (1-2 lines, max 50 total) → log to `evolution-log.jsonl` → update `metrics.json`.
→ Full protocol: [engine/evolution.md](engine/evolution.md) §1

**Checkpoint Output** (≤12 lines per B.18 — no state file echo):
```
✅ Phase N 完成: [Name]
📦 产出物: [state files created/updated]
📍 进度: Phase 0 ✅ → Phase 1 ✅ → Phase 2 🔧 → ...
🔔 下一阶段: Phase N+1 — [Name]
```

**Phase 3 special rules**: Pre-Dev and Change Impact per B.15. Learning guard: phase_3 insights need 2+ observations unless error_resolution. After checkpoint, display next-step prompt (B.8). STOP — WAIT.

### C.2 Context Budget
HOT ≤150 · WARM ≤250 · Total ≤300 lines. COLD = disk on-demand only.
→ [engine/context-occupancy.md](engine/context-occupancy.md), [engine/context-protocol.md](engine/context-protocol.md) §6–§12

---

## D. Project Type Awareness

| Type | Behavior |
|------|----------|
| **Legacy** | Follow existing conventions 100%. Minimize new dependencies. Match test framework in repo. |
| **Greenfield** | OpenSpec / TDD / DDD OK. Scaffold tests, CI, deploy manifests. Higher coverage targets. |
| **Monorepo** | Tag tasks with `[pkg:name]`; deploy/test per affected package. See Phase 0/2 instructions. |

## E. MCP Integration
During Phase 3 & 4, proactively use available MCP servers: Database MCP (verify structures, mock data), Browser MCP (E2E, screenshots). Check `.cursor/mcp.json` before complex tasks; suggest installation if critical MCP missing.
