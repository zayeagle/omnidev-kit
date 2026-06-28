# Phase 4 Instructions (Testing & Wrap-up)

```yaml
context_requires:
  read:
    - 00-project-context.md
    - 02-plan.md
    - 03-progress.md                 # if exists
    - 04-design.md                   # INDEX ONLY
    - 05-test-plan.md                # lazy: ONE feature test table at a time
  read_on_demand:
    - features/{FN}.md               # only when investigating failure
  scan:
    - test files for current feature only
    - "git diff --stat HEAD~5"       # stat only, not full diff
  scan_limit: 10                     # reduced from 15
  defer:
    - evolution-log.jsonl
    - metrics.json
  unload:
    - "Phase 3 instruction file"
    - "Phase 2 instruction file"
    - "test runner raw logs after summary written"
```

→ Occupancy: [context-occupancy.md](../engine/context-occupancy.md) §3 Phase 4

```yaml
context_occupancy:
  hot: ["current feature test table", "active TC result"]
  warm: ["smoke summary table", "02-plan traceability row"]
  cold: ["other feature tests", "coverage raw", "test logs"]
```

**Sub-agents**: NEVER in Phase 4.

---

## Overview

1. Smoke — current requirement features only
2. Regression — **targeted** by Module tag (default if 10+ REG)
3. Resilience — primary or alternative mocks
4. Coverage — **once**, summary line only in report
5. `05-test-report.md` + metrics update

---

## Step 1–2: Smoke Test

Load ONE feature's test table from `05-test-plan.md` at a time. Execute → append result inline:

```markdown
| TC-F1-01 | Happy | ✅ | 45ms |
| TC-F1-02 | Input | ❌ | see note |
```

Failed cases: add 1-line note; do NOT paste full stack trace into plan.

---

## Step 3: Regression (Targeted Default)

1. Cross-reference modified modules from `02-plan.md` traceability
2. Run REG entries with matching **Module** tag only
3. Full regression: user request OR no Module tags OR release/L/XL deploy

---

## Step 4: Resilience

Primary fault injection OR alternative unit mocks (see prior Phase 4 §4). Record method in report.

---

## Step 5: Coverage (Once)

Run project coverage command → extract **single summary line** (e.g. `82.3% statements`). Do NOT load coverage JSON/HTML into context.

---

## Step 6: Test Report → `05-test-report.md`

Summary tables only — details stay in `05-test-plan.md`.

---

## Step 7–8: Sync, Learning, Checkpoint

SAST if available. `/od ln` optional. Log `test_complete` + token estimate to metrics.

Next: Phase 5 (L/XL) / `/od ps` / Done.
