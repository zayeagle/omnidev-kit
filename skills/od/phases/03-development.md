# Phase 3 Instructions (Development & DevSecOps)

```yaml
context_requires:
  read:
    - 00-project-context.md
    - 02-plan.md
    - 03-progress.md                 # if exists
    - 04-design.md                   # INDEX ONLY — never load all features/
  read_on_demand:
    - features/{FN}.md               # ONE file matching current task's feature: field
  scan:
    - ONLY paths from current task `outputs` and `depends`
  scan_limit: 8                      # reduced from 10 for token savings
  reload: 02-plan.md
  skip:
    - 01-blueprint.md, 05-test-report.md, 06-release-notes.md
    - features/*.md                  # bulk load forbidden — use read_on_demand
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
→ Occupancy: [context-occupancy.md](../engine/context-occupancy.md) §3 Phase 3

```yaml
context_occupancy:
  hot_max: 150
  warm_max: 80
  hot: ["02-plan active Group", "features/{FN}.md", "current source files"]
  warm: ["04-design index", "03-progress snapshot"]
  cold: ["05-test-plan", "01-blueprint", "completed groups", "git diff full"]
  purge_on_task_complete: ["features/{FN}.md"]
  purge_on_group_complete: ["source file reads", "git diff stat summary retained in 03-progress"]
```

## 1. Execution Protocol

1. **Safety checkpoint**: Only if `auto_checkpoint: true` → `git stash`. Never auto-commit.
2. **Pre-Dev Scope** (B.15): Required per complexity. Keep output ≤25 lines for M.
3. **Load design**: Read `04-design.md` index → identify current task's `feature:` → Read **only** `features/FN.md`.
4. **Execute groups** from `02-plan.md`. Sub-agents per config (§1.2).
5. **After each task**: `[x]` in plan; archive progress; **unload** that feature's design file from context.
6. **git diff**: Always `--stat` first. Full diff only for active fix (±30 lines).
7. **Change Impact** (B.15): Per complexity tier.
8. Log token estimate + `metrics.json` on phase exit.

---

## 1.1 Confirmation Levels (B.15)

| Complexity | Pre-Dev | Per-Group Impact | Phase End |
|------------|---------|------------------|-----------|
| S | Skip | Skip | Skip |
| M | Once (≤25 lines) | Skip unless deviation | Required |
| L/XL | Required | Required | Required |

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

## 4. Greenfield vs Legacy

Unchanged. Legacy: match existing patterns. Greenfield: scaffold tests per compact test plan.
