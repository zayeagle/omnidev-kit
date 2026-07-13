# Phase 4 Instructions (Testing & Wrap-up)
→ Platform mapping: SKILL.md §F (Platform Abstraction Layer)
→ **Test strategy**: [test-strategy.md](../engine/test-strategy.md) — layer composition, gates, gap backfill


```yaml
context_requires:
  read:
    - 00-project-context.md          # project_type, test conventions, stack
    - 02-plan.md                     # frontend/backend tags, traceability
    - 03-progress.md                 # unit_tests_written if exists
    - 04-design.md                   # INDEX ONLY
    - 05-test-plan.md                # lazy: ONE layer+feature section at a time
  read_on_demand:
    - features/{FN}.md               # gap backfill G1, failure investigation
    - user-preferences.md            # test_framework override
  scan:
    - test files for current feature/layer only
    - playwright.config.*, e2e/**, cypress.config.*
    - package.json scripts (test, test:int, test:e2e)
    - "git diff --stat HEAD~5"
  scan_limit: 12
  defer:
    - evolution-log.jsonl
    - metrics.json
    - "*-history.md"
  unload:
    - "Phase 3 instruction file"
    - "Phase 2 instruction file"
    - "test runner raw logs after summary written"
    - "Playwright trace/video binary — path only in report"
```

→ Occupancy: [context-lifecycle.md](../engine/context-lifecycle.md) §3 Phase 4

```yaml
context_occupancy:
  hot: ["current layer test table", "active TC result row"]
  warm: ["Test Strategy Summary table", "smoke summary", "gate status"]
  cold: ["other layer tables", "coverage raw", "e2e traces", "full test logs"]
```

**Sub-agents**: Default **NEVER** — **exception**: E2E Playwright runner when `allow_e2e_sub_agent: true` and suite is large (test-strategy.md §8.3).

---

## Overview

Phase 4 is **not** "run a few smoke cases". Per [test-strategy.md](../engine/test-strategy.md), auto-compose and **enforce**:

| Layer | Default | Description |
|-------|---------|-------------|
| **UNIT** | ✅ Required, blocking | Should already be written in Phase 3; if missing → Gap Backfill |
| **INT** | Required for multi-module/API | supertest / testcontainers / existing repo patterns |
| **SYS** | L/XL multi-service | docker-compose + API suite |
| **E2E** | Required for fullstack | **Playwright** preferred; Browser MCP / E2E sub-agent optional |
| **SMK** | ✅ Required | Critical-path subset |
| **REG** | ✅ Targeted | Module tags; full suite allowed for L/XL release |

**Artifacts**: inline results into `05-test-plan.md` + `05-test-report.md` + metrics `test_complete`

---

## Step 0: Validate / Compose Test Strategy

1. Read `05-test-plan.md` frontmatter `layers_required` — if missing, **compose** from:
   - Phase 0: complexity, Frontend Impact, project_structure
   - `00-project-context.md`: project_type
   - `02-plan.md`: frontend+backend tasks
2. Cross-check [test-strategy.md](../engine/test-strategy.md) §2 matrix — **add missing layers** to plan (Gap G2) before execution
3. Output **Test Execution Plan** (≤15 lines):

   ```markdown
   ## Phase 4 Test Execution Plan
   Profile: fullstack-M | UNIT ✅ INT ✅ E2E ✅ SMK ✅ REG targeted
   E2E tool: playwright | Commands: [list]
   Blocking: UNIT + E2E (e2e_required)
   ```

4. If S-level with no `05-test-plan.md`: create **minimal plan** (UNIT + SMK for touched files only) — still mandatory UNIT

**Interactive gates** (mandatory when applicable) — [interactive-prompt.md](../engine/interactive-prompt.md):

| Trigger | decision_point |
|---------|----------------|
| Layer dispute / user wants to skip E2E (and `e2e_required`) | §3.9 `test_layers` (`skip_e2e` requires B.0 reason in session-log) |
| Disposition after UNIT/E2E Gate failure | §3.9 `test_gate_fail` |
| Gap Backfill path selection | §3.9 `gap_backfill` |
| Phase 4 end | §3.1 `checkpoint` |

Same turn §4/§5/§6; on failure → §8. **STOP — WAIT**. Do not use prose numbered options.

---

## Step 1: Unit Tests (UNIT) — BLOCKING GATE

**Mandatory**. Cannot complete Phase 4 with UNIT failures (unless user B.0 waives specific TC with reason logged).

1. Load ONE feature's **UNIT** table from `05-test-plan.md`
2. Scan repo for existing test files; match project conventions (legacy) or scaffold (greenfield)
3. If tests missing vs plan → **Gap Backfill** §Step 8 (G5: implement tests, link TC-IDs)
4. Run layer command:

   | Stack | Command |
   |-------|---------|
   | Node | `npm test -- --testPathPattern=<pattern> --silent` |
   | Go | `go test ./path/... -count=1` |
   | Python | `pytest path/ -q` |

5. Append inline results:

   ```markdown
   ## F1 — UNIT (executed)
   | TC-ID | Layer | Type | Result | Note |
   | TC-F1-U01 | UNIT | Happy | ✅ | 12ms |
   | TC-F1-U02 | UNIT | Input | ❌ | expected 400 got 500 |
   ```

6. Failed UNIT → diagnose → fix or Gap Backfill → **re-run** before proceeding

---

## Step 2: Integration Tests (INT)

**Skip only if** `integration_required: false` in plan frontmatter AND matrix agrees.

1. Load INT table per feature
2. Ensure test DB/MQ/env — if missing → Gap G3 (env/fixture)
3. Run: `npm run test:int` / `go test -tags=integration` / project-specific
4. Record inline; cross-module API contract failures → Gap G1 (update `features/FN.md`)

---

## Step 3: System Tests (SYS)

When `layers_required` includes `system`:

1. Start services via docker-compose or project script (B.0 if touches production-like env)
2. Run API/system suite from plan
3. Teardown; summary to report

---

## Step 4: Smoke Tests (SMK)

1. Execute `## Smoke Suite` TCs — subset of critical Happy paths
2. Must pass before E2E/REG if time-boxed; SMK fail → block unless B.0

---

## Step 5: E2E Tests — Playwright / MCP / Agent

**Trigger**: `e2e_required: true` OR fullstack matrix (test-strategy §2.4). **Cannot skip** for fullstack without B.0.

### 5.1 Discover & Prepare

1. Scan: `playwright.config.ts`, `e2e/`, `tests/e2e/`, `package.json` → `"@playwright/test"`
2. Legacy: use existing specs; extend for new flows
3. Greenfield: scaffold `e2e/[feature].spec.ts` if missing (align plan TC-E2E-*)
4. Start app: `npm run dev` / docker — document in plan `## Test Environment` if not exists (Gap G3)

### 5.2 Execute — Tool Priority

| Priority | Method |
|----------|--------|
| 1 | **Playwright CLI**: `npx playwright test [spec] --reporter=line` |
| 2 | **Browser MCP** / Playwright MCP (SKILL §F.6) — navigate, assert, screenshot to disk |
| 3 | **E2E Sub-agent** (if `allow_e2e_sub_agent` + large suite): Task / create_thread with Playwright-only scope |

### 5.3 Record

```markdown
## E2E Results
| TC-ID | Spec | Result | Evidence |
| TC-E2E-01 | e2e/login.spec.ts | ✅ | — |
| TC-E2E-02 | e2e/checkout.spec.ts | ❌ | screenshot: test-results/...png |
```

Load screenshot **path only** into context — not binary.

### 5.4 E2E Failure

- UI selector / timing → fix test or app
- API 4xx/5xx → may need INT fix or G1 design update
- Env missing → G3 backfill

---

## Step 6: Regression (REG)

1. Cross-reference modified **Module** tags from `02-plan.md` traceability
2. Run REG entries with matching Module only (default `regression_mode: targeted`)
3. Full regression: user request OR XL deploy OR no Module tags
4. Record in `05-test-plan.md` REG section + report

---

## Step 7: Resilience

Execute `Dep-Fail` / fault-injection TCs from plan (UNIT or INT layer with mocks). Record method in report.

---

## Step 8: Gap Backfill (spec backfill)

When any step blocked by missing spec/env/test/fixture:

1. Classify: G1 Design | G2 Plan | G3 Env | G4 Fixture | G5 Implementation ([test-strategy.md](../engine/test-strategy.md) §7)
2. **Interactive prompt**: backfill upstream docs / fill in now / skip (reason required)
3. Actions:
   - **G1**: Update `features/FN.md` or `04-design.md` index → archive if substantive
   - **G2**: Append layer table to `05-test-plan.md`
   - **G3/G4**: Add `## Test Environment` to plan; create `.env.test`, seed script (B.0)
   - **G5**: Fix code + add UNIT in Phase 4 if small scope; else log blocker for Phase 3 return
4. Re-run affected layer from failed TC
5. Log `test_gap_backfill` to metrics

**Forbidden**: Silently skipping Required layer citing "no spec" — must backfill or get B.0 waiver.

---

## Step 9: Coverage (Once)

Run project coverage command → **single summary line** in report ([metrics.md](../engine/metrics.md)).

If `coverage_gate: true` and below threshold → CONDITIONAL gate; B.0 for proceed.

---

## Step 10: Test Report → `05-test-report.md`

Archive previous to `05-test-report-history.md` if replacing ([document-history.md](../engine/document-history.md)).

**Required sections** (test-strategy §9):

```markdown
---
artifact: 05-test-report.md
gate_status: PASS | FAIL | CONDITIONAL
test_strategy_profile: fullstack-M
---

# Test Report

## 1. Executive Summary
| Layer | Pass | Fail | Skip | Blocking |
| UNIT | 12 | 0 | 0 | yes |
| INT | 4 | 0 | 0 | yes |
| E2E | 3 | 1 | 0 | yes |
| SMK | 5 | 0 | 0 | yes |
| REG | 8 | 0 | 0 | no |

## 2. Strategy Profile
[echo layers_required, e2e_tool]

## 3. Results by Layer
[tables — details in 05-test-plan inline]

## 4. Coverage
82.3% statements (jest)

## 5. E2E Evidence
- e2e/login.spec.ts ✅
- test-results/checkout-fail.png (path)

## 6. Gaps & Backfill
| Gap | Action | Status |
| G2 | Added INT table for F2 | resolved |

## 7. Blocking Issues
- TC-E2E-02 checkout flow — fix before deploy

## 8. Gate Status
**FAIL** — E2E TC-E2E-02; UNIT/INT pass
```

---

## Step 11: SAST, Learning, Checkpoint

- SAST if available in repo
- `/od ln` optional on repeated failures
- Log `test_complete` + `test_pass_rate` + layer counts to metrics
- Checkpoint: include **Gate Status**; if FAIL → offer `/od ad` (Phase 3/4) or fix loop

**Next**: Phase 5 (L/XL, gate PASS) / `/od ps` / Done

---

## Handoff Checklist

- [ ] Test Strategy Profile validated; all **Required** layers executed (not skipped)
- [ ] UNIT gate passed (or documented B.0 waiver)
- [ ] E2E executed when fullstack / `e2e_required`
- [ ] Gaps logged and resolved or waived
- [ ] `05-test-report.md` § Gate Status written
- [ ] Phase 5 entry: gate PASS or user CONFIRMED conditional

---

## Phase 4 Anti-Patterns

| ❌ | ✅ |
|----|-----|
| Only smoke, no UNIT | UNIT blocking first |
| Skip E2E on fullstack | Playwright/MCP E2E or B.0 waiver |
| Skip INT with 3+ modules | INT layer per matrix |
| "No spec" → skip | Gap Backfill G1/G2 |
| Paste Playwright trace into chat | Path in report only |
