# Test Strategy Engine

**Principle**: Required tests **must not be omitted**. Unit tests are **mandatory**; other layers are auto-composed from **complexity × project shape × architecture signals**. Before Phase 4 execution, produce/validate a `Test Strategy Profile`; if a spec gap is found during execution, trigger **Gap Backfill** to update upstream docs.

→ Phase 4 execution: [../phases/04-testing.md](../phases/04-testing.md)
→ Test plan authoring: [../phases/02-planning.md](../phases/02-planning.md) Step 2

---

## 1. Test Layers (Definitions)

| Layer | Code | Meaning | Typical tools |
|-------|------|---------|---------------|
| **Unit** | `UNIT` | Single function/class/component; mock external deps | jest/vitest, go test, pytest, JUnit |
| **Integration** | `INT` | Multi-module / multi-API / DB / MQ collaboration | supertest, testcontainers, `@SpringBootTest` |
| **System** | `SYS` | Full service chain or subsystem, near-prod config | docker-compose up + API suite |
| **E2E** | `E2E` | Browser/client + backend full path | **Playwright** (default), Cypress, Browser MCP |
| **Smoke** | `SMK` | Fast critical-path check after build/deploy | Curated Happy-path TC subset |
| **Regression** | `REG` | Historical cases for affected modules | Targeted by Module/Package tags |

**Mandatory floor**: Every requirement at least **UNIT + SMK**. Append other layers per §2 matrix; **do not omit layers marked Required**.

---

## 2. Auto-Composition Matrix

Read signals from:
- `session-log.md` / Phase 0: `complexity`, `Frontend Impact`, `project_structure`
- `00-project-context.md`: `project_type` (legacy|greenfield), stack, existing test conventions
- `02-plan.md`: task groups, `[frontend]`/`[backend]` tags, module count
- `04-design.md`: feature count, cross-feature dependencies, API boundaries

### 2.1 By Complexity

| Complexity | UNIT | INT | SYS | E2E | SMK | REG |
|------------|:----:|:---:|:---:|:---:|:---:|:---:|
| **S** | ✅ Required | ✅ when multi-module | ❌ | ✅ when fullstack change | ✅ | Minimal (current feature) |
| **M** | ✅ Required | ✅ when ≥2 modules/API boundaries | Optional | ✅ fullstack | ✅ | Targeted REG |
| **L** | ✅ Required | ✅ | ✅ multi-service | ✅ fullstack | ✅ | Targeted + critical paths |
| **XL** | ✅ Required | ✅ | ✅ | ✅ fullstack | ✅ | Targeted; full REG before release |

### 2.2 By Project Type

| Signal | Adjustment |
|--------|------------|
| **legacy** | Reuse existing test runner/framework; do not introduce a new stack unless B.0 confirms; E2E uses existing Playwright/Cypress config |
| **greenfield** | If missing, scaffold UNIT + (fullstack) Playwright E2E; write CI test job into plan |
| **monorepo** | REG/INT by `[pkg:name]` tags; independent UNIT command per package |
| **backend-only** | No E2E; INT covers API + DB |
| **frontend-only** | UNIT (components) + optional E2E (routes); no INT unless BFF |
| **fullstack** | **E2E mandatory** (`Frontend Impact = yes` or plan has frontend+backend tasks) |

### 2.3 Integration Triggers (INT required if any)

- ≥2 independent modules/packages in the same feature
- HTTP/gRPC/MQ cross-service calls
- Shared DB / cache read-write chain
- Phase 3 changed API contract + consumer

### 2.4 E2E Triggers (E2E required if any)

- `Frontend Impact: yes` and backend API changes exist
- `02-plan.md` has both `[frontend]` and `[backend]` tasks
- User flow spans pages + API (login, form submit, list refresh, etc.)
- L/XL and `project_structure: fullstack`

### 2.5 E2E Tool Priority

1. **Playwright** — default (`npx playwright test`, `playwright.config.*`)
2. **Existing in repo** — Cypress, Puppeteer (prefer legacy match)
3. **Browser MCP** — assist screenshots/interaction when Cursor/Claude MCP available
4. **Playwright MCP** — if configured
5. **Sub-agent E2E runner** — Phase 4 only allowed parallel exception: isolate long Playwright output (see 04-testing.md §6)

Scan `package.json`, `playwright.config.*`, `e2e/`, `tests/e2e/` before choosing.

---

## 3. Test Strategy Profile (Write to `05-test-plan.md` frontmatter)

Phase 2 **must** generate; Phase 4 **entry validates** — missing layers → backfill plan or Block.

```yaml
---
artifact: 05-test-plan.md
test_strategy_profile: fullstack-M          # {structure}-{complexity}
layers_required: [unit, integration, e2e, smoke, regression]
layers_optional: [system]
e2e_tool: playwright                        # playwright | cypress | browser_mcp | none
e2e_required: true
integration_required: true
unit_gate: blocking                         # always blocking
regression_mode: targeted                   # targeted | full
project_type: legacy
frontend_impact: yes
---
```

### 3.1 Profile Examples

| Profile | layers_required |
|---------|-----------------|
| `backend-only-S` | unit, smoke, regression |
| `fullstack-M` | unit, integration, e2e, smoke, regression |
| `frontend-only-M` | unit, e2e, smoke, regression |
| `fullstack-XL` | unit, integration, system, e2e, smoke, regression |

---

## 4. `05-test-plan.md` Structure (Phase 2)

```markdown
## Test Strategy Summary

| Layer | Required | Tool | Command / Path | TC Count |
|-------|:--------:|------|----------------|----------|
| UNIT | ✅ | jest | `npm test -- --testPathPattern=F1` | 8 |
| INT | ✅ | supertest | `npm run test:int` | 4 |
| E2E | ✅ | playwright | `npx playwright test e2e/login` | 3 |
| SMK | ✅ | — | subset of above | 5 |
| REG | ✅ | jest | Module: auth | 12 |

## Traceability
| Feature | Task IDs | UNIT | INT | E2E | SMK |
|---------|----------|------|-----|-----|-----|

## F1 — UNIT
| TC-ID | Layer | Type | Target | Input | Expected | Mock |
| TC-F1-U01 | UNIT | Happy | UserService.create | valid | 201 | none |

## F1 — INT
| TC-ID | Layer | Type | Target | Input | Expected | Mock |
| TC-F1-I01 | INT | API | POST /api/users | valid body | 201 + row in DB | test DB |

## E2E Flows
| TC-ID | Layer | Flow | Steps (short) | Expected |
| TC-E2E-01 | E2E | Login | open /login → fill → submit | dashboard |

## Smoke Suite
| TC-ID | Source-TC | Layer | Critical Path |
| TC-SMK-01 | TC-E2E-01 | E2E | Login happy path |

## Regression Suite
| TC-ID | Layer | Module | Package | Type |
| TC-REG-auth-01 | REG | auth | web | UNIT |
```

**TC-ID convention**:
- UNIT: `TC-F{n}-U{nn}`
- INT: `TC-F{n}-I{nn}`
- E2E: `TC-E2E-{nn}` or `TC-F{n}-E{nn}`
- SMK: `TC-SMK-{nn}`
- REG: `TC-REG-{module}-{nn}`

Minimum per feature (when layer required):
- UNIT: 1 Happy + 2 error + 1 boundary
- INT: 1 Happy + 1 cross-module failure
- E2E: 1 primary user journey

---

## 5. Phase 3 — Unit Tests During Development

**Mandatory**: When each backend/logic task completes in Phase 3, corresponding **UNIT** tests must exist (new or updated), mapped to `05-test-plan.md` TC-IDs.

| project_type | Rule |
|--------------|------|
| legacy | Extend existing `*_test.go` / `*.test.ts` patterns |
| greenfield | Write test files in the same PR batch as implementation |

Phase 3 checkpoint add-on: write `unit_tests_written: [TC-F1-U01, ...]` to `03-progress.md`.

Phase 4 **must not** skip UNIT because "tests were not written" — if missing, Phase 4 Step 0 triggers Gap Backfill → Phase 3 backfill or write on the spot (B.0 confirms scope).

---

## 6. Phase 4 Execution Order

```
0. Validate Test Strategy Profile (compose if S-level minimal plan missing)
1. UNIT      — blocking gate; all Required UNIT must pass
2. INT       — if integration_required
3. SYS       — if layers includes system
4. SMK       — fast critical path
5. E2E       — if e2e_required; Playwright/MCP/sub-agent runner
6. REG       — targeted by Module; full if L/XL deploy or user request
7. Resilience — fault injection / dep-fail TCs
8. Coverage  — once, summary line
9. Report    — 05-test-report.md
```

**Gate rule**: UNIT failure → **blocks** Phase 4 completion and Phase 5 entry. E2E failure with `e2e_required: true` → blocks unless user B.0 confirms downgrade.

---

## 7. Gap Backfill (Test Dependency Gap Repair)

When a gap is found during test execution, **do not silently skip**:

| Gap Type | Symptom | Action |
|----------|---------|--------|
| **G1 Design** | API contract/fields unclear | Update `features/FN.md` + archive; `/od ad` Phase 2 or inline sync |
| **G2 Test plan** | Missing TC/layer | Append corresponding layer tables in `05-test-plan.md`; do not overwrite history |
| **G3 Env** | Missing `.env.test`, docker | Write plan `## Test Environment`; create after B.0 confirm |
| **G4 Fixture** | Missing seed data | Database MCP / script; record in report |
| **G5 Implementation** | Code bug | Fix → re-run failed TC; major changes use Change Impact |

**Protocol**:
1. Log gap to `05-test-report.md` § Gaps
2. If G1/G2: interactive prompt — backfill docs / continue skip (needs explicit reason) / cancel
3. After backfill, **re-run from the failed layer**; update inline results
4. metrics event: `test_gap_backfill`

---

## 8. E2E Execution (Playwright + MCP + Optional Agent)

### 8.1 Playwright (default)

```bash
# discover
npx playwright test --list
# run scoped
npx playwright test e2e/[flow].spec.ts --reporter=line
```

Record: pass/fail + screenshot path on failure (do not load image into context).

### 8.2 MCP Browser

When Browser MCP / Playwright MCP configured (SKILL §F.6):
- Navigate → interact → assert DOM/network
- Summarize ≤5 lines to report; screenshot to disk

### 8.3 Sub-Agent E2E Runner (Phase 4 exception)

When E2E suite >3 specs OR raw output >100 lines:
- **Cursor**: spawn worker with Playwright instructions only
- **Claude Code**: `Task` with readonly=false, Playwright scope
- **Codex**: `create_thread` + `send_message_to_thread`

Worker returns ≤30 line summary. Main agent merges to `05-test-report.md`. **Only for E2E** — UNIT/INT run serially on the main agent.

---

## 9. `05-test-report.md` Required Sections

1. **Executive Summary** — pass/fail counts by layer
2. **Strategy Profile** — echo frontmatter
3. **Results by Layer** — table per layer
4. **Coverage** — one line
5. **E2E Evidence** — spec paths, screenshot refs
6. **Gaps & Backfill** — G1–G5 log
7. **Blocking Issues** — must fix before deploy
8. **Gate Status** — PASS / FAIL / CONDITIONAL

---

## 10. Config (`config.json`)

| Key | Default | Description |
|-----|---------|-------------|
| `e2e_tool` | `"playwright"` | playwright / cypress / browser_mcp / auto |
| `e2e_required_fullstack` | `true` | Force E2E for fullstack |
| `unit_gate_blocking` | `true` | Phase 4 completes only when all UNIT pass |
| `regression_mode` | `"targeted"` | targeted / full |
| `allow_e2e_sub_agent` | `true` | Phase 4 E2E isolated runner |
| `coverage_gate` | `false` | When true, block if coverage below gate |

---

## 11. Integration Points

- Phase 0: output `test_strategy_hint` in assessment block
- Phase 2: author full `05-test-plan.md` per §4
- Phase 3: UNIT tests with implementation
- Phase 4: execute §6
- Phase 5: entry gate reads report § Gate Status
- `/od ch`: re-evaluate matrix; regen test layers if structural
