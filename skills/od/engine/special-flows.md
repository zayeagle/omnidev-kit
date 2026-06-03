# Special Flows & Engine Instructions

## 1. Push (`/od push`)

```yaml
context_requires:
  scan:
    - git status                     # modified files list
    - git diff --stat                # file-level change summary
    - git diff --staged              # after staging, for commit message generation
  skip:
    - all state files                # push doesn't need OmniDev state
```

1. `git diff --stat HEAD` → generate **Change Impact Summary** and display to user:
   ```
   📋 **本次提交影响总结 (Pre-Push Impact Summary)**

   ### 文件变更 (N 个文件)
   | 操作 | 文件路径 | 说明 |
   |------|---------|------|
   | 📝 修改 | src/routes/user.ts | 新增登录接口 |
   | 🆕 新增 | src/services/auth.ts | 认证服务模块 |
   | 🗑️ 删除 | src/utils/legacy.ts | 废弃旧认证逻辑 |

   ### 功能影响
   - **[模块名]**: [影响描述]

   ### 依赖与配置变更
   - [列出变更，若无则标注"无"]
   ```
2. If `interactive_mode` is `true`, use `AskQuestion`:
   - **一键全自动 (One-click)**: `git add .` -> auto-generate message -> commit -> push.
   - **手动选择 (Manual)**: wait for user to `git add`, then generate message.
   - **取消 (Cancel)**.
3. If `interactive_mode` is `false`, wait for user to `git add`, then generate message.
4. Confirm message (AskQuestion if interactive).
5. `git commit` + `git push origin <current-branch>`.

## 2. Change Management (`/od change`)

```yaml
context_requires:
  read:
    - 00-project-context.md          # stack info for impact scope
    - 02-plan.md                     # current plan to assess impact against
    - 03-progress.md                 # what's already done (can't undo)
    - 04-design.md                   # architectural constraints
  scan:
    - files affected by the proposed change
```

1. Assess impact on current architecture.
2. If interactive, use `AskQuestion` to confirm: Proceed / Revise / Cancel.
3. Archive old plan, regenerate blueprint/plan.

## 3. Report (`/od report`)

```yaml
context_requires:
  read:                              # report needs the full picture
    - 00-project-context.md
    - 02-plan.md
    - 03-progress.md
    - metrics.json
    - archive/*                      # historical progress
  scan:
    - git log --since="7 days ago"
```

1. Read all state files + `archive/`.
2. Analyze `git log` (past 7 days).
3. Generate management-ready report in `docs/omnidev-state/weekly-report-[date].md`.
4. Include: executive summary, AI-assisted achievements, progress, blockers, next week plan.

## 4. Context Pruning (`/od compress` or Auto-trigger)

**Triggers:** `03-progress.md` > 200 lines, 3+ M-level tasks done, or `/od compress`.
**Action:**
1. Archive resolved logs to `docs/omnidev-state/archive/progress-archive-[date].md`.
2. Condense to 1-2 sentence summary at top of `03-progress.md`.
3. Retain: YAML frontmatter, current blockers, next action.
4. Keep `03-progress.md` under 50 lines.

## 5. Update (`/od up`)

```yaml
context_requires:
  read:
    - docs/omnidev-state/config.json   # load update_source_url
  skip:
    - all other state files
```

**Source**: Always use the `update_source_url` from `config.json`. If not set, default to `https://github.com/zayeagle/omnidev-kit.git`.

**Steps**:

1. **Clone remote to temp directory**:
   ```
   git clone --depth 1 <update_source_url> _omnidev-kit-tmp
   ```
2. **Build file manifest** — list all files under the following directories in both remote (`_omnidev-kit-tmp/`) and local (`.cursor/`):

   | Remote source path | Local target path |
   |--------------------|-------------------|
   | `_omnidev-kit-tmp/rules/` | `.cursor/rules/` |
   | `_omnidev-kit-tmp/skills/od/` | `.cursor/skills/od/` |

3. **Diff & present change summary** — compare remote vs local and categorize every file:

   | Category | Meaning |
   |----------|---------|
   | **新增 (New)** | File exists in remote but not locally |
   | **更新 (Changed)** | File exists in both, content differs |
   | **删除 (Obsolete)** | File exists locally but not in remote — will be deleted |
   | **未变 (Unchanged)** | File exists in both, content identical |

   Output a summary table to the user:
   ```
   📦 OmniDev Kit 更新预览
   ┌──────────┬──────────────────────────────────┐
   │ 操作     │ 文件                              │
   ├──────────┼──────────────────────────────────┤
   │ 🆕 新增  │ skills/od/phases/05-deploy.md     │
   │ 📝 更新  │ skills/od/SKILL.md                │
   │ 📝 更新  │ rules/01-omnidev-workflow.mdc     │
   │ 🗑️ 删除  │ skills/od/engine/deprecated.md    │
   │ ✅ 未变  │ skills/od/phases/00-assessment.md │
   └──────────┴──────────────────────────────────┘
   ```

4. **Confirm with user** — the update **MUST NOT** proceed without explicit user approval:

   - If `interactive_mode` is `true`: use **AskQuestion** tool:
     - **确认更新 (Confirm)**: Apply all changes listed above.
     - **取消 (Cancel)**: Abort, delete temp directory, no changes.
   - If `interactive_mode` is `false`: display numbered prompt:
     ```
     请选择：
       1. 确认更新 — 应用以上所有变更 (`/od y`)
       2. 取消更新 (`/od x`)
     ```

   **STOP — WAIT for user reply.** Do NOT proceed until the user confirms.

5. **Apply changes** (only after user confirms):
   - **New + Changed files**: Copy from `_omnidev-kit-tmp/` to `.cursor/`, overwriting existing files.
   - **Obsolete files**: Delete from `.cursor/`.
   - **Unchanged files**: Skip.

6. **Cleanup**: Delete `_omnidev-kit-tmp/` directory.

7. **Report result**:
   ```
   ✅ OmniDev Kit 更新完成
      新增: N 个文件
      更新: N 个文件
      删除: N 个文件
      未变: N 个文件
   ```

**Error handling**:
- If `git clone` fails (network, auth, etc.): report error, suggest checking URL and network, abort.
- If temp directory already exists from a previous failed update: delete it first, then retry.

## 6. Install (`/od i <url>`)

**Steps**: Clone to `_omnidev-kit-tmp`, copy rules/skills per INSTALL.md, write `update_source_url` to `config.json`, cleanup temp directory.

## 7. Resume (`/od re`)

```yaml
context_requires:
  read:
    - docs/omnidev-state/config.json          # locale, interactive_mode
    - docs/omnidev-state/user-preferences.md  # user behavior preferences (if exists)
    - session-log.md                          # session memory (if exists) — CRITICAL for resume
    - 00-project-context.md
    - 02-plan.md                              # resume needs plan to locate position
    - 03-progress.md                          # current progress
  skip:
    - 01-blueprint.md, 04-design.md
    - 05-test-report.md, 06-release-notes.md
```

### 步骤

1. **读取 session-log.md**（如果存在）：
   - 从 YAML frontmatter 中获取 `last_phase`、`last_task_group`、`status`
   - 从 `## 关键决策` 恢复决策上下文
   - 从 `## 用户反馈要点` 恢复用户偏好上下文
   - 从 `## 恢复指引` 获取具体恢复操作建议

2. **读取 state files**：按 `context_requires` 加载 plan 和 progress

3. **定位恢复点**：
   - 如果 session-log 存在：使用其中的 `last_phase` + `last_task_group` 定位
   - 如果 session-log 不存在：从 `03-progress.md` 和 `02-plan.md` 推断（找到第一个未完成的任务）

4. **向用户汇报**并确认恢复：
   ```
   ♻️ 会话恢复
   分支: [branch]
   上次进度: Phase [N] — [描述]
   未完成: [任务列表]
   ```
   使用 AskQuestion（如果 interactive）确认：继续 / 重新开始 / 取消

5. **加载对应 phase 指令**：根据恢复点加载对应的 `phases/{L}/` 文件，进入正常工作流

### 检查未处理的学习信号

如果 `evolution-log.jsonl` 存在且包含 `processed: false` 的信号，在恢复输出末尾追加提示。

## 8. Session Exit (`/od x`)

当用户结束会话时（输入 `/od x` 或选择"结束"），在输出关闭摘要前执行：

1. **生成 session-log.md**（按 `engine/session-memory.md` 的规则）：
   - 记录当前阶段、进度、关键决策、用户反馈
   - 状态标记为 `in_progress`（如果有未完成任务）或 `completed`
   - 写入 `docs/omnidev-state/[branch]/session-log.md`

2. **更新 user-preferences.md**（如果本次会话有新的偏好信号）：
   - 按 `engine/user-preferences.md` 的采集规则检查是否有新偏好
   - 如有，静默更新 `docs/omnidev-state/user-preferences.md`

3. **输出关闭摘要**：
   ```
   ✅ 会话结束
   本次完成: [已完成的任务/阶段摘要]
   待继续: [未完成项，若有]
   会话记忆已保存，使用 `/od re` 可随时恢复
   ```

4. **Q&A Loop 不再触发**——`/od x` 是终止信号，不追加 Q&A prompt