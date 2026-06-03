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

## 3. Session Log 格式

```markdown
---
branch: feature/xxx
last_phase: 3
last_task_group: 2
timestamp: 2026-06-03T08:30:00+08:00
complexity: M
status: in_progress | completed | stashed
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
