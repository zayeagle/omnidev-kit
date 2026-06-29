# Token Optimization Protocol

→ Platform mapping: SKILL.md §F.3 (Sub-Agent/Worker Dispatch)

**Load on**: Phase 0 entry, phase transitions, `/od compress`, `/od gv --scope cost`.

**Goal**: Keep resident context ≤400 lines; minimize tool raw output; avoid Sub-Agent multiplication unless justified.

---

## 1. Config (`config.json`)

| Key | Default | Values | Effect |
|-----|---------|--------|--------|
| `sub_agents` | `"auto"` | `off` / `auto` / `on` | Sub-Agent spawn policy (§2) |
| `confirmation_level` | `"auto"` | `full` / `reduced` / `minimal` | B.15 confirmation throttling |
| `log_token_estimates` | `true` | bool | Write estimates to metrics.json on phase_exit |
| `design_split` | `true` | bool | Phase 2 uses index + `features/*.md` (§3) |
| `max_read_lines` | `150` | int | Hard cap per Read call unless user requests full file |

---

## 2. Sub-Agent Policy (`sub_agents`) — see SKILL.md §F.3 for platform mechanism

| Mode | Phase 0 | Phase 1 | Phase 2 | Phase 3 | Phase 4 |
|------|---------|---------|---------|---------|---------|
| **off** | Main agent only | Main agent only | Main agent serial | Main agent serial | Main agent only |
| **auto** | 1 explorer max if monorepo | 1 explorer if L/XL | Workers if features ≥5 AND L/XL | Workers if group has ≥3 independent tasks AND L/XL | Never |
| **on** | 2 explorers | 2–3 approach explorers | 1 worker/feature | 1 worker/task | Never |

**Default `auto` rules**:

- **S/M**: NEVER spawn Sub-Agents — main agent serial execution only.
- **L/XL**: Spawn only when estimated time saved > token cost (≥3 parallelizable units).
- **Phase 4**: NEVER spawn — test execution is I/O bound, not parallel-doc bound.
- Workers MUST return ≤30 line summary; main agent reads code directly for merge.

---

## 3. Split Design Documents (`design_split: true`)

Phase 2 writes:

```
docs/omnidev-state/[branch]/
├── 04-design.md              # INDEX ONLY — ≤60 lines
└── features/
    ├── F1.md                 # One feature — ≤40 lines
    ├── F2.md
    └── ...
```

### `04-design.md` (index)

```markdown
---
blueprint_ref: 01-blueprint.md
feature_count: N
last_updated: [timestamp]
---

# Design Index

| ID | Feature | Package | Design File | Tasks |
|----|---------|---------|-------------|-------|
| F1 | User login | pkg:api | features/F1.md | T1, T3 |

## Cross-Cutting Notes
[≤10 lines: shared auth, error format, etc.]
```

### `features/FN.md` (detail)

Same section structure as before (Business Context, Implementation Logic, Edge Cases, Data Changes) — **≤40 lines per file**.

**Phase 3/4 read rule**: Load `04-design.md` index at start; load **only** `features/{ID}.md` for the current task's feature(s). **FORBIDDEN**: Read entire `features/` directory or multiple feature files at once.

When `design_split: false` (legacy): single `04-design.md` allowed; MUST still lazy-load one `## Feature FN` section via Grep/offset Read.

---

## 4. Compact Test Plan (`05-test-plan.md`)

Use **table-first** format to cut token bulk ~50%:

```markdown
## Feature F1 Tests

| TC-ID | Type | Input (short) | Expected | Mock |
|-------|------|---------------|----------|------|
| TC-F1-01 | Happy | valid email+pwd | 200 + token | none |
| TC-F1-02 | Input | empty email | 400 E001 | none |
| TC-F1-03 | Dep-Fail | valid input | 503 | DB timeout mock |
```

Expand to prose ONLY on execution failure (append Notes under TC entry). Coverage Matrix stays as summary table.

---

## 5. Tool Output Summarization (MANDATORY)

Before any raw tool output enters conversation context:

| Tool | Rule |
|------|------|
| **Read** | If file > `max_read_lines`: use `offset`+`limit` or Grep. Never Read full `05-test-plan.md` / `features/*.md` directory |
| **git diff** | Default `--stat` only. Full diff only when fixing specific lines; then ±30 lines around hunk |
| **test runner** | Extract: pass/fail counts + failed TC names + first error line. Discard stack traces after diagnosis |
| **Grep** | `head_limit: 20` default; increase only with reason |
| **Shell build/lint** | Keep last 30 lines or error summary table |

Write 3–5 line summary to state file; mark raw output as **expired** in next turn.

---

## 6. Token Estimation (phase_exit)

When `log_token_estimates: true`, append to `metrics.json` events[]:

```json
{
  "type": "phase_exit",
  "phase": 2,
  "requirement_id": "req-xxx",
  "estimated_lines_loaded": 380,
  "estimated_tokens": 1520,
  "estimated_cost_tier": "medium",
  "sub_agents_spawned": 0,
  "confirmations_count": 1
}
```

**Estimation formula** (approximate):

```
estimated_tokens =
  (skill_lines + phase_instruction_lines + state_files_loaded_lines) × 4
  + (tool_output_lines × 3)
  + (conversation_turns × 200)
  + (sub_agents_spawned × platform_overhead)   # platform-dependent flat overhead per worker
```

**Platform overhead per sub-agent spawn**:

| Platform | Overhead (tokens) | Rationale |
|----------|-------------------|-----------|
| Cursor | 8000 | Full sub-agent session overhead |
| Claude Code | 8000 | Task tool round-trip |
| Codex | **4000** | Thread create + message + await; lower than Task tool |
| CLI / Other | 0 | Serial execution only |

For Codex, apply `codex_compaction_multiplier` (default 1.3) to the final total after platform overhead.

**Tier mapping**:

| estimated_tokens | Tier |
|------------------|------|
| < 8,000 | low |
| 8,000 – 25,000 | medium |
| > 25,000 | high |

Also update `requirements[].estimated_tokens_total` (running sum).

---

## 7. Session & Compress Triggers

| Trigger | Action |
|---------|--------|
| HOT+WARM > 300 lines | Purge + `/od compress` ([context-occupancy.md](context-occupancy.md) §9) |
| 15 turns same phase | Suggest compress |
| 25 turns total | Must compress or new session |
| `03-progress.md` > 100 lines | `/od compress` immediately |
| Same file Read 2+ times | Summarize → COLD |

Cross-ref: [context-occupancy.md](context-occupancy.md) for layer model.

---

## 8. Phase-Specific Quick Wins

| Phase | Optimization | Codex Note |
|-------|-------------|------------|
| 0 | Cache in `00-project-context.md`; skip re-scan if exists | If compaction suspected, reload from disk |
| 1 | Max 2 approaches (not 3) for M; 3 for L/XL only | — |
| 2 | Split design; table test plan; sub_agents auto = serial for M | Threads for ≥5 features L/XL; overhead ~4000/thread |
| 3 | Read `features/FN.md` + task output files only; diff --stat default | Write progress to disk before any tool call |
| 4 | Targeted REG by Module tag; coverage run once; lazy test sections | — |
| 5 | Document-only default; no deploy scan unless user confirms | — |

## 9. Platform Token Overrides

| Platform | Config Key | Default | Effect |
|----------|-----------|---------|--------|
| Codex | `codex_compaction_multiplier` | `1.3` | Multiplier on estimated_tokens to account for invisible compaction cost |
| Codex | `codex_thread_overhead_tokens` | `4000` | Overhead per `create_thread` + `send_message_to_thread` round-trip |
