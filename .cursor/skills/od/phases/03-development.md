# Phase 3 Instructions (Development & DevSecOps)
→ Platform mapping: SKILL.md §F (Platform Abstraction Layer)


```yaml
context_requires:
  read:
    - 00-project-context.md
    - 02-plan.md
    - 03-progress.md                 # if exists
    - 04-design.md                   # INDEX ONLY — never load all features/
  read_on_demand:
    - 04-design.md (grep `## Feature {FN}` for current task's feature: field) # default design_split:false
    - features/{FN}.md               # only when design_split:true
  scan:
    - ONLY paths from current task `outputs` and `depends`
  scan_limit: 8                      # reduced from 10 for token savings
  reload: 02-plan.md
  skip:
    - 01-blueprint.md, 05-test-report.md, 06-release-notes.md
    - features/*.md                  # bulk load forbidden — use read_on_demand
    - "*-history.md"
  unload:
    - "Phase 1-2 instruction files full text"
    - "01-blueprint.md full text"
    - "previously loaded features/FN.md"  # unload after task group completes
  summarize_before_exit:
    target: 03-progress.md
    discard_after_write:
      - "per-task code edit raw outputs"
      - "git diff full output — keep stat summary only"
      - "lint/build logs — keep error summary only"
```

→ Token rules: [token-optimization.md](../engine/token-optimization.md)
→ Occupancy: [context-lifecycle.md](../engine/context-lifecycle.md) §3 Phase 3

```yaml
context_occupancy:
  hot_max: 150
  warm_max: 80
  hot: ["02-plan active Group", "features/{FN}.md", "current source files"]
  warm: ["04-design.md active feature section", "03-progress snapshot"]
  cold: ["05-test-plan", "01-blueprint", "completed groups", "git diff full"]
  purge_on_task_complete: ["04-design.md feature section", "features/{FN}.md"]
  purge_on_group_complete: ["source file reads", "git diff stat summary retained in 03-progress"]
```

## 1. Execution Protocol

1. **Safety checkpoint**: Only if `auto_checkpoint: true` → `git stash`. Never auto-commit.
2. **Pre-Dev Scope** (B.15): Required per complexity. Keep output ≤25 lines for M.
3. **Load design**: `grep '## Feature {FN}' 04-design.md` → read only that section (≈20-40 lines). When `design_split: true`: read `features/FN.md` instead.
4. **Execute groups** from `02-plan.md`. Sub-agents per config (§1.2).
5. **After each task**: `[x]` in plan; archive progress; **unload** that feature's design section from context.
6. **git diff**: Always `--stat` first. Full diff only for active fix (±30 lines).
7. **Task-level recovery record** (new): after every task, append to `03-progress.md`:
   ```
   ✅ T3 · [files modified, comma-separated] · [time]
   ```
   When `/od x` interrupts mid-task (`[-]`): record `[-] T3 · files: [comma-separated] · [time]` so `/od re` knows what was touched.
8. **Change Impact** (B.15): Per complexity tier.
9. Log token estimate + `metrics.json` on phase exit.

---

## 1.1 Confirmation Levels (B.15) — Interactive Gates

All complexity levels **must** show `checkpoint` (B.8) popup at **phase end**. Intermediate gates:

| Complexity | Pre-Dev (`pre_dev`) | Per-Group Impact (`change_impact`) | Phase End |
|------------|---------------------|--------------------------------------|-----------|
| S | Only when departing from plan / user requests | Only when departing | **Required** `checkpoint` |
| M | **Required** once (interactive) | **Required** when departing | **Required** |
| L/XL | **Required** | **Required** every group | **Required** |

Invoke: [interactive-prompt.md](../engine/interactive-prompt.md) §3.12 → §4/§5/§6 → **STOP — WAIT**.
If native UI missing: copy §8 **Markdown table** (`/od y` · `/od ad` · `/od x`). **Forbidden**: prose-only menus, box-drawing, `||` frames, pad-aligned fake modals.

---

## 1.2 Sub-Agent Dispatch (`sub_agents`)

| Mode | Phase 3 |
|------|---------|
| **off** | Main agent serial — default for S/M |
| **auto** | Workers only if L/XL AND ≥3 independent tasks in group |
| **on** | 1 worker per independent task |

Workers: same branch, disjoint files, ≤30 line report. Pre-Dev + Change Impact: main agent only.

---

## 2. Impact Analysis

### 2.1 Pre-Development Scope — compact table format, max 15 file rows

### 2.2 Change Impact — use `git diff --stat`; max 15 file rows; prose ≤10 lines

---

## 3. DevSecOps

Unchanged — see stability level in `00-project-context.md`. Security checklist before task complete.

---

## 4. Greenfield vs Legacy & Unit Tests

| Type | Rule |
|------|------|
| **legacy** | Match existing test patterns; extend `*_test.go` / `*.test.ts` |
| **greenfield** | Scaffold tests per `05-test-plan.md`; Playwright if E2E required |

### 4.1 Unit Tests — MANDATORY During Phase 3

Every logic/backend/utility task **must** ship with **UNIT** tests before task `[x]`:

1. Map task → `05-test-plan.md` TC-F*-U* IDs
2. Create or update test file in same task group
3. Run quick UNIT for touched files (`npm test -- --findRelatedTests` / `go test ./pkg/...`)
4. Append to `03-progress.md`: `unit_tests: [TC-F1-U01, TC-F1-U02]`

Phase 4 UNIT gate expects these to exist — missing → Phase 4 Gap Backfill (test-strategy §5).

Frontend component tasks: UNIT via testing-library / vitest per repo convention.
