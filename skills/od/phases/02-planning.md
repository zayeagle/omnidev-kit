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

1. **`04-design.md`** (index) + **`features/FN.md`** (per feature) — when `design_split: true` (default)
2. **`05-test-plan.md`** — table-first compact format
3. **`02-plan.md`** — tasks with `feature_ref: FN` field

→ Token: [token-optimization.md](../engine/token-optimization.md) · Occupancy: [context-occupancy.md](../engine/context-occupancy.md) §3 Phase 2

```yaml
context_occupancy:
  hot: ["current feature template being written"]
  warm: ["04-design index"]
  cold: ["other features/*.md until merged", "scan raw"]
```

---

## Step 1: Design → Index + Feature Files

When `design_split: true` (default):

1. Write **`04-design.md`** index only (≤60 lines) — feature table + cross-cutting notes
2. Write each **`features/FN.md`** (≤40 lines) — one file per feature

When `design_split: false`: single `04-design.md` with `## Feature FN` sections; Phase 3 MUST lazy-load one section via Grep.

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

## Step 2: Test Plan → `05-test-plan.md` (Compact)

**Table-first** — one table per feature (see token-optimization.md §4):

```markdown
## F1 Tests
| TC-ID | Type | Input | Expected | Mock |
|-------|------|-------|----------|------|
| TC-F1-01 | Happy | ... | 200 | none |
| TC-F1-02 | Input | empty | 400 | none |
| TC-F1-03 | Dep-Fail | valid | 503 | DB timeout |
```

Coverage Matrix at top (summary table). REG entries require **Module** + **Package** (monorepo).

Minimums: 1 Happy + 2 errors + 1 dep-fail per feature.

---

## Step 3: Task Plan → `02-plan.md`

Each task MUST include feature reference:

```markdown
- [ ] **T3** [backend] User service · feature: F1 · outputs: `service/user.go` · depends: T1
```

Traceability table: Task Group ↔ Features ↔ TC-IDs.

---

## Step 4: Checkpoint → WAIT

Record token estimate in `metrics.json` if `log_token_estimates: true`.

### Handoff Checklist

- [ ] `04-design.md` index + all `features/FN.md` on disk
- [ ] `05-test-plan.md` uses table format
- [ ] `02-plan.md` has `feature:` on every task
- [ ] Traceability complete

---

## Sub-Agent Dispatch (per `sub_agents` config)

| Mode | Behavior |
|------|----------|
| **off** | Main agent writes all files serially |
| **auto** (default) | S/M: serial. L/XL + ≥5 features: 1 worker/feature for `features/*.md` only |
| **on** | 1 worker/feature for design + test tables; main agent merges |

Workers return ≤30 line summary. Main agent writes final files. Phase 2 NEVER loads worker raw outputs into context — merge from disk files only.
