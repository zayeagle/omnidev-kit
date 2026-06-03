# Stash & Pop (任务上下文暂存/恢复)

## Overview

当用户需要临时切换到另一个任务（如紧急 hotfix）时，`/od st` 将当前工作上下文完整快照保存，`/od po` 在切回时恢复，实现多任务无缝切换。

## 1. 存储结构

**路径**: `docs/omnidev-state/stash/`

```
docs/omnidev-state/stash/
├── stash-index.json          # 暂存索引（所有暂存条目）
├── <id>/                     # 每个暂存一个子目录
│   ├── snapshot.json         # 暂存元数据
│   └── session-log.md        # 会话记忆快照
```

**索引文件** `stash-index.json`:
```json
[
  {
    "id": "stash-20260603-083000",
    "branch": "feature/user-auth",
    "description": "用户认证模块 - Phase 3 Group 2 进行中",
    "timestamp": "2026-06-03T08:30:00+08:00",
    "phase": 3,
    "task_group": 2
  }
]
```

**快照文件** `snapshot.json`:
```json
{
  "id": "stash-20260603-083000",
  "branch": "feature/user-auth",
  "timestamp": "2026-06-03T08:30:00+08:00",
  "phase": 3,
  "task_group": 2,
  "complexity": "M",
  "state_files": {
    "02-plan.md": "docs/omnidev-state/feature-user-auth/02-plan.md",
    "03-progress.md": "docs/omnidev-state/feature-user-auth/03-progress.md"
  },
  "uncommitted_files": ["src/services/auth.ts", "src/routes/user.ts"],
  "git_stash_ref": "stash@{0}"
}
```

## 2. `/od st` (Stash) 流程

```yaml
context_requires:
  read:
    - session-log.md              # 当前会话记忆（如果有）
    - 03-progress.md              # 当前进度
  scan:
    - git status --short          # 未提交文件列表
  skip:
    - all other state files
```

### 步骤

1. **检查前置条件**:
   - 如果没有活跃的 `/od` 工作流（没有 state files），提示"当前没有可暂存的任务"并退出。

2. **生成会话记忆**: 按 `session-memory.md` 的规则生成 `session-log.md`（如果尚未存在），状态标记为 `stashed`。

3. **处理未提交代码**:
   - 运行 `git status --short` 检查是否有未提交变更。
   - 如果有未提交变更，使用 `AskQuestion`（或文本提示）：

   | id | 选项 |
   |----|------|
   | `git_stash` | Git stash 暂存代码变更 |
   | `git_commit` | 先提交再暂存任务 (`git commit`) |
   | `skip_code` | 只暂存任务上下文，不处理代码 |

4. **创建快照**:
   - 生成 stash ID: `stash-YYYYMMDD-HHmmss`
   - 创建 `docs/omnidev-state/stash/<id>/` 目录
   - 写入 `snapshot.json`（元数据）
   - 复制当前 `session-log.md` 到 stash 目录
   - 更新 `stash-index.json`

5. **输出确认**:
   ```
   📦 任务已暂存
   ID: stash-20260603-083000
   分支: feature/user-auth
   阶段: Phase 3 — Group 2 进行中
   代码: [已 git stash | 已提交 | 未处理]
   
   使用 `/od po` 恢复此任务
   ```

## 3. `/od po` (Pop) 流程

```yaml
context_requires:
  read:
    - docs/omnidev-state/stash/stash-index.json  # 暂存索引
  skip:
    - all other files until user selects which stash to restore
```

### 步骤

1. **读取索引**: 加载 `stash-index.json`。如果为空或不存在，提示"没有暂存的任务"并退出。

2. **选择恢复目标**:
   - 如果只有 1 个暂存条目，直接确认是否恢复。
   - 如果有多个，使用 `AskQuestion` 列出所有条目让用户选择：

   | id | 选项 |
   |----|------|
   | `stash_N` | [分支名] — [描述] (Phase N, [时间]) |
   | `cancel` | 取消 |

3. **恢复快照**:
   - 读取选中 stash 的 `snapshot.json`
   - 检查当前分支是否匹配。如果不匹配，提示用户切换分支：
     ```
     ⚠️ 暂存的任务在分支 `feature/user-auth`，当前在 `main`。
     是否自动切换？
     ```
   - 如果 `snapshot.json` 中有 `git_stash_ref`，执行 `git stash pop`
   - 将 stash 目录中的 `session-log.md` 复制回 `docs/omnidev-state/[branch]/session-log.md`

4. **清理 stash**:
   - 删除 stash 子目录 `docs/omnidev-state/stash/<id>/`
   - 从 `stash-index.json` 移除该条目

5. **自动进入恢复流程**: 执行 `/od re` 逻辑（读取 session-log + state files 恢复上下文）。

6. **输出确认**:
   ```
   ♻️ 任务已恢复
   分支: feature/user-auth
   阶段: Phase 3 — 从 Group 3 继续
   代码: [已恢复 git stash | 无需恢复]
   
   正在加载上下文...
   ```

## 4. 约束

- **最大暂存数**: 5 个。超过时提示用户清理旧的暂存。
- **过期清理**: 超过 30 天的暂存条目，在 `/od po` 时提示"此暂存已超过 30 天，state files 可能已过时，是否仍要恢复？"
- **分支安全**: pop 时如果目标分支已被删除，提示用户并终止恢复。
- **不自动 pop**: `/od po` 必须由用户显式触发，不会自动恢复。
