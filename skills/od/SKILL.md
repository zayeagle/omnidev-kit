---
name: od
description: >-
  OmniDev workflow. Load ONLY when: (1) message STARTS WITH /od, OR (2) skill explicitly
  attached/invoked this turn. Resume: /od re only. Advance: /od n, /od ad, etc.
  Bare 1/n/continue without /od does NOT trigger. No chat-context inference.
  Supports Cursor, Claude Code, and Codex.
---

# OmniDev Workflow Skill

**Single source of truth for OmniDev rules. Applies ONLY when [trigger-gate](engine/trigger-gate.md) activates.**

---

## A. Command Reference

→ Full reference in [engine/commands.md](engine/commands.md). Load only on `/od h` or `/od help`.

---

## B. Core Rules

### B.0 — 不确定就问，禁止自我发挥
**最高优先级**：任何不确定/歧义/猜测 → 停下来确认。删改/部署等破坏性操作默认"不执行"。
→ Full rules: [engine/context-lifecycle.md](engine/context-lifecycle.md) §1 · [engine/interactive-prompt.md](engine/interactive-prompt.md) §4.7

### B.1 — Trigger & Activation
**仅 Signal A** (`/od` 前缀) 或 **Signal B** (skill 被显式 invoke) 才激活。Phase 0–5 按序执行；`/od re` 磁盘恢复；bare `1`/`n`/`继续` 不触发。
→ [engine/trigger-gate.md](engine/trigger-gate.md) · [engine/activation.md](engine/activation.md)

### B.4 — Interactive Prompt (主要工作模式)
`interactive_mode: true` 默认开启。决策点 **必须先调原生工具** (`AskUserQuestion`/`request_user_input`)，与 checkpoint 同 turn 发出；禁止仅 prose。弹窗只做选择确认，结论/上下文走对话 prose。
→ [engine/interactive-prompt.md](engine/interactive-prompt.md)

### B.11 — Session Resume
`/od re` 从 `session-log.md` YAML frontmatter 恢复；`/od re [payload]` 续传变更；`/od x` 保存退出。禁止对话上下文推断。
→ [engine/session-memory.md](engine/session-memory.md)

---

### Quick Reference (其余规则详见对应 engine 文件)

| Rule | Short | Reference |
|------|-------|-----------|
| B.2 Workflow | Blueprint→Plan→Dev→Test→Deploy · S→P3, M→P2, L/XL→P1 | [activation.md](engine/activation.md) §3 |
| B.3 State Files | `docs/omnidev-state/` · active+history 配对 · append-only | [engine/document-history.md](engine/document-history.md) |
| B.5 Context Lifecycle | HOT≤150 · WARM≤250 · COLD 磁盘按需 · Phase 结束 purge | [engine/context-lifecycle.md](engine/context-lifecycle.md) |
| B.6 Config | `/od cfg` · `interactive_mode`/`auto_checkpoint`/`design_split` | [engine/user-preferences.md](engine/user-preferences.md) |
| B.8 Checkpoint | ≤12 行 · 2-4 选项 · STOP-WAIT | [engine/special-flows.md](engine/special-flows.md) §3.1 |
| B.9 Progress | `[✅/🔄/⏳] Task — Time` → `03-progress.md` | [phases/03-development.md](phases/03-development.md) §1 |
| B.10 Errors | Log → diagnose → propose fix → confirm (B.0) | [engine/special-flows.md](engine/special-flows.md) §5 |
| B.12 Stash | `/od st` save, `/od po` restore | [engine/stash.md](engine/stash.md) |
| B.13 Governance | `/od gv` token audit | [engine/governance.md](engine/governance.md) |
| B.14 Doc Sync | 需求变更 → 确认 → 归档到 `*-history.md` → 更新 active | [engine/special-flows.md](engine/special-flows.md) §2 |
| B.15 Confirm Throttling | S: minimal, M: reduced, L/XL: full | [phases/03-development.md](phases/03-development.md) §1.1 |
| B.16 Git Safety | 禁止 auto-commit · `git stash` 仅 `auto_checkpoint: true` | [engine/metrics.md](engine/metrics.md) |
| B.17 Token Opt | Read cap 150行 · Sub-agent ≤30行 report · diff `--stat` 优先 | [engine/token-optimization.md](engine/token-optimization.md) |
| B.18 Occupancy | HOT+WARM≤300 · section切片 · 路径指针代全文 | [engine/context-lifecycle.md](engine/context-lifecycle.md) |
| B.19 Doc History | active+history 双文件 · append-only · workflow 只加载 active | [engine/document-history.md](engine/document-history.md) |
| B.20 Test Strategy | UNIT强制 · INT/E2E/SMK/REG 按复杂度组合 · Gap Backfill | [engine/test-strategy.md](engine/test-strategy.md) |
| B.21 Deploy | Makefile + 一键部署 · Greenfield docker+k8s · 生产需确认 | [phases/05-deploy.md](phases/05-deploy.md) |

---

## C. Phase Execution Protocol

### C.0 Phase & Engine File Loading

| Target | File to Load |
|--------|-------------|
| **Every `/od` activation (first)** | [engine/activation.md](engine/activation.md) |
| **Every decision / checkpoint** | [engine/interactive-prompt.md](engine/interactive-prompt.md) |
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
| Phase transition (exit/enter) | [engine/context-lifecycle.md](engine/context-lifecycle.md) + [engine/context-lifecycle.md](engine/context-lifecycle.md) |
| Document history / archive | [engine/document-history.md](engine/document-history.md) |
| Test strategy / Phase 4 layers | [engine/test-strategy.md](engine/test-strategy.md) |
| Multi-agent architecture | [engine/multi-agent-architecture.md](engine/multi-agent-architecture.md) |
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
→ [engine/context-lifecycle.md](engine/context-lifecycle.md), [engine/context-lifecycle.md](engine/context-lifecycle.md) §6–§12

---

## D. Project Type Awareness

| Type | Behavior |
|------|----------|
| **Legacy** | Follow existing conventions 100%. Minimize new dependencies. Match test framework in repo. |
| **Greenfield** | OpenSpec / TDD / DDD OK. Scaffold tests, CI, deploy manifests. Higher coverage targets. |
| **Monorepo** | Tag tasks with `[pkg:name]`; deploy/test per affected package. See Phase 0/2 instructions. |

## E. MCP Integration
During Phase 3 & 4, proactively use available MCP servers: Database MCP (verify structures, mock data, test fixtures), **Browser MCP / Playwright MCP (E2E — Phase 4 mandatory when fullstack)**. Check MCP config per SKILL.md §F.6 before complex tasks; suggest installation if critical MCP missing.

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

**Primary mode**: popup interaction is the default OmniDev UX. Execute [interactive-prompt.md](engine/interactive-prompt.md) at every decision point.

| Platform | Interactive Prompt Mechanism |
|----------|------------------------------|
| **Cursor** | `AskQuestion` tool (native), `allow_multiple: true` for multi-select |
| **Claude Code** | **`AskUserQuestion` tool — REQUIRED same turn** at every checkpoint. Copy-paste JSON from interactive-prompt.md §4. Works in **all collaboration modes**. |
| **Codex** | **`request_user_input` tool — REQUIRED same turn** in **Plan AND Default/Code mode**. Copy-paste JSON from interactive-prompt.md §5. Enable Default mode: `[features] default_mode_request_user_input = true` in `~/.codex/config.toml`. |
| **CLI / Other** | Pseudo-popup §E → minimal text §9 |

#### Mandatory Tool Invocation (Claude Code & Codex)

When `interactive_mode=true`:

1. Output checkpoint/decision summary (≤12 lines)
2. **Immediately invoke** native tool with matching §4/§5 template — **forbidden** to end turn with prose-only options
3. On tool error or "unavailable in this chat mode" → pseudo-popup §E **same turn**
4. Log `native_attempted: true` in session-log or metrics

#### Codex Default/Code Mode Setup

```toml
# ~/.codex/config.toml
[features]
default_mode_request_user_input = true
```

CLI: `codex features enable default_mode_request_user_input` — restart Codex. Without this flag, Codex falls back to pseudo-popup §E (structured table UX, not plain text).

#### Codex Multi-Select Simulation

`request_user_input` has no native multi-select. When the calling engine file specifies `allow_multiple: true` (e.g., skill-composition §4, stash §3), simulate multi-select on Codex/CLI by:

1. List all options as numbered choices (same as CLI/Other fallback).
2. At end of prompt, add: "可以多选，用逗号分隔序号 (e.g., 1,3,4)" / "Multi-select: reply with comma-separated numbers (e.g., 1,3,4)".
3. Parse the user's response to extract multiple selections.
4. If `request_user_input` IS available, use `autoResolutionMs` (see below) to avoid indefinite blocking.

#### Codex `request_user_input` Auto-Resolution

When using `request_user_input` on Codex, set `autoResolutionMs` to a value between 60000 and 240000 when the question is non-blocking (e.g., next-step prompts B.8, skill selection). This allows the session to continue with best judgment if the user doesn't answer. Omit `autoResolutionMs` only for decisions that genuinely require explicit user confirmation (B.0 critical decisions, Pre-Dev scope).

**Usage rule**: When any engine file says "use `AskQuestion`" or "platform interactive prompt", execute [interactive-prompt.md](engine/interactive-prompt.md) — native tool first, **text fallback mandatory** if unavailable or error.

### F.3 Sub-Agent / Worker Dispatch (maps token-optimization §2, context-lifecycle §10, special-flows §2.2)

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
| Phase 4 | NEVER spawn threads for UNIT/INT — **exception**: E2E Playwright runner via sub-agent when `allow_e2e_sub_agent: true` |
| Failure/timeout | Mark thread as failed in `03-progress.md`; main agent retries serially once with narrower scope |
| Conflict (same file modified by 2 threads) | Abort thread outputs; main agent merges from `git diff` |

**Codex thread token accounting**: Each `create_thread` + `send_message_to_thread` round-trip has an overhead of approximately **4000 tokens** (not 8000). The `metrics.json` token estimation formula (§F.8) uses this value for Codex.

**Worker return format** (all platforms): ≤30 line summary. Main agent reads code directly for merge. Worker raw output never enters main context.

→ **Recommended multi-agent model**: Orchestrator + selective Phase/Task Workers — [multi-agent-architecture.md](multi-agent-architecture.md)

### F.4 Trigger Gate (maps activation rule B.1)

→ Full spec: [engine/trigger-gate.md](engine/trigger-gate.md)

| Platform | How user triggers OmniDev |
|----------|---------------------------|
| **Cursor** | `/od …` prefix **OR** attach `@od` skill / skill picker (no `/od` required when skill is attached) |
| **Claude Code** | `/od …` prefix **OR** invoke `od` skill (Claude loads SKILL.md into context) |
| **Codex** | `/od …` prefix **OR** invoke `od` skill for the message |

| Platform | Gate enforcement file |
|----------|----------------------|
| **Cursor** | `.cursor/rules/01-omnidev-workflow.mdc` (`alwaysApply: true`) + `AGENTS.md` |
| **Claude Code** | `CLAUDE.md` + `rules/02-omnidev-workflow.claude.md` |
| **Codex** | `rules/03-omnidev-workflow.codex.md` + skill `description` |

**Not a trigger**: od skill only listed without explicit invoke; bare checkpoint replies without `/od`.

**Iteration**: Every workflow step requires new message with `/od` prefix (or Signal B). Checkpoint → STOP → user sends `/od n` / `/od ad` / UI pick.

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
| **Turn counting** | OmniDev's 25-turn compress trigger (context-lifecycle §6.3) becomes unreliable after compaction resets the visible turn count | On Codex, trigger `/od compress` at 15 turns (not 25) to stay ahead of Codex's own compaction threshold. |

**Codex-specific config defaults** (merge into `config.json`):

```json
{
  "codex_compaction_multiplier": 1.3,
  "codex_conservative_occupancy": true,
  "codex_thread_overhead_tokens": 4000,
  "codex_max_turns_before_compress": 15
}
```
