# Context Protocol (On-Demand)

**Load this file ONLY during Phase transitions or when `/od compress` is triggered.**

---

## 1. Content Classification & Unload Rules

| Content Type | Example | Unloadable? | Condition |
|-------------|---------|-------------|-----------|
| **Raw tool output** | Read file content, Grep results, Shell logs, git diff | ✅ Yes | Key info already extracted into state file or checkpoint |
| **Intermediate reasoning** | Requirement analysis, approach comparison | ✅ Yes | Conclusion written to state file |
| **Phase instruction file** | `00-assessment.md`, `01-blueprint.md`, `02-planning.md` | ✅ Yes | Already exited that phase |
| State files | `02-plan.md`, `03-progress.md`, `00-project-context.md` | ⚠️ Section-only | Load slices per [context-occupancy.md](context-occupancy.md) §4–§5; never full file if over budget |
| **User decisions & feedback** | Phase skip choices, API format requirements | ❌ Never | Must persist in session-log or user-preferences |

---

## 2. Dependency Chain

```
Phase 0 → 00-project-context.md → Phase 1, 2, 3, 4, 5 (never unload)
Phase 1 → 01-blueprint.md       → Phase 2 (unloadable after Phase 2; essence in 02-plan.md)
Phase 2 → 02-plan.md, 04-design.md (index), features/FN.md, 05-test-plan.md → Phase 3, 4
Phase 3 → 03-progress.md        → Phase 4 (never unload)
Phase 4 → 05-test-report.md     → Phase 5 (never unload early)
Phase 5 → 06-release-notes.md   → session end
```

**Any state file referenced in a downstream `context_requires.read` MUST NOT be unloaded.** `features/FN.md` files are loaded one-at-a-time on demand — unload after task completes. `04-design.md` index stays loadable; individual feature files are ephemeral in context.

---

## 3. Phase Exit Protocol

When exiting Phase N (after Checkpoint, before loading Phase N+1):

1. **Persist to state file**: Write key outputs to the target state file. Ensure nothing needed downstream depends solely on conversation history.
2. **Update metrics.json**: Append phase_exit event per [metrics.md](metrics.md) §2.
3. **Transition summary** (≤ 5 lines):

   ```
   📌 Phase N context summary:
   - [What was persisted and where]
   - [Key concerns for next phase]
   - [User decisions/preferences]
   ```

4. **Mark unloadable content**:

   ```
   ⏹️ Raw outputs no longer needed (key info in state files):
   - Phase N instruction file full text
   - Phase N Read/Grep/Shell raw returns
   - Phase N intermediate reasoning
   ✅ Still valid (state files, will reload on demand):
   - [List state files written/updated by this phase]
   ```

---

## 4. Phase Entry Protocol

When entering Phase N+1:

1. Load new phase instruction file
2. Re-read dependent state files from filesystem (NOT from conversation history)
3. Skip content listed in previous phase's `unload` declaration
4. Active context should now consist of:
   - SKILL.md core rules (resident)
   - Current phase instruction (just loaded)
   - State files per `context_requires.read` (just re-read from disk)
   - user-preferences.md (if exists, resident)
   - Previous transition summary (≤ 5 lines)

### 4.5 Resume Entry Protocol (after `/od re`)

1. Load session-log.md frontmatter only (YAML + 恢复指引, max 20 lines)
2. Identify active phase from last_phase
3. Load that phase instruction file
4. Load only state files from session-log's state_files manifest
5. Skip: previous phase instructions, raw tool outputs, intermediate reasoning
6. Max context: 250 lines

---

## 5. Backtrack Rule

If Phase N+1 needs a detail not persisted in state files:

1. First check state files
2. If missing: re-read the source file from project (allowed)
3. Forbidden: scrolling back through conversation history for raw tool outputs

---

## 6. Context Budget (Occupancy)

| Layer | Budget | Content |
|-------|--------|---------|
| **HOT** | ≤150 lines | Current task: phase instruction header + active group + 1 feature slice |
| **WARM** | ≤250 lines | Phase-scoped: plan index, design index, 3-line decisions |
| **COLD** | unlimited on disk | features/, test plan, blueprint, tool raw, history |
| **Total resident** | ≤300 lines | HOT + WARM |

| Context Type | Trimmable? | Over-limit Action |
|-------------|-----------|-------------------|
| SKILL.md | ❌ | Pointer-only for engine docs |
| Phase instruction | ⚠️ | Header + active section only when >80 lines |
| State files | ⚠️ | Section/group slice per [context-occupancy.md](context-occupancy.md) |
| Tool output (single) | ✅ | Summarize ≤5 lines → state file |
| Historical tool output | ✅ | Last 2 summaries only |
| Transition summary | ✅ | ≤5 lines, keep latest only |
| user-preferences.md | ❌ | ≤30 lines resident |

**Over 300 resident lines**: Purge §12 + `/od compress` before next tool call.

---

## 7. Trim Safety Rules

Before trimming anything, verify:

1. Not referenced in downstream `context_requires.read` — if yes, **do not trim**
2. Does not contain explicit user decisions — if yes, **persist first**
3. Is not a state file — state files are **never trimmed**

Safely trimmable:

- Raw tool outputs (if key info already extracted)
- Previous phase instruction files
- Intermediate reasoning (if conclusions already in output)

---

## 8. Auto-Compress Trigger

When AI detects context approaching capacity (slow responses, missing earlier info, truncated results):

1. Trigger `/od compress`: archive old progress, keep `03-progress.md` under 50 lines
2. Mark all tool outputs older than 3 turns as expired
3. Re-read from state files if prior info needed

---

## 9. `summarize_before_exit` Mechanism

```yaml
context_requires:
  summarize_before_exit:
    target: "02-plan.md"
    discard_after_write:
      - "source code scan results"
      - "intermediate Shell logs"
    retain:
      - "user decisions and feedback"
      - "state files in next phase's context_requires.read"
```

`discard_after_write` may only list raw tool outputs and intermediate processes — never state files or user decisions.

---

## 10. Sub-Agent Failure & Conflict Resolution

When parallel workers (Phase 0–3) fail or conflict:

| Situation | Action |
|-----------|--------|
| Worker timeout / error | Main agent retries once with narrower scope; if still fails, serialize and execute itself |
| Two workers modified same file | Abort worker outputs; main agent merges manually from git diff |
| Worker output contradicts plan | Main agent flags deviation; user confirms before accepting (B.0) |
| Explorer returns incomplete scan | Main agent fills gaps with targeted Read/Grep (max 5 files) |

Never silently discard failed worker output — log failure reason in `03-progress.md` or session-log.

---

## 11. Token Hard Guards (MANDATORY)

Enforce [token-optimization.md](token-optimization.md) at runtime:

1. **Read cap**: Before `Read`, check line count (via prior knowledge or `wc -l`). If > `max_read_lines` (default 150): use `offset`+`limit` or `Grep` — NEVER read full file except `04-design.md` index (≤60 lines).
2. **Single feature load**: Phase 3/4 may have at most **one** `features/FN.md` in context at a time.
3. **No double phase instructions**: Unload previous phase instruction before loading next (see §3 step 4).
4. **Tool output**: git diff → `--stat` default; test logs → failure summary only (§5).
5. **400-line breach**: Immediately lazy-load + run `/od compress`; do not proceed until resident context trimmed.
6. **25-turn session**: Suggest `/od compress` or `/od x` + `/od re` before next phase.

Violations MUST be logged to `metrics.json` as `type: "token_guard_triggered"`.

---

## 12. Context Occupancy Guards (MANDATORY)

Enforce [context-occupancy.md](context-occupancy.md):

1. **Layer check**: Before each tool call, estimate HOT+WARM lines. If > `max_resident_lines` (default 300): purge per occupancy §8 before proceeding.
2. **No stacking**: At most **1** phase instruction + **1** engine doc (context-protocol OR token-optimization, not both) in WARM simultaneously.
3. **Group-scoped plan**: Phase 3/4 load `02-plan.md` active group only (§5).
4. **Section-scoped context**: `00-project-context.md` per phase slice only (§4).
5. **Pointer responses**: Assistant messages reference file paths; never echo >20 lines of state file content.
6. **Checkpoint cap**: ≤12 lines (occupancy §7).
7. **Phase purge**: Execute §8 purge list on every phase transition.

Log breaches to `metrics.json` as `type: "occupancy_guard_triggered"`.
