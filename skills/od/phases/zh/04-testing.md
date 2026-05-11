# Phase 4 Instructions (Testing & Wrap-up)

```yaml
context_requires:
  read:
    - 00-project-context.md          # test conventions, topology
    - 02-plan.md                     # verify all tasks checked off
    - 03-progress.md                 # blockers
    - evolution-log.jsonl            # unprocessed signals
    - metrics.json
  scan:
    - test directories
    - files modified in Phase 3
    - config files for DB/MQ/API connections
  skip:
    - 01-blueprint.md, 04-design.md
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