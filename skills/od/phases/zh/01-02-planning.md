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
    - frontend entry files            # learn API client, router, state patterns
    - backend route/handler files     # existing API surface
  skip:
    - 03-progress.md, 04-design.md, 05-test-report.md, 06-release-notes.md
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