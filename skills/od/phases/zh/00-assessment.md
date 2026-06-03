# Phase 0 & Onboard Instructions

## Context Requires
```yaml
context_requires:
  read:
    - 00-project-context.md          # cached stack info; may not exist
  scan:
    - package.json, go.mod, pom.xml  # only if 00-project-context.md missing
    - top-level directory listing     # quick ls for structure signals
  skip:
    - 01-blueprint.md, 02-plan.md, 03-progress.md, 04-design.md  # not yet created
  summarize_before_exit:
    target: 00-project-context.md    # stack detection results persist here
    discard_after_write:
      - "project scan tool outputs (package.json, go.mod reads, directory listings)"
    retain:
      - 00-project-context.md        # ❌ 后续所有 phase 都依赖，永不卸载
      - "user's complexity/phase selection decisions"  # ❌ 写入 session-log
  unload: []                         # Phase 0 is first phase, nothing to unload
```

## 1. Project Stack Detection (`/od onboard` or Phase 0 init)

Before sizing, scan the project once (results cached in `00-project-context.md` § Stack & Layers; re-scan only if missing):

1. **Frontend signals**: `package.json` (react, vue, next, etc.), `src/pages`, `vite.config.*`.
2. **Backend signals**: `go.mod`, `requirements.txt`, `pom.xml`, `package.json` (express, nestjs), `cmd/`, `internal/`.
3. **Classify**: `fullstack` | `frontend-only` | `backend-only` | `monorepo`.
4. **Dependency Topology Scan**:
   - Storage (DB, Cache, MQ, Search, S3): scan `config/*.yml`, `.env`, driver imports (`gorm`, `redis`, `kafka`).
   - Third-Party (HTTP APIs, gRPC, SDKs): scan `http.Client`, `axios`, `.proto`, AWS/Sentry SDKs.
5. **Stability Level**: `high` (if user requested high availability/stability) else `standard`.
6. Output to `docs/omnidev-state/00-project-context.md` (mark `project_type: legacy` or `greenfield`). Include `## Stack & Layers`, `## Dependency Topology`, and `## Stability Level`.

## 2. Phase 0: Complexity Assessment (T-Shirt Sizing)

- **S**: Skip blueprint/plan → Dev → Test directly.
- **M**: Skip blueprint → Plan → Dev → Test.
- **L/XL**: Full workflow: Blueprint → Plan → Dev → Test → Deploy.

**Output format:**
```markdown
## OmniDev Phase 0: 需求解析 & 复杂度评估
**需求解析**: [1-2 sentences]
**项目结构**: [fullstack | frontend-only | backend-only | monorepo] — frontend: [fw/none], backend: [fw/none]
**复杂度评估**: [S/M/L/XL] — [reason]
**稳定性级别**: [standard | high] — [reason]
**前端影响**: [yes — 需同步修改前端 | no — 纯后端变更 | n/a]
**推荐策略**: [phases]
```

**If `interactive_mode` is `true`**: Use `AskQuestion` to let the user confirm/adjust complexity and select phases to execute.

For **S tasks**: Do NOT generate state files. Resolve directly.