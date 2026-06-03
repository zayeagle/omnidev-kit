# Phase 4 Instructions (Testing & Wrap-up)

```yaml
context_requires:
  read:
    - 00-project-context.md          # test conventions, topology
    - 02-plan.md                     # verify all tasks checked off
    - 03-progress.md                 # blockers (if exists)
  scan:
    - "{test,tests,__tests__,spec}/**/*.{test,spec}.{ts,tsx,js,jsx,go,py}"  # test files
    - "git diff --name-only HEAD~5"  # files modified in recent commits (Phase 3 output)
    - ".env*", "config/*.{yml,yaml,json,toml}"  # config files for connections
  scan_limit: 15                     # read at most 15 files from scan results
  defer:
    - evolution-log.jsonl            # only read at Phase 4 END (step 4-5), not at start
    - metrics.json                   # only read at Phase 4 END for reporting
  unload:                             # ✅ 可安全忽略的前序原始输出
    - "Phase 3 instruction file (03-development.md) full text"
    - "Phase 3 code edit tool outputs (StrReplace, Write raw returns)"
    - "Phase 3 git diff raw outputs"
    - "Phase 1-2 instruction and scan outputs (if still in context)"
  skip:
    - 01-blueprint.md, 04-design.md  # upstream phase instructions — already consumed
  summarize_before_exit:
    target: 05-test-report.md        # test results persist here
    discard_after_write:             # ✅ 原始工具输出，已提取到 test report
      - "test execution Shell outputs (raw test runner logs)"
      - "SAST/lint tool raw outputs"
      - "coverage report raw data"
    retain:                          # ❌ 不可卸载，会话结束和 learn 依赖
      - 05-test-report.md            # 会话结束时的最终交付物
      - 03-progress.md               # learn 可能需要回顾
      - 02-plan.md                   # verify task completion status
      - "Phase 3 Change Impact Summary (checkpoint output)"  # 用户参考
      - "test failures and their root causes"  # learn 需要
```

## 1. Mock Strategy

When a dependency's data source is not directly available, use mock data. Never skip testing.
- **Interface Mock**: `gomock`, `jest.mock`, `unittest.mock` (Unit tests).
- **In-Memory Fake**: SQLite for MySQL, in-memory map for Redis.
- **Container Stub**: `testcontainers` (Integration tests).
- **HTTP/gRPC Stub**: `wiremock`, `httptest`, `msw`.
- **MCP-Driven**: Use DB/Browser MCP if available.

## 2. Scenario Coverage

Cover: Happy path, Validation (bad input), Conflict (duplicate/concurrent), Dependency failure (timeout/503), Security (IDOR/SQLi).

## 3. System-Level Resilience Testing

- **Always run**: Network latency (inject delay), Dependency timeout (mock never responds), High concurrency (P99 < 200ms).
- **Conditionally run (L/XL or High stability)**: Memory pressure (large payload), Cascading failure (circuit breaker trips).

## 4. Test Execution & Reporting

1. Run SAST linters (`gosec`, `npm audit`).
2. Run tests with coverage (Gate: >= 90% statement/branch coverage).
3. Generate `05-test-report.md`.
4. Trigger `/od ln` (self-learning).
5. If `evolution-log.jsonl` has unprocessed signals, append: "🧬 发现 N 条学习信号。使用 `/od ln` 查看提案。"
6. Final summary → STOP.

**05-test-report.md Concise Format:**
```markdown
# Test Report
## 1. Dependency Topology
| Dependency | Type | Category | Test Strategy |
## 2. Mock Data Registry
| Mock ID | Target | Purpose | Data Shape |
## 3. Scenario Coverage Matrix
| # | Scenario | Input | Expected Output | Mock Used | Result | Duration |
## 4. System-Level Resilience Tests
| # | Fault Type | Target | Expected | Actual | Result |
## 5. Summary
- Coverage: [X]% (Gate: >= 90%)
- Performance: P99 = [X]ms
```