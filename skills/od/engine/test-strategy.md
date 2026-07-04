# Test Strategy Engine (测试策略引擎)

**Principle**: 必要测试 **不可缺少**。单元测试 **强制**；其余层级按 **复杂度 × 项目形态 × 架构信号** 自动组合。Phase 4 执行前必须产出/校验 `Test Strategy Profile`；执行中若发现规范缺口，触发 **Gap Backfill** 回补上游文档。

→ Phase 4 execution: [../phases/04-testing.md](../phases/04-testing.md)
→ Test plan authoring: [../phases/02-planning.md](../phases/02-planning.md) Step 2

---

## 1. Test Layers (定义)

| Layer | Code | 含义 | 典型工具 |
|-------|------|------|----------|
| **Unit** | `UNIT` | 单函数/类/组件，mock 外部依赖 | jest/vitest, go test, pytest, JUnit |
| **Integration** | `INT` | 多模块/多接口/DB/消息队列协作 | supertest, testcontainers, `@SpringBootTest` |
| **System** | `SYS` | 完整服务链或子系统，近生产配置 | docker-compose up + API suite |
| **E2E** | `E2E` | 浏览器/客户端 + 后端全链路 | **Playwright** (default), Cypress, Browser MCP |
| **Smoke** | `SMK` | 部署/构建后关键路径快速验证 | 精选 Happy path TC 子集 |
| **Regression** | `REG` | 受影响模块历史用例 | 按 Module/Package 标签定向 |

**Mandatory floor**: 每个需求至少 **UNIT + SMK**。其余按 §2 矩阵追加，**不得省略矩阵标记为 Required 的层**。

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
| **S** | ✅ 必做 | 多模块时 ✅ | ❌ | 全栈改动时 ✅ | ✅ | 最小（当前 feature） |
| **M** | ✅ 必做 | ≥2 模块/API 边界 ✅ | 可选 | 全栈 ✅ | ✅ | 定向 REG |
| **L** | ✅ 必做 | ✅ | 多服务 ✅ | 全栈 ✅ | ✅ | 定向 + 关键路径 |
| **XL** | ✅ 必做 | ✅ | ✅ | 全栈 ✅ | ✅ | 定向；发布前全量 REG |

### 2.2 By Project Type

| Signal | Adjustment |
|--------|------------|
| **legacy** | 沿用仓库已有 test runner/framework；不引入新栈除非 B.0 确认；E2E 用已有 Playwright/Cypress 配置 |
| **greenfield** | 无则 scaffold UNIT +（全栈时）Playwright E2E；CI 测试 job 写入 plan |
| **monorepo** | REG/INT 按 `[pkg:name]` 标签；每 package 独立 UNIT 命令 |
| **backend-only** | 无 E2E；INT 覆盖 API + DB |
| **frontend-only** | UNIT (组件) + 可选 E2E (路由)；无 INT 除非 BFF |
| **fullstack** | **E2E 强制**（Frontend Impact = yes 或 plan 含 frontend+backend tasks） |

### 2.3 Integration Triggers (INT 必做条件 — 满足任一)

- ≥2 独立模块/包参与同一 feature
- HTTP/gRPC/MQ 跨服务调用
- 共享 DB / cache 读写链
- Phase 3 改动了 API contract + consumer

### 2.4 E2E Triggers (E2E 必做条件 — 满足任一)

- `Frontend Impact: yes` 且存在 backend API 变更
- `02-plan.md` 同时含 `[frontend]` 与 `[backend]` 任务
- 用户流程跨页面 + API（登录、表单提交、列表刷新等）
- L/XL 且 `project_structure: fullstack`

### 2.5 E2E Tool Priority

1. **Playwright** — default (`npx playwright test`, `playwright.config.*`)
2. **Existing in repo** — Cypress, Puppeteer (legacy 优先匹配)
3. **Browser MCP** — Cursor/Claude MCP 可用时辅助截图/交互
4. **Playwright MCP** — 若已配置
5. **Sub-agent E2E runner** — Phase 4 唯一允许的并行例外：隔离 Playwright 长输出（见 04-testing.md §6）

Scan `package.json`, `playwright.config.*`, `e2e/`, `tests/e2e/` before choosing.

---

## 3. Test Strategy Profile (写入 `05-test-plan.md` frontmatter)

Phase 2 **必须**生成；Phase 4 **入口校验** — 缺层则补 plan 或 Block。

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

**Mandatory**: Phase 3 每个 backend/逻辑任务完成时，必须存在对应 **UNIT** 测试（新增或更新），与 `05-test-plan.md` TC-ID 对应。

| project_type | Rule |
|--------------|------|
| legacy | 扩展已有 `*_test.go` / `*.test.ts` 模式 |
| greenfield | 与实现同 PR 批次写入测试文件 |

Phase 3 checkpoint 附加项：`unit_tests_written: [TC-F1-U01, ...]` 写入 `03-progress.md`。

Phase 4 **不得** 以「未写测试」为由跳过 UNIT — 若缺失，Phase 4 Step 0 触发 Gap Backfill → Phase 3 补测或当场补写（B.0 确认范围）。

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

**Gate rule**: UNIT 失败 → **阻塞** Phase 4 完成与 Phase 5 入口。E2E 失败且 `e2e_required: true` → 阻塞，除非用户 B.0 确认降级。

---

## 7. Gap Backfill (测试依赖缺口回补)

测试执行中发现缺口时 **不得静默跳过**：

| Gap Type | Symptom | Action |
|----------|---------|--------|
| **G1 Design** | API 契约/字段不明 | 更新 `features/FN.md` + archive；`/od ad` Phase 2 或 inline 同步 |
| **G2 Test plan** | 缺 TC/层 | 追加 `05-test-plan.md` 对应层表格；不覆盖 history |
| **G3 Env** | 缺 `.env.test`、docker | 写入 plan `## Test Environment`；B.0 确认后创建 |
| **G4 Fixture** | 缺 seed data | Database MCP / script；记录于 report |
| **G5 Implementation** | 代码 bug | 修复 → 重跑失败 TC；重大变更走 Change Impact |

**Protocol**:
1. 记录 gap 到 `05-test-report.md` § Gaps
2. 若 G1/G2：interactive prompt — 回补文档 / 继续跳过(需明确理由) / 取消
3. 回补完成后 **从失败层重跑**，更新 inline 结果
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

Worker returns ≤30 line summary. Main agent merges to `05-test-report.md`. **Only for E2E** — UNIT/INT 主 agent 串行。

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

| Key | Default | 说明 |
|-----|---------|------|
| `e2e_tool` | `"playwright"` | playwright / cypress / browser_mcp / auto |
| `e2e_required_fullstack` | `true` | 全栈时强制 E2E |
| `unit_gate_blocking` | `true` | UNIT 全过才完成 Phase 4 |
| `regression_mode` | `"targeted"` | targeted / full |
| `allow_e2e_sub_agent` | `true` | Phase 4 E2E 隔离 runner |
| `coverage_gate` | `false` | true 时覆盖率未达标阻塞 |

---

## 11. Integration Points

- Phase 0: output `test_strategy_hint` in assessment block
- Phase 2: author full `05-test-plan.md` per §4
- Phase 3: UNIT tests with implementation
- Phase 4: execute §6
- Phase 5: entry gate reads report § Gate Status
- `/od ch`: re-evaluate matrix; regen test layers if structural
