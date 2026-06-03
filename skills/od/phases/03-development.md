# Phase 3 Instructions (Development & DevSecOps)

```yaml
context_requires:
  read:
    - 00-project-context.md          # conventions, pitfall guide, stability_level
    - 02-plan.md                     # task groups, dependencies
    - 03-progress.md                 # resume point (if exists)
    - 04-design.md                   # architectural constraints (if exists)
  scan:
    - ONLY the exact file paths listed in current group's task `outputs` and `depends` fields
    - DO NOT scan directories broadly; read individual files by path from 02-plan.md
  scan_limit: 10                     # read at most 10 files per task group
  reload: 02-plan.md                 # re-read after each group completes
  skip:
    - 01-blueprint.md               # Phase 1 instruction — already consumed, discard
    - 05-test-report.md, 06-release-notes.md  # downstream artifacts — not yet created
  unload:                             # ✅ 可安全忽略的前序原始输出
    - "Phase 1-2 instruction file (01-02-planning.md) full text"
    - "Phase 1-2 source code scan raw returns (Read/Grep outputs)"
    - "01-blueprint.md full text"    # Phase 2 已提取精华到 02-plan.md
  summarize_before_exit:
    target: 03-progress.md           # dev progress persists here
    discard_after_write:             # ✅ 原始工具输出，已反映在代码和 state file 中
      - "per-task code edit tool outputs (StrReplace, Write raw returns)"
      - "git diff raw outputs from completed task groups"
      - "intermediate Shell outputs (lint, build logs)"
    retain:                          # ❌ 不可卸载，Phase 4 依赖
      - 00-project-context.md        # Phase 4 需要 test conventions, topology
      - 02-plan.md                   # Phase 4 需要 verify all tasks checked off
      - 03-progress.md               # Phase 4 需要 blockers
      - "Change Impact Summary"      # Phase 3 checkpoint 输出，Phase 4 和用户需要参考
      - "user feedback during dev"   # 写入 session-log
```

## 1. Execution Protocol

1. Auto-checkpoint: `git commit -m "chore: auto-checkpoint before omnidev task"`.
2. **Execute by group order** from `02-plan.md`. Dispatch independent tasks in parallel via `Task` tool if possible.
3. **Frontend sync**: Follow existing conventions (API client wrapper, state management, naming style).
4. **Aggressive Pruning**: Keep ONLY the last 3 active tasks in `03-progress.md` `## State Snapshot`. When a task completes, mark `[x]` in `02-plan.md` and immediately remove its details from `03-progress.md` to save tokens.
5. **Change Impact Summary**: After completing each task group, output a structured impact summary (see §2 below).
6. Checkpoint → WAIT.

## 2. Change Impact Summary (修改影响总结)

**Trigger**: Automatically after each task group completes AND before the Phase 3 checkpoint.

**Steps**:
1. Run `git diff --stat HEAD` to collect all changed files since the last checkpoint.
2. Categorize each file by operation type and functional module.
3. Analyze which features, APIs, pages, or services are affected by the changes.
4. Check for dependency changes (`package.json`, `requirements.txt`, `go.mod`, etc.).
5. Check for configuration or environment changes (`.env`, config files, migration scripts).

**Output format** (display to user):

```
📋 **修改影响总结 (Change Impact Summary)**

### 文件变更
| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 🆕 新增 | src/services/auth.ts | 认证服务模块 |
| 📝 修改 | src/routes/user.ts | 新增登录接口 |
| 📝 修改 | src/models/user.ts | 增加 token 字段 |
| 🗑️ 删除 | src/utils/old-auth.ts | 废弃旧认证逻辑 |

### 功能影响
- **[模块名]**: [具体影响描述]
- **[模块名]**: [具体影响描述]
- **前端影响**: [需同步修改 / 无影响]

### 依赖与配置变更
- **新增依赖**: [列出新增的包及版本，若无则标注"无"]
- **环境变量**: [列出新增/修改的 .env 变量，若无则标注"无"]
- **数据库迁移**: [列出迁移脚本，若无则标注"无"]
```

**Rules**:
- Keep the summary concise — no more than 20 file entries. If more, group by directory with counts.
- Functional impact analysis must map files to business features, not just list paths.
- If no dependency/config changes exist, still show the section with "无" to confirm nothing was missed.
- This summary is for **user awareness only** — it does not block the workflow and requires no confirmation.

## 3. DevSecOps & Resilience Requirements

Every interface must handle system-level failures and prevent vulnerabilities. Depth depends on `Stability Level` (`standard` or `high`).

**Security by Design (Mandatory for ALL levels):**
- Prevent IDOR/BOLA: `resource.owner_id == current_user.id`.
- Prevent Injection: Parameterized queries/ORM.
- Prevent SSRF/CSRF: Whitelist URLs, anti-CSRF tokens.
- Protect Sensitive Data: Hash passwords, mask PII in logs.

**Standard Level (Default):**
1. **Structured Errors**: Consistent JSON `{code, message, details}`. No raw stack traces.
2. **Timeout Control**: Explicit timeouts on ALL outbound calls (DB 5s, HTTP 10s).
3. **Graceful Failure**: Return 502/503/504 on dependency failure. Do not crash.
4. **Input Validation**: Validate/sanitize at the API boundary.

**High Level (User-requested additions):**
5. **Circuit Breaker**: Trip on high failure rate (e.g., `gobreaker`, `opossum`).
6. **Retry with Backoff**: Max 3 retries with exponential backoff + jitter for idempotent ops.
7. **Bulkhead Isolation**: Isolate connection/thread pools.
8. **Graceful Degradation**: Return degraded response for non-critical dependency failures.
9. **Rate Limiting**: Prevent resource exhaustion.

**Implementation Checklist (Verify before task completion):**
- [ ] Resource ownership verified (IDOR)
- [ ] SQL/NoSQL injection prevented
- [ ] Sensitive data masked
- [ ] Explicit timeouts on outbound calls
- [ ] Structured JSON errors
- [ ] (High only) Circuit breaker & Retry implemented