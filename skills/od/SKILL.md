---
name: od
description: >-
  OmniDev AI-driven development workflow. Use ONLY when the user's message starts with /od
  (e.g. /od h, /od re, /od ob, /od rp, /od rv, /od qa, /od ch, /od ln).
  Do not load or follow this skill for normal chat without the /od prefix.
---

# OmniDev Workflow Skill — Full Specification

This file is the **single source of truth** for all OmniDev rules. The lightweight trigger lives in `rules/01-omnidev-workflow.mdc` (`alwaysApply: false`); **everything below applies only when the current user message starts with `/od`** — including workflow, `docs/omnidev-state/**`, and evolution logging. No OmniDev behavior on non-`/od` turns.

---

## A. Command Reference (On-Demand)

**DO NOT read the command table into context on every activation.**

- The full command reference lives in `engine/commands.md`.
- **Load it ONLY when**: the user types `/od h` or `/od help`, or asks "what commands are available".
- For all other `/od` commands, the AI already knows how to route them from the rules below — no need to load the full table.

---

## B. Core Rules

### B.0 First Principle — 不确定就问，禁止自我发挥

**此条为最高优先级规则，贯穿所有 phase、所有命令、所有决策点。任何其他规则与此条冲突时，以此条为准。**

在整个 OmniDev 工作流中，凡遇到 **不确定、不清楚、有歧义、有多种可能** 的情况，**一律停下来问用户确认**，禁止擅自解读、禁止自我发挥、禁止"猜一个合理的"然后继续。

**适用场景（不限于以下）**：

| 场景 | 错误做法 | 正确做法 |
|------|---------|---------|
| 需求模糊 | 自行解读并开始编码 | 停下来，问用户确认核心诉求和验收标准 |
| 技术方案有多种选择 | 自行挑一个"最佳"方案 | 列出方案及对比，问用户选哪个 |
| 代码风格/命名不确定 | 按 AI 默认习惯写 | 参考 user-preferences.md；若无记录，问用户 |
| Phase 阶段选择 | 替用户决定跳过/保留 | 推荐策略，但用 AskQuestion 让用户确认 |
| 修复问题 | 直接提交补丁 | 先输出方案，等用户审阅确认后再动手 |
| 卸载上下文内容 | 自行判断"应该不需要了" | 只卸载 `unload` 声明中明确列出的内容 |
| 前序步骤结果是否仍需保留 | 自行判断"已经不需要" | 只丢弃 `discard_after_write` 中列出的原始输出；state files 永不主动丢弃 |
| 依赖版本/框架选择 | 选一个"流行的" | 参考 00-project-context.md 现有技术栈；若无定论，问用户 |
| 删除/重构现有代码 | 认为"这样更好"就改 | 说明改动理由和影响，问用户确认后再改 |

**执行方式**：
- **`interactive_mode` = `true`**: 使用 AskQuestion 工具呈现选项
- **`interactive_mode` = `false`**: 输出文字提问，等待用户回复
- **无论哪种模式**: 问完之后必须 **STOP — WAIT**，不可在同一回复中自行继续

**判断标准**：如果你需要说"我假设..."、"我猜测..."、"应该是..."、"大概是..."，那就说明你不确定——停下来问。

### B.1 Activation & Tool Execution
- OmniDev activates **only** on `/od` prefix. Without it, treat as normal conversation.
- First action on any `/od` message MUST be a tool call — zero text before tools.
- Ad-hoc requests (e.g. `/od 这里加个按钮`) → use tools to find file, edit code, apply changes directly.
- Image attachments: tool calls FIRST, then explain.

### B.2 Workflow Philosophy
- Guided, not forced. Phase order: **Blueprint → Plan → Dev → Test → Deploy**.
- Phases execute in forward order only, but **any phase can be skipped**.
- Complexity assessment (S/M/L/XL) provides **recommendations**, not mandates.

### B.3 Requirement Alignment

B.0 原则在需求阶段的具体应用：

分析用户需求时，凡遇到以下情况，**禁止擅自解读、禁止直接开始任务**：
- 需求模糊、表述不清、存在歧义
- 关键信息缺失（目标、范围、验收标准等）
- 无法自行判定用户意图、最终目标或交付标准

**必须向用户确认以下要素**：
1. **核心诉求**：用户到底要解决什么问题？
2. **最终目标**：期望达到的结果是什么？
3. **交付效果**：怎样算「做完了」？
4. **本质问题**：表象需求背后要解决的根因是什么？

待用户需求完全明确后，才可制定方案并执行。宁可多问一轮，不可做错一步。

### B.4 Problem Fix Protocol

B.0 原则在问题修复阶段的具体应用：

接到修复类需求时（Bug Fix / Security Fix / Behavior Correction），**禁止直接发补丁**。

**必须执行的流程**：
1. **诊断根因**：分析问题本质，定位根本原因而非表象。
2. **输出完整解决方案**：包括修复思路、影响范围、回归风险。
3. **多方案择优**：若存在多种解决路径，列出对比并说明选择理由。
4. **等待用户确认**：方案经用户审阅同意后，再进行落地修复。

未经确认的修复一律不得提交。

### B.5 State File Isolation
- Global: `docs/omnidev-state/` (`00-project-context.md`, `metrics.json`, `config.json`, `user-preferences.md`)
- Branch-specific: `docs/omnidev-state/[branch-name]/` (`01-blueprint.md`, `02-plan.md`, `03-progress.md`, `04-design.md`, `05-test-report.md`, `06-release-notes.md`, `session-log.md`)
- Stash: `docs/omnidev-state/stash/` (`stash-index.json`, `<stash-id>/snapshot.json`, `<stash-id>/session-log.md`)

### B.6 Numbered Quick-Select

At **every checkpoint** where the user needs to choose an action, present options as a **numbered list** in the current `locale` language. The user can reply with the **number**, the **short alias**, or the **full command**. All three forms are equivalent.

**Rules**:
- Numbers are **context-dependent** — each checkpoint defines its own numbered menu.
- If the user replies with a number that is out of range, ask them to choose again.
- Always show the short alias in parentheses next to each option.
- **When `interactive_mode` is `true`**: Replace the numbered text list with the **AskQuestion** tool (structured choice UI). This saves a request round-trip and reduces token usage.
- All option labels must match the current `locale`.

### B.7 Context Lifecycle Management (加载 / 摘要 / 卸载)

**核心原则**: LLM 无法主动遗忘已读入的内容，因此必须通过 **"少读 + 摘要替代 + 沉淀后卸载"** 三层机制控制上下文膨胀。**但卸载的前提是：关键产出已通过 state file 沉淀，后续 phase 可通过 `context_requires.read` 重新加载。**

#### B.7.1 按需加载 (Load)

每个 phase 和 command 声明 `context_requires`，进入时：

1. **只读声明的文件**——不在列表中的文件一律不读。
2. **跳过不存在的文件**——缺失即信息（如无 `00-project-context.md` 说明未 onboard）。
3. **禁止预读下游产物**——Phase 2 不读 `05-test-report.md`。
4. **扫描需授权**——只有 `context_requires` 包含 `scan:` 字段时才允许 Grep/Glob/SemanticSearch。
5. **scan_limit 硬上限**——scan 结果超过 `scan_limit` 条时，只取最相关的前 N 条，丢弃其余。

#### B.7.2 摘要替代 (Summarize-then-discard)

**对工具调用结果**实施摘要替代——这是上下文消耗最大的隐形来源：

| 工具调用类型 | 摘要规则 |
|-------------|---------|
| **Read 大文件** (> 100 行) | 读取后立即提取关键信息（函数签名、接口定义、配置项），在后续推理中只引用摘要，不复述原文 |
| **Grep/Glob 结果** (> 20 条匹配) | 只保留最相关的 10 条结果用于推理，其余记为"另有 N 条匹配已省略" |
| **Shell 输出** (> 50 行) | 提取关键行（错误信息、统计摘要、最后状态），丢弃中间过程日志 |
| **git diff** (> 30 个文件) | 按目录分组统计，只展示 top 20 文件的详细 diff |

**操作方式**: 在工具调用返回后、进入下一步推理前，AI 在内部将结果压缩为摘要形式。后续引用时使用摘要而非原始输出。

#### B.7.3 沉淀后卸载 (Persist-then-unload)

**卸载 ≠ 遗忘。卸载 = 将信息从"对话历史"转移到"state file"，后续 phase 通过 read 重新加载。**

上下文中的内容分为两类，卸载策略不同：

| 内容类型 | 示例 | 可否卸载 | 卸载条件 |
|---------|------|---------|---------|
| **原始工具输出** | Read 的文件原文、Grep 匹配列表、Shell 执行日志、git diff 原文 | ✅ 可卸载 | 关键信息已被 AI 提取并用于产出 |
| **中间推理过程** | AI 分析需求的推导、方案对比的思考过程 | ✅ 可卸载 | 结论已写入 state file 或 checkpoint 输出 |
| **Phase 指令文件** | `00-assessment.md`、`01-02-planning.md` 等 | ✅ 可卸载 | 已退出该 phase，指令不再适用 |
| **结构化产出 (state files)** | `02-plan.md`、`03-progress.md`、`00-project-context.md` | ❌ 不可主动卸载 | 后续 phase 的 `context_requires.read` 会按需重新加载 |
| **用户的决策与反馈** | 用户选择跳过 Blueprint、要求统一 API 格式等 | ❌ 不可卸载 | 必须持久保留（写入 session-log 或 user-preferences） |

**依赖链保护规则**：

```
Phase 0 产出 → 00-project-context.md → Phase 1/2/3/4 都可能读取（不可卸载）
Phase 1 产出 → 01-blueprint.md       → Phase 2 读取（Phase 2 后可卸载，因精华已入 02-plan.md）
Phase 2 产出 → 02-plan.md            → Phase 3/4 都读取（不可卸载）
Phase 3 产出 → 03-progress.md        → Phase 4 读取（不可卸载）
Phase 4 产出 → 05-test-report.md     → 会话结束时引用（不可提前卸载）
```

**每个 phase 的 `context_requires` 通过 `unload` 字段声明可卸载的内容。`unload` 只能包含上表中标记为"✅ 可卸载"的类型。**

**B.0 原则兜底**: 如果某个内容不在 `unload` 列表中，且你不确定后续是否还需要——**保留它**。不确定时永远选择保留。

#### B.7.4 Phase 转场摘要 (Transition Summary)

每个 phase 退出时，通过 `summarize_before_exit` 将关键产出沉淀到 state file：

```yaml
context_requires:
  read: [...]
  summarize_before_exit:
    target: "02-plan.md"             # 将本 phase 的关键产出写入此 state file
    discard_after_write:             # 写入后可忽略的"原始工具输出"（非 state file）
      - "source code scan results"   # ✅ 原始工具输出，已提取到 plan 中
      - "intermediate Shell logs"    # ✅ 中间过程，已提取关键信息
    retain:                          # 即使转场后仍需保留的内容
      - "user decisions and feedback" # ❌ 用户反馈，必须保留
      - "state files listed in next phase's context_requires.read"  # ❌ 下游依赖
```

**关键区分**: `discard_after_write` 只能丢弃**原始工具输出和中间过程**，绝不能丢弃 **state files 和用户决策**。后者通过 `retain` 显式标注保护。

### B.8 Configuration (`config.json`)

OmniDev stores user preferences in `docs/omnidev-state/config.json`. If the file does not exist, treat all settings as their defaults.

```json
{
  "interactive_mode": true,
  "ask_mode_after_od": true,
  "locale": "zh",
  "update_source_url": "https://github.com/zayeagle/omnidev-kit.git"
}
```

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `interactive_mode` | boolean | `true` | Use **AskQuestion** tool for structured choice UIs at decision points. |
| `ask_mode_after_od` | boolean | `true` | Enter a **Q&A loop** after every `/od` command completes. |
| `locale` | string | `"zh"` | UI language. `"zh"` = Chinese, `"en"` = English. Controls which locale variant of phase/engine files to load. |
| `update_source_url` | string | `"https://github.com/zayeagle/omnidev-kit.git"` | Remote Git URL for `/od up`. |

#### Config Commands

- **`/od cfg`** — Read and display current `config.json` (create with defaults if missing).
- **`/od cfg -i on`** — Set `interactive_mode` and `ask_mode_after_od` to `true`.
- **`/od cfg -i off`** — Set both to `false`.
- **`/od cfg -l zh`** — Set `locale` to `"zh"`.
- **`/od cfg -l en`** — Set `locale` to `"en"`.

### B.9 Interactive Mode

When `interactive_mode` is **`true`** (default), the AI MUST use the **AskQuestion** tool at these decision points instead of numbered text prompts:

| Decision Point | Questions Presented |
|----------------|-------------------|
| **Phase 0: Complexity Assessment** | Confirm/adjust complexity rating; select phases to include/skip |
| **Phase Checkpoint** (after each phase) | Choose next action: continue / adjust / skip / go back |
| **Change Management** (`/od ch`) | Confirm impact assessment: proceed / revise / cancel |
| **Push** (`/od ps`) | Confirm commit message: commit / edit message / cancel |
| **Learning Proposals** (`/od ln`) | For each proposal: adopt / reject / adjust |

When `interactive_mode` is **`false`**, use numbered text prompts as defined in §B.6.

**On first `/od` activation in a session**: Read `docs/omnidev-state/config.json` (if it exists) to load settings. If absent, assume defaults.

### B.10 Auto Q&A Loop & Command Prompt (命令提示)

When `ask_mode_after_od` is **`true`** (default), the AI enters a **Q&A loop** after every `/od` command completes.

#### Trigger

After every `/od` command finishes its primary work, present the **command prompt** as the **final action**.

#### Command Prompt — 可用命令列表

每次 phase 或命令执行完毕后，必须展示**当前可用的命令列表**，每个命令附带别名和说明。命令列表是**上下文相关的**——只展示当前状态下有意义的命令。

**展示格式（`interactive_mode` = `false` 时）**：

```
📋 可用命令：
 #  | 命令         | 说明
 1  | /od n (next)  | 继续下一阶段
 2  | /od ad (adj)  | 修订当前阶段输出
 3  | /od sk (skip) | 跳过某个阶段
 4  | /od bk (back) | 返回某个阶段
 5  | /od rv (review)| 代码审查（只读）
 6  | /od qa        | 运行测试
 7  | /od ps (push) | 提交并推送代码
 8  | /od ln (learn)| 自学习与复盘
 9  | /od ch (change)| 需求变更管理
10  | /od rp (report)| 生成周报
11  | 直接输入       | 其他指令或提问
12  | /od x (cancel)| 结束本次任务

请输入编号或命令：
```

**展示格式（`interactive_mode` = `true` 时）**：

使用 **AskQuestion** 工具，每个 option 的 label 格式为：`[命令别名] — [说明]`。例如：
- label: `继续下一阶段 (/od n)` 或 `Continue to next phase (/od n)`

#### 命令可见性规则

以下规则决定哪些命令在当前状态下展示：

| 命令 | 别名 | zh 说明 | en 说明 | 何时展示 |
|------|------|--------|---------|---------|
| `/od n` | next | 继续下一阶段 | Continue to next phase | 工作流进行中，有剩余阶段 |
| `/od ad` | adj | 修订当前阶段输出 | Revise current output | 刚完成某个阶段 |
| `/od sk` | skip | 跳过某个阶段 | Skip a phase | 工作流进行中，有剩余阶段 |
| `/od bk` | back | 返回某个阶段 | Go back to a phase | 已完成 ≥ 1 个阶段 |
| `/od al` | all | 执行所有剩余阶段 | Execute all remaining | 工作流进行中，剩余 ≥ 2 个阶段 |
| `/od rv` | review | 代码审查（只读） | Code review (read-only) | 有代码文件被修改 |
| `/od qa` | — | 运行测试 | Run tests | 有代码文件被修改 |
| `/od ps` | push | 提交并推送代码 | Commit & push | 有未提交的变更 |
| `/od ln` | learn | 自学习与复盘 | Self-learning | M/L/XL 任务刚完成 |
| `/od ch` | change | 需求变更管理 | Change management | 工作流进行中 |
| `/od rp` | report | 生成周报 | Weekly report | 始终可用 |
| `/od st` | stash | 暂存当前任务 | Stash current task | 工作流进行中 |
| `/od cfg` | config | 查看/修改配置 | View/edit config | 始终可用 |
| 直接输入 | — | 其他指令或提问 | Other command or question | **始终可用** |
| `/od x` | cancel | 结束本次任务 | End this task | **始终可用** |

**规则**：
- 命令说明必须使用当前 `locale` 对应的语言
- `直接输入` 和 `/od x` 始终作为最后两个选项
- 编号从 1 开始，用户可以回复编号、别名或完整命令
- 每个命令只展示一行，保持列表紧凑

#### Loop Behavior

- **用户选择某个命令** → 执行该命令，完成后再次展示命令提示
- **用户选择"直接输入"/Other 或输入自由文本** → 作为 OmniDev 会话的延续处理（全工具权限），完成后再次展示命令提示
- **用户输入 `/od x` 或选择"结束"** → 输出关闭摘要，停止循环
- **用户输入新的 `/od` 命令** → 正常执行，循环继续

#### Rules

1. 命令提示是每次回复的**最后一个动作**——在所有输出、checkpoint、phase 操作之后。
2. When `ask_mode_after_od` is **`false`**, skip the command prompt entirely.

### B.11 Dynamic Skill Composition (On-Demand)

**DO NOT load Skill Composition rules into context by default.**

- The full specification lives in `engine/skill-composition.md`.
- **Load it ONLY when**: the user's `/od` message matches troubleshooting/diagnosis intent keywords (报错, exception, error, 排查, troubleshoot, debug, fix, 修复, etc.).
- For normal development workflows, this module is irrelevant and should not consume context.

**Quick-check keyword list** (if ANY match, load `engine/skill-composition.md`):
`报错`, `异常`, `exception`, `error`, `failed`, `crash`, `排查`, `troubleshoot`, `debug`, `diagnose`, `fix`, `hotfix`, `修复`, `修bug`, `漏洞`, `查日志`, `log`, `OOM`, `timeout`, `超时`, `Pod`, `K8s`, `部署失败`

### B.12 Session Memory (会话记忆)

每次 `/od` 会话结束时自动生成结构化摘要，持久化到 `docs/omnidev-state/[branch]/session-log.md`，实现跨会话断点续传。

- 完整规则见 `engine/session-memory.md`。**Load it when**: `/od x`（会话结束）、`/od re`（恢复会话）、`/od st`（暂存）。
- **写入时机**: 用户输入 `/od x` 或选择"结束"时，在输出关闭摘要的同时静默写入，不阻塞退出。
- **读取时机**: `/od re` 恢复时 **必读** session-log（如果存在），用于定位恢复点和恢复决策上下文。
- **新需求保护**: 当同分支存在 `status: in_progress` 的 session-log 时，新 `/od` 命令应提醒用户"检测到未完成的任务"。

### B.13 User Preferences (用户偏好档案)

被动采集用户行为模式，持久化到 `docs/omnidev-state/user-preferences.md`（全局级，不分分支）。

- 完整规则见 `engine/user-preferences.md`。**不需要单独加载此文件**——规则已内联如下。
- **加载时机**: 每次 `/od` 激活时，与 `config.json` 同步读取（如果存在）。文件限制 30 行以内，上下文开销可忽略。
- **采集原则**: 同一偏好信号出现 **2 次以上** 才写入；静默采集不提示用户；新偏好覆盖旧偏好。
- **采集范围**: Phase 跳过模式、代码风格纠正、输出详细程度偏好、技术栈偏好、交互语言偏好。
- **使用方式**: Phase 3 参考 `## 代码风格` 指导代码生成；Checkpoint 参考 `output_verbosity` 调整输出详细程度。
- **用户可控**: `/od cfg` 同时展示偏好内容；用户可直接编辑或删除文件重置。

### B.14 Stash & Pop (任务暂存/恢复)

支持多任务切换：`/od st` 保存当前工作快照，`/od po` 恢复。

- 完整规则见 `engine/stash.md`。**Load it ONLY when**: 用户输入 `/od st` 或 `/od po`。
- **存储路径**: `docs/omnidev-state/stash/`（索引 + 快照子目录）。
- **最大暂存数**: 5 个；超过 30 天的条目恢复时提示过期。
- `/od st`: 生成 session-log → 处理未提交代码（git stash / commit / skip）→ 保存快照。
- `/od po`: 读取索引 → 选择恢复目标 → 切分支 → 恢复代码 → 自动执行 `/od re`。

---

## C. Phase Execution Protocol

### C.0 Locale-Aware File Loading

**MANDATORY**: All phase and engine instruction files are organized by locale under `phases/{locale}/` and `engine/{locale}/`. On first `/od` activation, read `locale` from `config.json` (default: `"zh"`).

**Path resolution** (replace `{L}` with current `locale`):

| Target | File to Load |
|--------|-------------|
| Phase 0 / `/od onboard` | `phases/{L}/00-assessment.md` |
| Phase 1 & 2 | `phases/{L}/01-02-planning.md` |
| Phase 3 | `phases/{L}/03-development.md` |
| Phase 4 / `/od qa` | `phases/{L}/04-testing.md` |
| `/od push`, `/od change`, `/od report`, `/od compress` | `engine/{L}/special-flows.md` |
| `/od learn`, `/od ln` | `engine/{L}/evolution.md` |
| `/od h`, `/od help` | `engine/commands.md` |
| `/od st`, `/od po` | `engine/stash.md` |
| `/od x` (会话结束), `/od re` (恢复) | `engine/session-memory.md` |
| 排障/诊断类需求 | `engine/skill-composition.md` |

**Locale-independent engine files**: `commands.md`, `stash.md`, `session-memory.md`, `skill-composition.md`, `user-preferences.md` 不分 locale，直接从 `engine/` 加载。

**Rules**:
- **Load only ONE locale** — never load both `zh/` and `en/` files simultaneously.
- If locale-specific file is missing, fall back to the root-level file.
- All user-facing output MUST use the language matching the current `locale`.

After reading the instruction file, follow its `context_requires` block to load project state files.

### C.1 Phase Transition Protocol (上下文转场协议)

Phase 转场是上下文膨胀最严重的时刻。严格执行以下协议，**同时确保依赖链完整**。

**B.0 原则在此处的应用**: 卸载内容时只卸载 `unload` 中明确列出的项；遇到不确定"这个信息后面还要不要用"的情况，**保留而非丢弃**——宁可多占一点上下文，不可丢失后续 phase 需要的关键信息。

#### 依赖链总览

在卸载任何内容前，必须理解 phase 间的依赖关系：

```
Phase 0 ──写入──→ 00-project-context.md ──被读取──→ Phase 1, 2, 3, 4
Phase 1 ──写入──→ 01-blueprint.md       ──被读取──→ Phase 2
Phase 2 ──写入──→ 02-plan.md            ──被读取──→ Phase 3, 4
Phase 3 ──写入──→ 03-progress.md        ──被读取──→ Phase 4
Phase 3 ──更新──→ 02-plan.md (mark [x]) ──被读取──→ Phase 4
Phase 4 ──写入──→ 05-test-report.md     ──被读取──→ 会话结束
```

**任何出现在下游 phase `context_requires.read` 中的 state file 都不可被卸载——它们是依赖链的节点。**

#### 退出 Phase N 时（Checkpoint 之后、加载 Phase N+1 之前）

1. **沉淀到 state file**: 将本 phase 的关键产出写入对应 state file。**确保所有后续 phase 需要的信息都已持久化，不依赖对话历史。** 具体包括：
   - 用户做出的决策和偏好
   - 分析结论和方案选择理由
   - 关键的技术发现（如 API 签名、数据结构、依赖关系）

2. **输出转场摘要** (≤ 5 行)：概括本 phase 对后续 phase 有价值的核心信息：
   ```
   📌 Phase N 上下文摘要（后续 phase 可从 state files 获取详情）:
   - [已沉淀到哪个 state file，包含什么]
   - [需要后续 phase 特别注意的事项]
   - [用户的关键决策/偏好]
   ```

3. **标注可卸载内容**（仅限原始工具输出和中间过程，不含 state files）：
   ```
   ⏹️ 以下原始工具输出已无需引用（关键信息已沉淀到 state files）：
   - Phase N 指令文件 (XX-phase.md) 的原文
   - Phase N 期间的 Read/Grep/Shell 原始返回值
   - Phase N 期间的中间推理过程
   ✅ 以下内容仍然有效（state files，后续 phase 将按需读取）：
   - [列出本 phase 写入/更新的 state files]
   ```

#### 进入 Phase N+1 时

1. **加载新指令**: 读取 Phase N+1 的指令文件
2. **重新读取依赖的 state files**: 按 `context_requires.read` 列表加载。**这是从"文件系统"重新读取，不是从对话历史回忆。** 这确保即使前序工具输出被标记为过期，结构化产出仍可通过 state file 完整获取。
3. **执行 unload**: 按 `unload` 列表跳过前序的原始工具输出和指令文件
4. **工作上下文构成**: AI 此刻的有效上下文应为：
   - SKILL.md 核心规则 (B.1–B.14)（常驻）
   - 当前 phase 指令文件（刚加载）
   - `context_requires.read` 列出的 state files（刚从文件系统重新读取）
   - user-preferences.md（如果存在，常驻）
   - 上一步的转场摘要（≤ 5 行）

#### 回溯规则（当后续 phase 发现缺少前序信息时）

如果在 Phase N+1 执行过程中发现需要 Phase N 的某个细节，但该细节未被沉淀到 state file 中：
1. **优先从 state file 查找**——大部分信息应已沉淀
2. **允许重新读取源文件**——如果 state file 中确实缺失，可以用 Read 工具重新读取项目中的源文件（代码文件、配置文件等），这不算违规
3. **禁止的是**：回溯到对话历史中的原始工具输出去"翻找"——这对 AI 来说既不可靠也不高效

### C.2 Phase Exit — Checkpoint

每个 phase 完成后，输出 checkpoint 摘要。格式如下（使用当前 `locale` 语言）：

```
✅ Phase N 完成: [Phase Name]
📦 产出物: [列出生成/更新的 state files]
📍 进度: Phase 0 ✅ → Phase 1 ✅ → Phase 2 ✅ → Phase 3 🔄 → Phase 4 ⏳
🔜 下一阶段: Phase N+1 — [Name]（将加载: [files]，将执行: [actions]）

📌 Phase N 上下文摘要（供后续参考）:
- [关键产出 1]
- [关键产出 2]
- [用户的关键决策]
```

**Phase 3 special rule**: The checkpoint MUST include the **Change Impact Summary** (defined in `03-development.md` §2) before the standard checkpoint output.

**Checkpoint 之后，必须展示命令提示**（按 B.10 的命令可见性规则）。这是用户决定下一步操作的入口。

**If `interactive_mode` is `false`**: 展示命令列表（编号 + 别名 + 说明）。**STOP — WAIT for user reply**.
**If `interactive_mode` is `true`**: 使用 **AskQuestion** 工具展示命令选项（label 带别名和说明）。**STOP — WAIT for user selection**.

### C.3 Context Budget (上下文预算)

每个 phase 在任意时刻的"活跃上下文"应控制在以下预算内：

| 上下文类型 | 预算上限 | 可否裁剪 | 超限处理 |
|-----------|---------|---------|---------|
| **SKILL.md 核心规则** | 常驻（~200 行） | ❌ | 不裁剪 |
| **当前 phase 指令文件** | 1 份（~60-100 行） | ❌ | 不裁剪 |
| **State files** (context_requires.read) | 合计 ≤ 200 行 | ⚠️ 可精简不可丢弃 | 超长 state file 只读 YAML frontmatter + 当前活跃 section；但**不可跳过不读** |
| **工具调用结果** (单次) | ≤ 100 行 | ✅ | 超过时按 B.7.2 摘要替代 |
| **历史工具结果** (累计) | 最近 3 次的摘要 | ✅ | 更早的工具调用结果视为已过期 |
| **转场摘要** | ≤ 5 行/phase | ✅ | 只保留最近 1 个 phase 的转场摘要 |
| **user-preferences.md** | ≤ 30 行 | ❌ | 常驻 |
| **用户决策/反馈** | 不限 | ❌ | 已写入 session-log 或 user-preferences，不可丢弃 |

#### 裁剪安全规则

**在裁剪任何内容前，必须检查**：
1. 该内容是否在下游 phase 的 `context_requires.read` 中被引用？→ 如果是，**禁止裁剪**
2. 该内容是否包含用户的显式决策或偏好？→ 如果是，**必须先沉淀到 session-log 或 user-preferences**
3. 该内容是否是 state file？→ State file **永远不被裁剪**，它们是 phase 间传递信息的唯一可靠通道

**可安全裁剪的内容（无依赖风险）**：
- 工具调用的原始输出（Read/Grep/Shell 的返回值）——前提是关键信息已被提取使用
- 前序 phase 的指令文件原文——当前 phase 有自己的指令
- 中间推理过程——结论已体现在产出中

#### 自动裁剪触发

当 AI 感知到上下文窗口已接近容量限制（表现为：回复变慢、开始遗漏前文信息、工具调用结果被截断），应主动执行：

1. **触发 `/od compress`**: 压缩 `03-progress.md`（保留 frontmatter + 当前活跃任务）
2. **清理工具历史**: 将所有超过 3 轮的工具调用原始输出标记为过期（**state files 不受影响**）
3. **如果需要前序信息**: 从 state file 重新读取，而非在对话历史中翻找

---

## D. Project Type Awareness
- **Legacy**: Follow existing conventions 100%. No forced DDD/TDD. "Write code like a sensible veteran employee."
- **Greenfield**: Full modern conventions — OpenSpec / TDD / DDD, high test coverage, deployment manifests.

## E. MCP Integration
During Phase 3 & 4, proactively use available MCP servers:
- **Database MCP**: Verify table structures, insert mock data, check data flow.
- **Browser MCP (Playwright)**: Start server → visit page → E2E test → screenshot/DOM verification.
- **Discovery**: Check `.cursor/mcp.json` before complex tasks. If critical MCP missing, suggest installation.
