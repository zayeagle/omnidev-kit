---
name: od
description: >-
  OmniDev workflow. Activate ONLY when message STARTS WITH /od or $od.
  Attaching @od without /od does NOT start Phase 0 (reference only).
  Resume: /od re or $od re. Advance: /od n, /od ad, etc. Bare 1/n/continue does NOT
  trigger. No chat-context inference. Supports Cursor, Claude Code, and Codex.
---

# OmniDev Workflow Skill

**Single source of truth for OmniDev rules. Applies ONLY when [trigger-gate](engine/trigger-gate.md) activates (Signal A).**

---

## A. Command Reference

→ Full reference in [engine/commands.md](engine/commands.md). Load only on `/od h` or `/od help`.

---

## B. Core Rules

### B.0 — When unsure, ask; do not invent
**Highest priority**: Any uncertainty / ambiguity / guess → stop and confirm. Destructive actions (delete, deploy, etc.) default to "do not execute".
→ Full rules: [engine/context-lifecycle.md](engine/context-lifecycle.md) §1 · [engine/interactive-prompt.md](engine/interactive-prompt.md) §3.4 `b0_confirm`

### B.1 — Trigger & Activation
Activate **only** on **Signal A** (`/od` or `$od` line-start prefix). Attaching `@od` / invoking the skill **without** that prefix does **not** start the workflow (reference only). Phases 0–5 in order; `/od re`/`$od re` resume from disk; bare `1`/`n`/`continue` do not trigger (may show a one-line "OmniDev not active" tip).
→ [engine/trigger-gate.md](engine/trigger-gate.md) · [engine/activation.md](engine/activation.md)

### B.4 — Interactive Prompt (primary working mode)
`interactive_mode: true` is on by default. At decision points **must call the native tool first**, same turn as the summary; prose-only is forbidden. Keep short chat summaries (Phase 0 ≤6 lines); forbid `od_interactive` metadata or "reply 1/2/3". On native failure → §8 clean `/od`/`$od` table. **Always STOP — WAIT** (never auto-continue after a pseudo-popup).
→ [engine/interactive-prompt.md](engine/interactive-prompt.md)

### B.11 — Session Resume
`/od re` or `$od re` resumes from `session-log.md` YAML frontmatter; with payload continues changes; `/od x` saves and exits. Do not infer from chat context.
→ [engine/session-memory.md](engine/session-memory.md)

---

### Quick Reference (other rules: see corresponding engine files)

| Rule | Short | Reference |
|------|-------|-----------|
| B.2 Workflow | Blueprint→Plan→Dev→Test→Deploy · S→P3, M→P2, L/XL→P1 | [activation.md](engine/activation.md) §3 |
| B.3 State Files | `docs/omnidev-state/` · active+history pair · append-only | [engine/document-history.md](engine/document-history.md) |
| B.5 Context Lifecycle | HOT≤150 · WARM≤250 · COLD disk on-demand · purge on phase end | [engine/context-lifecycle.md](engine/context-lifecycle.md) |
| B.6 Config | `/od cfg` · `interactive_mode`/`auto_checkpoint`/`design_split` | [engine/user-preferences.md](engine/user-preferences.md) |
| B.8 Checkpoint | ≤12 lines · 2-4 options · STOP-WAIT | [engine/special-flows.md](engine/special-flows.md) §3.1 |
| B.9 Progress | `[✅/🔄/⏳] Task — Time` → `03-progress.md` | [phases/03-development.md](phases/03-development.md) §1 |
| B.10 Errors | Log → diagnose → propose fix → confirm (B.0) | [engine/special-flows.md](engine/special-flows.md) §5 |
| B.12 Stash | `/od st` save, `/od po` restore | [engine/stash.md](engine/stash.md) |
| B.13 Governance | `/od gv` token audit | [engine/governance.md](engine/governance.md) |
| B.14 Doc Sync | Requirement change → confirm → archive to `*-history.md` → update active | [engine/special-flows.md](engine/special-flows.md) §2 |
| B.15 Confirm Throttling | Required at phase end; mid-phase gates for S/M/L per Phase 3 §1.1 (do not skip all for S) | [phases/03-development.md](phases/03-development.md) §1.1 |
| B.16 Git Safety | No auto-commit · `git stash` only when `auto_checkpoint: true` | [engine/metrics.md](engine/metrics.md) |
| B.17 Token Opt | Read cap 150 lines · Sub-agent ≤30-line report · prefer diff `--stat` | [engine/token-optimization.md](engine/token-optimization.md) |
| B.18 Occupancy | HOT+WARM≤300 · section slices · path pointers instead of full text | [engine/context-lifecycle.md](engine/context-lifecycle.md) |
| B.19 Doc History | active+history dual files · append-only · workflow loads active only | [engine/document-history.md](engine/document-history.md) |
| B.20 Test Strategy | UNIT required · INT/E2E/SMK/REG by complexity · Gap Backfill | [engine/test-strategy.md](engine/test-strategy.md) |
| B.21 Deploy | Makefile + one-click deploy · Greenfield docker+k8s · production needs confirm | [phases/05-deploy.md](phases/05-deploy.md) |

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
✅ Phase N complete: [Name]
📦 Artifacts: [state files created/updated]
📍 Progress: Phase 0 ✅ → Phase 1 ✅ → Phase 2 🔧 → ...
🔔 Next phase: Phase N+1 — [Name]
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

On `/od` or `$od` activation, check `platform_override` first; else detect via tools:

| # | Signal | Platform |
|---|--------|----------|
| 1 | `AskUserQuestion` tool exists | **Claude Code** |
| 2 | `AskQuestion` tool exists | **Cursor** |
| 3 | `request_user_input` OR `create_thread` | **Codex** |
| 4 | `Task` without AskQuestion/AskUserQuestion | **Claude Code** (likely) |
| 5 | Fallback | **CLI / Other** |

Store detected platform in session memory; do not re-detect mid-session.

### F.2 Interactive Prompt (maps B.4, B.8, skill-composition §4, special-flows §3.1, stash §2-§3, session-memory §6)

**Primary mode**: popup interaction is the default OmniDev UX. Execute [interactive-prompt.md](engine/interactive-prompt.md) at every decision point.

| Platform | Interactive Prompt Mechanism |
|----------|------------------------------|
| **Cursor** | **`AskQuestion` tool — REQUIRED same turn** when present. Copy-paste JSON from interactive-prompt.md **§4**. Chat: short summary only; no YAML metadata dump. |
| **Claude Code** | **`AskUserQuestion` tool — REQUIRED same turn** at every checkpoint. Copy-paste JSON from interactive-prompt.md **§5**. Works in **all collaboration modes**. |
| **Codex** | **`request_user_input` tool — REQUIRED same turn** in **Plan AND Default/Code mode**. Copy-paste JSON from interactive-prompt.md **§6**. Enable Default mode: `[features] default_mode_request_user_input = true` in `~/.codex/config.toml`. |
| **CLI / Other** | Pseudo-popup §8 → minimal text §9 |

#### Mandatory Tool Invocation (Cursor / Claude Code / Codex)

When `interactive_mode=true`:

1. Output **short** summary only (Phase 0 ≤6 lines; checkpoint ≤12 lines) — do not paste the full assessment into chat
2. **Immediately invoke** native tool using §3 catalog + §4/§5/§6 wrapper — **forbidden** to end turn with prose-only options when the tool exists
3. On tool **absent**, error, or "unavailable in this chat mode" → clean pseudo-popup §8 **same turn** (forbid "reply 1/2/3"; must use `/od` or `$od`) → **STOP — WAIT** (forbid autoResolution / auto-continue)
4. Log `native_attempted: true` + method to **session-log** (do not paste into chat)
5. Decision points: follow [interactive-prompt.md](engine/interactive-prompt.md) **§3 Decision Matrix** (full Phase 0–5 coverage, including S-level `phase0_s_fastpath`)

#### Codex Default/Code Mode Setup

```toml
# ~/.codex/config.toml
[features]
default_mode_request_user_input = true
```

CLI: `codex features enable default_mode_request_user_input` — restart Codex. Without this flag, Codex falls back to pseudo-popup §8 (clean table UX, not plain text).

#### Codex Multi-Select Simulation

`request_user_input` has no native multi-select. When `allow_multiple: true`:

1. Sequential single-select, or §8 + "multi-select OK: explain in next message"
2. Parse user response for multiple selections
3. **Do NOT** set `autoResolutionMs` (unless `config.codex_auto_resolve: true`)

#### Codex `autoResolutionMs` — OFF by default

**By default forbid** `autoResolutionMs`, to avoid auto-picking when unanswered and breaking full-flow interaction.
Only when `docs/omnidev-state/config.json` → `"codex_auto_resolve": true` and the decision point explicitly allows it, may you set 60000–240000 for non-B.0 points. Blocking points such as B.0 / deploy_prod / pre_dev **always** omit this field.

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

| Platform | How user triggers OmniDev **workflow** |
|----------|----------------------------------------|
| **Cursor** | Message starts with `/od …` (or `$od …`) only |
| **Claude Code** | Message starts with `/od …` (or `$od …`) only |
| **Codex** | Message starts with `/od …` **or** `$od …` only |

`@od` attach / skill invoke without `/od` prefix → **not** a workflow trigger (skill may be used as reference).

| Platform | Gate enforcement file |
|----------|----------------------|
| **Cursor** | `.cursor/rules/01-omnidev-workflow.mdc` (`alwaysApply: true`) + `AGENTS.md` |
| **Claude Code** | `CLAUDE.md` + `rules/02-omnidev-workflow.claude.md` |
| **Codex** | `rules/03-omnidev-workflow.codex.md` + skill `description` |

**Not a trigger**: skill listing / `@od` without `/od` prefix; mid-sentence `/od` mention; bare checkpoint replies.

**Iteration**: Every typed workflow step requires `/od` or `$od` prefix. Checkpoint → STOP → UI pick **or** next full `/od`/`$od` command.

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

`/od up` and `/od i` support **`install_scope`**: `project` (default) | `user`. See [special-flows.md](engine/special-flows.md) §6.1.

| Platform | `project` skill path | `user` skill path | Rules |
|----------|----------------------|-------------------|-------|
| **Cursor** | `.cursor/skills/od/` | `~/.cursor/skills/od/` | Project only: `.cursor/rules/` (`.mdc`) + `AGENTS.md` |
| **Claude Code** | `.claude/skills/od/` | `~/.claude/skills/od/` | N/A — trigger via SKILL.md |
| **Codex** | Remap to `user` (no project skill path) | `~/.codex/skills/od/` | N/A — see `rules/03-omnidev-workflow.codex.md` |

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
