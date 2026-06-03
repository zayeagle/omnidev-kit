# Phase 1 & 2 Instructions

## Phase 1: Blueprint (recommended for L/XL)

```yaml
context_requires:
  read:
    - 00-project-context.md          # stack type, conventions, pitfall guide
  scan:
    - source directories relevant to the requirement
  skip:
    - 02-plan.md, 03-progress.md, 04-design.md, 05-test-report.md
```

1. Analyze requirements, edge cases, exception handling, UX.
2. Identify major work streams and their input/output boundaries.
3. Output to `docs/omnidev-state/[branch]/01-blueprint.md` with **Mermaid.js** diagrams.
4. Checkpoint → WAIT.

## Phase 2: Planning (recommended for M+)

```yaml
context_requires:
  read:
    - 00-project-context.md
    - 01-blueprint.md                # if Phase 1 ran
  scan:
    - src/{pages,views,app}/**/index.{ts,tsx,js,jsx,vue}  # frontend entry files (max 5)
    - src/{routes,router,api}/*.{ts,js}                    # frontend API client / router
    - cmd/**/main.go, internal/{handler,controller,route}/**/*.go  # Go backend routes
    - src/{routes,controllers,handlers}/*.{ts,js}          # Node backend routes
    - "**/routes.{py,rb}", "**/views.{py,rb}"              # Python/Ruby backend routes
  scan_limit: 8                      # read at most 8 files from scan results
  skip:
    - 03-progress.md, 04-design.md, 05-test-report.md, 06-release-notes.md
  unload:                             # ✅ 可安全忽略的前序原始输出
    - "Phase 0 instruction file (00-assessment.md) full text"
    - "Phase 0 project scan tool outputs (Read/Grep raw returns)"
  summarize_before_exit:
    target: 02-plan.md               # task decomposition persists here
    discard_after_write:             # ✅ 原始工具输出，已提取到 plan
      - "source code scan results (Read/Grep raw returns from this phase)"
    retain:                          # ❌ 不可卸载，后续 phase 依赖
      - 00-project-context.md        # Phase 3, 4 都需要
      - 02-plan.md                   # Phase 3, 4 都需要
      - 01-blueprint.md              # 仅 Phase 2 需要；Phase 3+ 可通过 02-plan.md 获取精华
      - "user decisions (phase selection, requirement clarifications)"
```

1. **Decompose** into atomic tasks (single clear deliverable).
2. **Frontend Impact Analysis** (if `fullstack` or `frontend-only`):
   - Auto-create frontend sync tasks for backend API/schema changes.
   - Tag with `[frontend]` and link via `depends` to the backend task.
   - If purely backend, explicitly note `前端影响: none`.
3. **Dependency Analysis**: Identify inputs, outputs, and `depends` (prerequisite task IDs).
4. **Parallel / Serial Grouping**:
   - Tasks with NO dependency edges belong to the same parallel group.
   - Groups execute in topological order.
5. Output structured plan to `docs/omnidev-state/[branch]/02-plan.md`.
6. Checkpoint → WAIT.

**02-plan.md Format:**
```markdown
---
total_tasks: N
parallel_groups: M
critical_path: [T1 → T3 → T5]
frontend_impact: yes | no
---
## Group 1 (parallel — no prerequisites)
- [ ] **T1** [backend] Create user model · outputs: `models/user.go`
- [ ] **T2** [backend] Design API doc · outputs: `docs/api.yaml`

## Group 2 (parallel — after Group 1)
- [ ] **T3** [backend] User CRUD service · depends: T1 · outputs: `service/user.go`
- [ ] **T4** [frontend] Update API client · depends: T2 · outputs: `src/api/user.ts`
```