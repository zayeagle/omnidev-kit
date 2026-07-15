# Phase 2 Instructions (Detailed Design & Planning)
→ Platform mapping: SKILL.md §F (Platform Abstraction Layer)


## Context Requires

```yaml
context_requires:
  read:
    - 00-project-context.md
    - user-preferences.md
    - 01-blueprint.md                # skip if M-level; use session-log requirement
  scan:
    - src/{pages,views,app}/**/index.{ts,tsx,js,jsx,vue}
    - src/{routes,router,api}/*.{ts,js}
    - cmd/**/main.go, internal/{handler,controller,route}/**/*.go
  scan_limit: 8
  skip:
    - 03-progress.md, features/*.md, 05-test-report.md, 06-release-notes.md
    - "*-history.md"                 # COLD — load active only
  unload:
    - "Phase 0 instruction file full text"
    - "Phase 0 project scan raw returns"
  summarize_before_exit:
    target: 02-plan.md
    discard_after_write:
      - "source code scan raw returns"
    retain:
      - 04-design.md                 # index only in context
      - features/*.md                # on disk; lazy-load per task in Phase 3
      - 05-test-plan.md
      - 02-plan.md
```

## Overview

Phase 2 produces **in order**:

1. **`04-design.md`** — single file per `config.json` `design_split` (default `false`):
   - **`design_split: false`** (default): one `04-design.md` with `## Feature F1`, `## Feature F2`, … sections (≤40 lines each). Phase 3 loads one section via Grep.
   - **`design_split: true`**: index `04-design.md` (≤60 lines) + per-feature `features/FN.md` files.
2. **`05-test-plan.md`** — table-first compact format
3. **`02-plan.md`** — tasks with `feature_ref: FN` field

→ Token: [token-optimization.md](../engine/token-optimization.md) · Occupancy: [context-lifecycle.md](../engine/context-lifecycle.md) §3 Phase 2

**Document history**: Before overwriting any existing active artifact (`01-blueprint`, `02-plan`, `04-design`, `05-test-plan`), archive previous content to paired `*-history.md` per [document-history.md](../engine/document-history.md). First creation skips archive.

```yaml
context_occupancy:
  hot: ["current feature section being written"]
  warm: ["04-design.md (single file)", "or 04-design index when design_split: true"]
  cold: ["other feature sections", "scan raw"]
```

---

## Step 1: Design → Index + Feature Files

### `design_split: false` (default) — Single File

Write ONE `04-design.md` with per-feature sections:

```markdown
# Design

## Feature F1: [Name]
### Business Context
- **Related**: [existing features]
- **Impact**: [affected flows]

### Implementation Logic
1. Entry: [route] → validate → service → response
2. Core: [3-5 steps max]
3. Data: [model/query]

### Edge Cases
- Happy: [...] | Err1: [...] | Err2: [...] | Boundary: [...]

### Data Changes
| Entity | Change | Details |

## Feature F2: [Name]
...
```

**Quality checks**: each section ≤40 lines; total ≤200 lines. Every feature linked to existing code.

### `design_split: true` — Index + Per-Feature Files

1. Write **`04-design.md`** index only (≤60 lines) — feature table + cross-cutting notes
2. Write each **`features/FN.md`** (≤40 lines) — one file per feature. Use template below.

**Feature file template** (`features/F1.md`):

```markdown
# F1: [Feature Name]

## Business Context
- **Related**: [existing features]
- **Impact**: [affected flows]

## Implementation Logic
1. Entry: [route] → validate → service → response
2. Core: [3-5 steps max]
3. Data: [model/query]

## Edge Cases
- Happy: [...] | Err1: [...] | Err2: [...] | Boundary: [...]

## Data Changes
| Entity | Change | Details |
```

**Quality checks**: every feature linked to existing code; ≤40 lines each.

---

## Step 2: Test Plan → `05-test-plan.md` (Multi-Layer)

→ Full rules: [test-strategy.md](../engine/test-strategy.md) — auto-compose layers from complexity + project_type + fullstack signals.

**Phase 2 MUST**:
1. Compute `test_strategy_profile` and `layers_required` (§2 matrix)
2. Write frontmatter (profile, e2e_tool, e2e_required, integration_required)
3. Author **separate tables per layer** per feature: UNIT, INT (if required), E2E (if fullstack), SMK, REG

**Table format** (compact — [token-optimization.md](../engine/token-optimization.md) §4):

```markdown
---
test_strategy_profile: fullstack-M
layers_required: [unit, integration, e2e, smoke, regression]
e2e_tool: playwright
e2e_required: true
integration_required: true
---

## Test Strategy Summary
| Layer | Required | Tool | Command | TC Count |
| UNIT | ✅ | jest | npm test | 8 |
| INT | ✅ | supertest | npm run test:int | 4 |
| E2E | ✅ | playwright | npx playwright test e2e/ | 3 |

## F1 — UNIT
| TC-ID | Layer | Type | Target | Input | Expected | Mock |
| TC-F1-U01 | UNIT | Happy | ... | ... | 200 | none |

## F1 — INT
| TC-ID | Layer | Type | Target | Input | Expected | Mock |

## E2E Flows
| TC-ID | Layer | Flow | Steps | Expected |

## Smoke Suite
| TC-ID | Source-TC | Layer | Critical Path |

## Regression Suite
| TC-ID | Layer | Module | Package | Type |
```

Minimums when layer **required**:
- UNIT: 1 Happy + 2 error + 1 boundary per feature
- INT: 1 Happy + 1 cross-module failure
- E2E: 1 primary user journey (fullstack)
- SMK: top critical paths
- REG: Module-tagged entries for touched modules

Legacy: match existing test layout; Greenfield: scaffold Playwright if E2E required.

---

## Step 3: Task Plan → `02-plan.md`

Each task MUST include feature reference:

```markdown
- [ ] **T3** [backend] User service · feature: F1 · outputs: `service/user.go` · depends: T1
```

Traceability table: Task Group ↔ Features ↔ TC-IDs.

---

## Step 4: Checkpoint → Interactive → WAIT

Record token estimate in `metrics.json` if `log_token_estimates: true`.

### Handoff Checklist

- [ ] `04-design.md` index + all `features/FN.md` on disk
- [ ] `05-test-plan.md` has Test Strategy Summary + all **Required** layer tables
- [ ] `layers_required` matches test-strategy matrix (fullstack → E2E present)
- [ ] `02-plan.md` has `feature:` on every task
- [ ] Traceability complete
- [ ] Prior versions archived to `*-history.md` if this is a revision (not first run)

### Interactive gate (mandatory)

After checklist prose (≤12 lines), **same turn** invoke [interactive-prompt.md](../engine/interactive-prompt.md):

1. §3.7 `phase2_plan_ready` — confirm design/plan ready for development
2. Then §3.1 `checkpoint` (B.8) — next step `/od n`, etc.

Platform: §4 / §5 / §6; on failure → §8 Markdown table. **STOP — WAIT**. Workers must not show options UI.

---

## Sub-Agent Dispatch (per `sub_agents` config)

| Mode | Behavior |
|------|----------|
| **off** | Main agent writes all files serially |
| **auto** (default) | S/M: serial. L/XL + ≥5 features: 1 worker/feature for `features/*.md` only |
| **on** | 1 worker/feature for design + test tables; main agent merges |

Workers return ≤30 line summary. Main agent writes final files. Phase 2 NEVER loads worker raw outputs into context — merge from disk files only.
