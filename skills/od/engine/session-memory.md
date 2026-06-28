# Session Memory (会话记忆持久化)

## Overview

每次 `/od` 会话结束时，自动将关键上下文压缩为结构化摘要，持久化到文件。下次 `/od re` 恢复时读取，实现真正的跨会话"断点续传"。

## 1. Session Log 文件

**路径**: `docs/omnidev-state/[branch]/session-log.md`

**生命周期**: 一个分支只保留 **最近 1 份** session-log。新会话结束时覆盖旧的（旧的关键信息已沉淀到 state files 中）。

## 2. 写入触发

在以下时机自动生成/更新 `session-log.md`：

| 触发场景 | 动作 |
|---------|------|
| 用户输入 `/od x` 或选择"结束" | 生成完整 session-log |
| Q&A Loop 中用户长时间无响应（会话自然结束） | 下次 `/od re` 时基于上下文补写 |
| `/od st` (stash) | 生成 session-log 作为暂存的一部分 |
| Phase exit (every checkpoint) | Minimal snapshot: phase, group, feature, last decision. **No state file body copy.** |

## 3. Session Log 格式

```markdown
---
branch: feature/xxx
last_phase: 3
last_task_group: 2
timestamp: 2026-06-03T08:30:00+08:00
complexity: M
status: in_progress | completed | stashed
state_files: ["02-plan.md", "04-design.md", "03-progress.md"]
active_feature: F2
active_group: 2
context_hot: ["02-plan Group 2", "features/F2.md"]
---

## 会话目标
[1-2 句话，用户最初的需求描述]

## 关键决策
- **[决策点]**: 选择了 [方案A]，原因：[理由]
- **[决策点]**: 用户要求 [具体偏好]

## 执行进度
- Phase 0: ✅ 复杂度 M，推荐 Plan → Dev → Test
- Phase 1: ⏭️ 已跳过
- Phase 2: ✅ 计划已生成，共 8 个任务 / 3 组
- Phase 3: 🔄 进行中，Group 2/3 完成，Group 3 待执行
- Phase 4: ⏳ 未开始
- Phase 5: ⏳ 未开始（L/XL 部署阶段）

## 未完成项
- [ ] T6: 用户列表前端页面 (Group 3)
- [ ] T7: 集成测试 (Group 3)
- [ ] Phase 4 测试尚未执行

## 用户反馈要点
- 要求 API 返回格式统一用 `{code, data, message}`
- 偏好先完成后端再做前端
- 跳过了 Blueprint 阶段（认为 M 级别不需要）

## 恢复指引
下次继续时：读取 `02-plan.md` 从 Group 3 开始执行，注意 T6 依赖 T3 的 API 输出。
```

## 4. 写入规则

1. **极简原则**: session-log 控制在 **50 行以内**。只记录对"恢复执行"有价值的信息，不复制 state files 的内容。
2. **决策优先**: 重点记录"为什么这样做"而非"做了什么"——后者已在 state files 中。
3. **用户反馈必记**: 用户在会话中给出的口头偏好、修正、要求，即使未触发 evolution-log，也必须记录在 `## 用户反馈要点` 中。
4. **不阻塞退出**: 生成 session-log 是会话的最后一步，在输出关闭摘要的同时静默写入，不需要用户确认。

## 5. 读取场景

| 命令 | 行为 |
|------|------|
| `/od re` | **必读** `session-log.md`（如果存在）。用其中的 `last_phase`、`last_task_group` 定位恢复点，用 `## 关键决策` 和 `## 用户反馈要点` 恢复上下文。然后按正常流程加载对应 phase 的 `context_requires`。 |
| `/od` (新需求，同分支) | 检查是否存在未完成的 session-log（`status: in_progress`）。如果有，提醒用户："检测到未完成的任务，是否先恢复？"（AskQuestion）。 |
| `/od st` | session-log 随 stash 一起保存。 |
| `/od po` | session-log 随 stash 一起恢复。 |

---

## 6. Resume 操作流程 (`/od re`)

```yaml
context_requires:
  read:
    - docs/omnidev-state/config.json
    - session-log.md                 # YAML + 恢复指引 only
    - 02-plan.md                     # frontmatter + active group ONLY
    - 03-progress.md                 # blockers + snapshot ONLY
  read_on_demand:
    - 04-design.md                   # index only, if Phase 3/4
    - 00-project-context.md          # phase slice on first use
  skip:
    - 01-blueprint.md, 05-test-plan.md, features/*.md bulk
    - 05-test-report.md, 06-release-notes.md
    - conversation history replay
```

### Steps

1. **Read session-log.md** (if exists):
   - Extract `last_phase`, `last_task_group`, `status` from YAML frontmatter
   - Restore decision context from `## Key Decisions`
   - Restore user preference context from `## User Feedback`
   - Get resume guidance from `## Resume Instructions`

1.5. **Verify state file integrity**: Cross-check `state_files` manifest against disk. If any missing: report "⚠️ Session state incomplete. Missing: [files]. Recoverable: [yes/no]." Ask user.

2. **Read state files**: Load plan and progress per `context_requires`

3. **Locate resume point**:
   - If session-log exists: use `last_phase` + `last_task_group`
   - If missing: infer from `03-progress.md` and `02-plan.md` (first incomplete task)

4. **Report to user** and confirm:
   ```
   ♻️ Session Resumed
   Branch: [branch]
   Last progress: Phase [N] — [description]
   Remaining: [task list]
   ```
   Use AskQuestion (if interactive): Continue / Restart / Cancel

5. **Load phase instructions**: Based on resume point, load corresponding `phases/` file

6. **Check for unprocessed learning signals**: If `evolution-log.jsonl` has `processed: false` signals, append reminder.

## 7. Session Exit 操作流程 (`/od x`)

When user ends session (`/od x` or selects "End"):

1. **Generate session-log.md** (per §3-§4 rules):
   - Record current phase, progress, key decisions, user feedback
   - Mark status: `in_progress` (if tasks remain) or `completed`
   - Write to `docs/omnidev-state/[branch]/session-log.md`

2. **Update user-preferences.md** (if new preference signals detected this session)

3. **Output closing summary**:
   ```
   ✅ Session Complete
   Completed: [summary of completed tasks/phases]
   Remaining: [incomplete items, if any]
   Session memory saved. Use `/od re` to resume anytime.
   ```

4. **No next-step prompt** — `/od x` is a termination signal.

## 8. Minimal Resume (Cold Start — max 200 lines)

Per [context-occupancy.md](context-occupancy.md) §10:

1. session-log YAML + 恢复指引 only (≤20 lines) — skip body unless needed
2. Active phase instruction only
3. `02-plan.md` frontmatter + **active group section only**
4. `03-progress.md` `## Blockers` + `## State Snapshot` only
5. `04-design.md` index only (if Phase 3/4)
6. `00-project-context.md` — **defer** until first need; then load phase-specific slice

**Forbidden on resume**: replay conversation history, load 01-blueprint, load full 05-test-plan, load all features/.

Log `metrics.json` event `type: "resume_cold_start"`.
