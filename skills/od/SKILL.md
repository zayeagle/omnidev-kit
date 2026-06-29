---
name: od
description: >-
  OmniDev AI-driven development workflow. Activates on /od prefix
  (e.g. /od h, /od re, /od ob, /od rp, /od rv, /od qa, /od ch, /od ln, /od gv).
  Do not load or follow this skill for normal chat without the /od prefix.
  Supports Cursor, Claude Code, and Codex agents. See F for platform adaptation.
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

#### B.0 Non-Interactive Fallback

When `interactive_mode: false` or the platform lacks interactive prompt tools (CLI/Other, Codex without `request_user_input`), B.0 confirmation uses **text-based prompts with explicit defaults**:

| Decision Type | Fallback Mechanism | Default (if no response) |
|---------------|-------------------|--------------------------|
| Requirement ambiguity | Text prompt with 2-3 clear options, each labeled | Most conservative/least-destructive option |
| Technical approach selection | Text prompt with numbered alternatives | Option 1 (recommended) |
| Code style uncertainty | Text prompt + "use existing convention in repo" default | Follow existing conventions |
| Code deletion/modification | Text prompt; require explicit `y` before acting | **Do NOT proceed** — assume `n` |
| Phase skip/retain | Text prompt per §F.2 CLI/Other pattern | Follow T-shirt size recommendations |

**Rules for text-based B.0 prompts**:
1. Each prompt must have ≤3 options, clearly numbered, with the default marked `[默认]`.
2. Unsafe actions (deletion, breaking changes, production deploys) default to **"不执行"** — user must explicitly opt in.
3. Safe actions (following conventions, using repo patterns) may proceed after prompt if user doesn't respond within a reasonable interval.
4. All B.0 decisions are logged to `session-log.md` `## 关键决策` whether interactive or text-based.

**Codex note**: When `request_user_input` IS available but `interactive_mode: false`, use text prompts (not `request_user_input`) for B.0 decisions. Save `request_user_input` for B.8 next-step prompts only.

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
When `interactive_mode=true`: use the platform interactive prompt (SKILL.md §F.2) with Chinese labels at decision points (phase checkpoints, pre-dev scope, post-dev impact, change management, doc sync). User can always reply with any `/od` command.
→ [engine/special-flows.md](engine/special-flows.md) §3.1

### B.5 Context Lifecycle (Load / Summarize / Unload)
三层占用模型：HOT ≤150 · WARM ≤250 · COLD 磁盘按需。阶段结束强制 Purge；对话中用路径指针代替粘贴 state 全文。
→ [engine/context-occupancy.md](engine/context-occupancy.md), [engine/context-protocol.md](engine/context-protocol.md)

### B.6 Configuration
`/od cfg` display; `/od cfg -i on|off` toggle interactive. Defaults: `interactive_mode: true`, `ask_mode_after_od: true`, `auto_checkpoint: false`.
→ [engine/user-preferences.md](engine/user-preferences.md), [engine/commands.md](engine/commands.md) Config Options

### B.8 Next-Step Prompt Format
After phase checkpoint: present 2-4 next actions as platform interactive prompt choices (§F.2), `/od h` as last option. MUST STOP and WAIT.
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
During Phase 3 & 4, proactively use available MCP servers: Database MCP (verify structures, mock data), Browser MCP (E2E, screenshots). Check MCP config per SKILL.md §F.6 before complex tasks; suggest installation if critical MCP missing.

---

## F. Platform Abstraction Layer (PAL)

OmniDev supports three code-agent platforms: **Cursor**, **Claude Code**, and **Codex**. For any platform-dependent capability, consult this layer before acting — **never hardcode a single platform's mechanism**.

### F.1 Platform Detection

On `/od` activation, detect the current platform via available tools. Check in order:

| # | Signal | Platform |
|---|--------|----------|
| 1 | `AskQuestion` tool exists | **Cursor** |
| 2 | `Task` tool (sub-agent) AND `AskUserQuestion` tool exists | **Claude Code** |
| 3 | `request_user_input` tool exists AND `SKILL.md`-based skill system | **Codex** |
| 4 | Fallback: treat as generic text-only agent | **CLI / Other** |

Store detected platform in session memory; do not re-detect mid-session.

### F.2 Interactive Prompt (maps B.4, B.8, skill-composition §4, special-flows §3.1, stash §2-§3, session-memory §6)

Replace all `AskQuestion` references with the following platform-adaptive pattern:

| Platform | Interactive Prompt Mechanism |
|----------|------------------------------|
| **Cursor** | `AskQuestion` tool (native), `allow_multiple: true` for multi-select |
| **Claude Code** | `AskUserQuestion` tool (with `multiSelect: true` where `allow_multiple` was used) |
| **Codex** | `request_user_input` tool — structured `questions` array, each with `options` list. **Availability note**: `request_user_input` is only available in **Plan mode**. Non-Plan-mode Codex sessions or sessions where `request_user_input` is absent MUST fall back to the CLI/Other mechanism (numbered text prompt). Verify the tool is in the available tool list before calling it. |
| **CLI / Other** | Numbered text prompt in assistant response — user replies with number or command |

#### Codex Multi-Select Simulation

`request_user_input` has no native multi-select. When the calling engine file specifies `allow_multiple: true` (e.g., skill-composition §4, stash §3), simulate multi-select on Codex/CLI by:

1. List all options as numbered choices (same as CLI/Other fallback).
2. At end of prompt, add: "可以多选，用逗号分隔序号 (e.g., 1,3,4)" / "Multi-select: reply with comma-separated numbers (e.g., 1,3,4)".
3. Parse the user's response to extract multiple selections.
4. If `request_user_input` IS available, use `autoResolutionMs` (see below) to avoid indefinite blocking.

#### Codex `request_user_input` Auto-Resolution

When using `request_user_input` on Codex, set `autoResolutionMs` to a value between 60000 and 240000 when the question is non-blocking (e.g., next-step prompts B.8, skill selection). This allows the session to continue with best judgment if the user doesn't answer. Omit `autoResolutionMs` only for decisions that genuinely require explicit user confirmation (B.0 critical decisions, Pre-Dev scope).

**Usage rule**: When any engine file says "use `AskQuestion`", substitute the platform's mechanism from this table. Keep label language (zh/en) as specified in the calling file. Always include `cancel` and escape options as defined.

### F.3 Sub-Agent / Worker Dispatch (maps token-optimization §2, context-protocol §10, special-flows §2.2)

Replace all Sub-Agent / Worker references with platform-native mechanisms:

| Platform | Sub-Agent Mechanism |
|----------|---------------------|
| **Cursor** | Built-in worker/sub-agent spawn (platform-native parallel workers) |
| **Claude Code** | `Task` tool — pass instructions as prompt, receive structured output |
| **Codex** | **Thread-based multi-agent model.** Codex provides multi-agent through thread operations: `create_thread` (spawn agent), `send_message_to_thread` (assign task + await result), `handoff_thread` (transfer ownership). Each thread runs as an independent agent with its own context. |
| **CLI / Other** | Main agent serial execution only |

#### Codex Thread-Agent Dispatch Protocol

When `sub_agents` is `auto` or `on` and platform is Codex, dispatch tasks via threads:

| Step | Action | Tool |
|------|--------|------|
| 1. Spawn | Create an agent thread for each parallelizable task | `create_thread` |
| 2. Assign | Send task instructions + context slice to each thread | `send_message_to_thread` |
| 3. Collect | Each agent returns a result (≤30 line summary, same cap as other platforms) | Read thread reply |
| 4. Merge | Main agent reads code directly from disk; thread raw output never enters main context | Standard Read |

| Scenario | Codex Thread Action |
|----------|---------------------|
| Phase 0 exploration (monorepo) | 1 `create_thread` for stack scan; main agent handles topology |
| Phase 2 feature parallelism (≥5 features, L/XL) | 1 `create_thread` per `features/FN.md` writer; main agent merges index |
| Phase 3 independent tasks (≥3, L/XL) | 1 `create_thread` per task; main agent does Pre-Dev + Change Impact |
| Phase 4 | NEVER spawn threads — test execution is I/O bound |
| Failure/timeout | Mark thread as failed in `03-progress.md`; main agent retries serially once with narrower scope |
| Conflict (same file modified by 2 threads) | Abort thread outputs; main agent merges from `git diff` |

**Codex thread token accounting**: Each `create_thread` + `send_message_to_thread` round-trip has an overhead of approximately **4000 tokens** (not 8000). The `metrics.json` token estimation formula (§F.8) uses this value for Codex.

**Worker return format** (all platforms): ≤30 line summary. Main agent reads code directly for merge. Worker raw output never enters main context.

### F.4 Slash Command Trigger (maps activation rule B.1)

OmniDev activates when user message (after optional whitespace) begins with `/od`. Platform-specific trigger setup:

| Platform | Trigger Mechanism |
|----------|------------------|
| **Cursor** | `.cursor/rules/*.mdc` file + `skills/od/` slash command auto-complete |
| **Claude Code** | `.claude/skills/od/SKILL.md` + `CLAUDE.md` referencing `/od` as trigger phrase |
| **Codex** | `~/.codex/skills/od/SKILL.md` — detected by Codex skill system via `description` field; activation by `/od` prefix in user message |

**Precedence clarification** (per B.1): On ALL platforms, `/od` is a **prefix match**, not an exact match. `/od h`, `/od re`, `/od onboard`, etc. all activate OmniDev.

### F.5 Skill Discovery Paths (maps skill-composition §2)

Skill discovery scans the following directories in priority order. The first priority is always project-local skills; remaining paths are user-level:

| Priority | Path | Platform |
|----------|------|----------|
| 1 | `.cursor/skills/` | Cursor (project-level) |
| 2 | `.claude/skills/` | Claude Code (project-level) |
| 3 | `~/.cursor/skills/` | Cursor (user-level) |
| 4 | `~/.claude/skills/` | Claude Code (user-level) |
| 5 | `~/.codex/skills/` | Codex (user-level) |
| 6 | `~/.agents/skills/` | Generic agent skills (user-level) |

**Codex note**: Codex's skill system may pre-load skill manifests into app-context `<skills_instructions>`. After scanning `~/.codex/skills/`, cross-reference with any skill descriptors already present in the system context to avoid re-reading already-available metadata.

### F.6 MCP Configuration Path

When Phase 3/4 needs MCP servers, check the platform-specific config:

| Platform | MCP config file to check |
|----------|--------------------------|
| **Cursor** | `.cursor/mcp.json` |
| **Claude Code** | `.claude/mcp.json` or `~/.claude/mcp.json` |
| **Codex** | Use the following tools in order:
1. `list_mcp_resources` — discover available resources across all MCP servers
2. `list_mcp_resource_templates` — discover parameterized resource templates
3. `read_mcp_resource` — read a specific resource by server name + URI (exact match required) |

#### Codex MCP Discovery Protocol

Unlike Cursor/Claude Code which read a static config file, Codex discovers MCP capabilities dynamically at runtime:

```
Step 1: list_mcp_resources
  → Returns all available resources with server names and URIs
  → Example: server="sre-db-mcp", uri="sre-db://schemas/users"

Step 2: list_mcp_resource_templates
  → Returns parameterized templates (e.g., query builder, log search)
  → Example: server="sre-log-mcp", uri="sre-log://query/{app}/{env}"

Step 3: read_mcp_resource
  → Reads actual data from a specific resource
  → Requires: server name (exactly as returned by list) + resource URI
```

**When to use each**:
- **Phase 0/1**: Run `list_mcp_resources` to understand available services (DB, browser, logging, etc.). Note results in `00-project-context.md` § MCP Services.
- **Phase 3**: Use `read_mcp_resource` to verify DB structures, mock data against real schemas.
- **Phase 4**: Use `read_mcp_resource` for browser-based E2E tests, DB state verification.

**MCP availability check**: Before Phase 3, run `list_mcp_resources`. If critical MCP servers are missing (e.g., no DB MCP for a backend project), suggest installation to the user — do NOT fail silently. If no MCP servers are configured, the tool returns empty; note this and recommend `codex mcp add` to the user.

### F.7 Platform Identity in Install/Update Docs

| Platform | Skill install path | Rules install path |
|----------|-------------------|---------------------|
| **Cursor** | `.cursor/skills/od/` | `.cursor/rules/` (`.mdc` files) |
| **Claude Code** | `.claude/skills/od/` (project) or `~/.claude/skills/od/` (user) | N/A — trigger via `SKILL.md` only |
| **Codex** | `~/.codex/skills/od/` (user-level) | N/A — trigger via `SKILL.md` only; see `rules/03-omnidev-workflow.codex.md` for optional always-apply rule file |

### F.8 Codex Context Compaction Awareness

Codex performs **automatic context compaction** when the conversation exceeds token limits. This is a platform-level mechanism distinct from OmniDev's occupancy controls. Key impacts and mitigations:

| Aspect | Risk | Mitigation |
|--------|------|------------|
| **Session continuity** | Compaction summarizes conversation history; phase state held in conversation memory may be lost | Write to state files **before** every tool call that might trigger a turn boundary. Never rely on conversation memory for phase state — always persist to disk first. |
| **Token estimation** | Codex compaction consumes tokens invisibly (compaction itself has token cost) | Mark Codex entries in `metrics.json` with `platform: "codex"`. Apply `codex_compaction_multiplier` (default 1.3) to estimated_tokens for Codex events. Thread agent overhead is ~4000 tokens per spawn (not 8000). |
| **Resume reliability** | After compaction + `/od re`, the AI's context is a summary, not the original conversation | `session-log.md` YAML frontmatter MUST be parseable independently. All critical state (`last_phase`, `last_task_group`, `active_feature`) lives in YAML fields, not prose. |
| **Occupancy model** | HOT/WARM/COLD line counts become unreliable after compaction (the model can't see what was purged) | After compaction, reset HOT+WARM estimates to conservative defaults (HOT 80, WARM 40). Rebuild from state files only. Defensive purge: assume all non-state-file context is lost. |
| **Double compression** | OmniDev `/od compress` + Codex auto-compaction may over-compress and lose information | On Codex, `/od compress` only archives `03-progress.md` (per special-flows §4); skip the full context occupancy report and purge. Let Codex handle conversation compaction. OmniDev occupancy guards (§B.18) still apply but use defensive defaults. |
| **Turn counting** | OmniDev's 25-turn compress trigger (context-occupancy §6.3) becomes unreliable after compaction resets the visible turn count | On Codex, trigger `/od compress` at 15 turns (not 25) to stay ahead of Codex's own compaction threshold. |

**Codex-specific config defaults** (merge into `config.json`):

```json
{
  "codex_compaction_multiplier": 1.3,
  "codex_conservative_occupancy": true,
  "codex_thread_overhead_tokens": 4000,
  "codex_max_turns_before_compress": 15
}
```
