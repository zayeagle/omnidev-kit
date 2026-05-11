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

## A. Command Reference

All commands support **short aliases** (1-2 letters). Users can also reply with **numbers** (e.g. `1`, `2`, `3`) when presented with numbered options at any checkpoint.

### Core Commands

| Command | Alias | 说明 |
|---------|-------|------|
| `/od [需求]` | — | 引导式工作流：评估复杂度 → 推荐阶段 → 可跳过任意阶段 |
| `/od -f [需求]` | — | 快速模式：跳过蓝图/计划，直接开发（热修复） |
| `/od -p [需求]` | — | 仅规划：只输出蓝图和计划，不写代码 |
| `/od h` | `/od help` | 显示所有命令 |
| `/od ob` | `/od onboard` | 扫描项目，生成上下文文档 |
| `/od rp` | `/od report` | 生成周报 |
| `/od rv` | `/od review` | 代码审查（只读，不修改） |
| `/od qa` | — | 依赖分析 → Mock → 场景覆盖 → 韧性测试 → 测试报告 |
| `/od ch [新需求]` | `/od change` | 需求变更管理 |
| `/od ln` | `/od learn` | 自学习：回顾错误 + 提炼规则 + 演化提案 |
| `/od ln -r` | — | 查看学习日志和待处理提案 |
| `/od ln -a` | — | 自动应用所有待处理提案 |
| `/od ln --rb [N]` | — | 回滚第 N 条演化 |
| `/od up` | `/od update` | 更新 OmniDev Kit 到最新版本 |
| `/od i <url>` | `/od install` | 从远程 Git 仓库安装 OmniDev Kit |
| `/od ps` | `/od push` | 提交并推送代码 |
| `/od st` | `/od stash` | 暂存当前任务上下文 |
| `/od po` | `/od pop` | 恢复暂存的任务上下文 |
| `/od sy` | `/od sync` | 同步输出到 Jira/GitHub Issue |
| `/od db` | `/od dashboard` | 生成全局效率 ROI 面板 |
| `/od re` | `/od resume` | 恢复上次中断的会话（加载 OmniDev 规则） |
| `/od cfg` | `/od config` | 查看当前 OmniDev 配置 / View current config |
| `/od cfg -i on` | — | 开启交互模式 + 自动问答模式 / Enable interactive + auto Q&A mode |
| `/od cfg -i off` | — | 关闭交互模式 + 自动问答模式 / Disable interactive + auto Q&A mode |
| `/od cfg -l zh` | — | 切换为中文模式 / Switch to Chinese |
| `/od cfg -l en` | — | 切换为英文模式 / Switch to English |

### Phase Navigation (阶段导航)

| Command | Alias | 说明 |
|---------|-------|------|
| `/od n` | `/od next` | 下一阶段 |
| `/od ad [内容]` | `/od adj` | 修订当前阶段输出 |
| `/od sk [阶段]` | `/od skip` | 跳过某个阶段 |
| `/od bk [阶段]` | `/od back` | 返回某个阶段 |
| `/od al` | `/od all` | 执行所有剩余阶段（不暂停） |

### Confirmation (确认操作)

At every checkpoint, options are presented as **numbered list** — user can reply with the **number**, the **alias**, or the **full command**. Example: reply `1` or `/od n` or `/od next` all mean "proceed to next phase".

| Command | Alias | 说明 |
|---------|-------|------|
| `/od y` | `/od confirm` | 确认当前操作 |
| `/od x` | `/od cancel` | 取消当前操作 |
| `/od em [msg]` | — | 修改提交信息（`/od ps` 流程中） |
| `/od ln y` | — | 接受所有学习提案 |
| `/od ln y [N,N]` | — | 接受指定编号的提案 |
| `/od ln x` | — | 拒绝所有提案 |
| `/od ln ad [N] [反馈]` | — | 调整指定提案 |

---

## B. Core Rules

### B.1 Activation & Tool Execution
- OmniDev activates **only** on `/od` prefix. Without it, treat as normal conversation.
- First action on any `/od` message MUST be a tool call — zero text before tools.
- Ad-hoc requests (e.g. `/od 这里加个按钮`) → use tools to find file, edit code, apply changes directly.
- Image attachments: tool calls FIRST, then explain.

### B.2 Workflow Philosophy
- Guided, not forced. Phase order: **Blueprint → Plan → Dev → Test → Deploy**.
- Phases execute in forward order only, but **any phase can be skipped**.
- Complexity assessment (S/M/L/XL) provides **recommendations**, not mandates.

### B.3 Requirement Alignment (需求判定与对齐规则)

**第一性原理：需求不清不动手。**

分析用户需求时，凡遇到以下情况，**禁止擅自解读、禁止自我发挥、禁止直接开始任务**：
- 需求模糊、表述不清、存在歧义
- 关键信息缺失（目标、范围、验收标准等）
- 无法自行判定用户意图、最终目标或交付标准

**必须执行的动作**：主动向用户沟通确认，对齐以下要素：
1. **核心诉求**：用户到底要解决什么问题？
2. **最终目标**：期望达到的结果是什么？
3. **交付效果**：怎样算「做完了」？
4. **本质问题**：表象需求背后要解决的根因是什么？

待用户需求完全明确后，才可制定方案并执行。宁可多问一轮，不可做错一步。

### B.4 Problem Fix Protocol (问题修复处理规则)

**第一性原理：修问题先出方案，确认后再动手。**

接到以下类型需求时，**禁止直接发补丁、禁止只给临时修复**：
- 问题修复（Bug Fix）
- 漏洞整改（Security Fix）
- 功能纠错（Behavior Correction）

**必须执行的流程**：
1. **诊断根因**：分析问题本质，定位根本原因而非表象。
2. **输出完整解决方案**：包括修复思路、影响范围、回归风险。
3. **多方案择优**：若存在多种解决路径，逐一列出并筛选最优方案，清晰说明选择理由（性能、稳定性、兼容性、可维护性等维度）。
4. **等待用户确认**：方案经用户审阅同意后，再进行落地修复。

未经确认的修复一律不得提交。

### B.5 State File Isolation
- Global: `docs/omnidev-state/` (`00-project-context.md`, `metrics.json`, `config.json`)
- Branch-specific: `docs/omnidev-state/[branch-name]/` (`01-blueprint.md`, `02-plan.md`, `03-progress.md`, `04-design.md`, `05-test-report.md`, `06-release-notes.md`)

### B.6 Numbered Quick-Select

At **every checkpoint** where the user needs to choose an action, present options as a **numbered list** in the current `locale` language. The user can reply with:
- The **number** (e.g. `1`, `2`, `3`)
- The **short alias** (e.g. `/od n`)
- The **full command** (e.g. `/od next`)

All three forms are equivalent. The AI must parse number replies and map them to the corresponding action.

**Format template** for all checkpoints (use the column matching current `locale`):

| # | zh | en | Alias |
|---|----|----|-------|
| 1 | 继续下一阶段 | Continue to next phase | `/od n` |
| 2 | 修订当前输出 | Revise current output | `/od ad` |
| 3 | 跳过某阶段 | Skip a phase | `/od sk` |
| 4 | 返回某阶段 | Go back to a phase | `/od bk` |
| 5 | 执行所有剩余阶段 | Execute all remaining phases | `/od al` |

Header line: zh → `请选择下一步操作：` / en → `Choose next action:`

**Rules**:
- Numbers are **context-dependent** — each checkpoint defines its own numbered menu (Phase Exit has 5 options, Push has 3 options, etc.).
- If the user replies with a number that is out of range, ask them to choose again.
- Always show the short alias in parentheses next to each option so the user learns the shortcuts over time.
- **When `interactive_mode` is `true`** (see §B.8): Replace the numbered text list with the **AskQuestion** tool (structured choice UI). The user clicks an option instead of typing a number or command. This saves a request round-trip and reduces token usage.
- All option labels in the AskQuestion tool or text prompts must match the current `locale`.

### B.7 Lazy Context Loading

**Principle**: Do NOT read all state files or scan the entire project upfront. Each phase and command declares exactly what context it needs (see §E Phase Context Requirements). On entering a phase:

1. **Read only the files listed** in that phase's `context_requires` block.
2. **Skip files that don't exist** — their absence is informational (e.g. no `00-project-context.md` means onboard hasn't run; trigger §C.1 stack detection instead).
3. **Cache across phases within the same session** — if a file was already read in a previous phase of the current session, reuse it unless the phase explicitly says `reload: true`.
4. **Never pre-read** downstream phase artifacts (e.g. don't read `05-test-report.md` during Phase 2).
5. **Project scanning is gated**: full codebase scans (Grep, Glob, SemanticSearch) are only permitted when the phase's context block includes `scan: [target]`. Otherwise, operate on the files already known from state files or prior phases.

This keeps token usage proportional to the current phase's actual needs, not the total project size.

### B.8 Configuration (`config.json`)

OmniDev stores user preferences in `docs/omnidev-state/config.json`. If the file does not exist, treat all settings as their defaults.

```json
{
  "interactive_mode": true,
  "ask_mode_after_od": true,
  "locale": "zh",
  "update_source_url": "https://github.com/zy-eagle/omnidev-kit.git"
}
```

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `interactive_mode` | boolean | `true` | When `true`, use the **AskQuestion** tool to present structured choice UIs at decision points instead of numbered text prompts. Saves requests and tokens. |
| `ask_mode_after_od` | boolean | `true` | When `true`, enter a **Q&A loop** after every `/od` command — present actionable options and accept free-form input so the user stays in an interactive workflow with full tool access until `/od x`. |
| `locale` | string | `"zh"` | UI language for all user-facing output. `"zh"` = Chinese, `"en"` = English. Controls which language variant of phase/engine instruction files to load (`phases/{locale}/`, `engine/{locale}/`) and which language to use for checkpoints, prompts, and reports. |
| `update_source_url` | string | `"https://github.com/zy-eagle/omnidev-kit.git"` | Remote Git repository URL used by `/od up` to fetch the latest version. Written automatically during `/od install`. |

#### Config Commands

- **`/od cfg`** — Read and display current `config.json` (create with defaults if missing).
- **`/od cfg -i on`** — Set `interactive_mode` to `true` **and** `ask_mode_after_od` to `true`.
- **`/od cfg -i off`** — Set `interactive_mode` to `false` **and** `ask_mode_after_od` to `false`.
- **`/od cfg -l zh`** — Set `locale` to `"zh"` (Chinese mode).
- **`/od cfg -l en`** — Set `locale` to `"en"` (English mode).

### B.9 Interactive Mode

When `interactive_mode` is **`true`** (default) in `config.json`, the AI MUST use the **AskQuestion** tool (structured multiple-choice UI) at the following decision points instead of numbered text prompts:

| Decision Point | Questions Presented |
|----------------|-------------------|
| **Phase 0: Complexity Assessment** | Confirm/adjust complexity rating (S/M/L/XL); select which phases to include/skip |
| **Phase Checkpoint** (after each phase) | Choose next action: continue / adjust / skip / go back |
| **Change Management** (`/od ch`) | Confirm impact assessment: proceed / revise / cancel |
| **Push** (`/od ps`) | Confirm commit message: commit / edit message / cancel |
| **Learning Proposals** (`/od ln`) | For each proposal: adopt / reject / adjust |

When `interactive_mode` is **`false`**, use numbered text prompts as defined in §B.6. **Do not** use AskQuestion.

**On first `/od` activation in a session**: Read `docs/omnidev-state/config.json` (if it exists) to load `interactive_mode`, `ask_mode_after_od`, and `locale`. If the file does not exist, assume `interactive_mode` = `true`, `ask_mode_after_od` = `true`, `locale` = `"zh"` (defaults).

### B.10 Auto Q&A Loop (自动问答模式)

When `ask_mode_after_od` is **`true`** (default), the AI enters a **Q&A loop** after every `/od` command completes. Instead of silently stopping, it presents actionable options AND accepts free-form input, keeping the user in an interactive workflow with full tool access.

#### Trigger

After every `/od` command finishes its primary work (phase execution, help display, config change, push, review, learn, update, etc.), the AI MUST present the Q&A prompt as the **final action** of the response.

#### Q&A Prompt Format

Use the **AskQuestion** tool with `allow_multiple: false`.

When `locale` is `"zh"`, the question prompt should be `"✅ 任务已完成，请选择下一步操作："`.
When `locale` is `"en"`, the question prompt should be `"✅ Task complete. Choose next action:"`.

Options are **context-adaptive** — include only the ones relevant to the current state. Always include `other` and `exit`. Use the label matching the current `locale`:

| id | zh label | en label | When to show |
|----|----------|----------|-------------|
| `next_phase` | 继续下一阶段 (`/od n`) | Continue to next phase (`/od n`) | Workflow active with remaining phases |
| `adjust` | 修订当前输出 (`/od ad`) | Revise current output (`/od ad`) | Phase just completed |
| `review` | 代码审查 (`/od rv`) | Code review (`/od rv`) | Code written or modified |
| `test` | 运行测试 (`/od qa`) | Run tests (`/od qa`) | Code written or modified |
| `push` | 提交并推送 (`/od ps`) | Commit & push (`/od ps`) | Uncommitted changes exist |
| `learn` | 自学习与复盘 (`/od ln`) | Self-learning (`/od ln`) | M/L/XL task just finished |
| `report` | 生成周报 (`/od rp`) | Weekly report (`/od rp`) | Always (low priority) |
| `other` | 其他（直接输入指令或提问） | Other (type a command or question) | **Always** |
| `exit` | 结束本次任务 (`/od x`) | End this task (`/od x`) | **Always** |

> When `interactive_mode` is `false`, display the same applicable options as a numbered text list instead of AskQuestion.

#### Loop Behavior

- **User selects a preset option** → AI executes the corresponding `/od` command, then presents the Q&A prompt again.
- **User selects "Other"/"其他" or types free-form text** (question, instruction, or any non-`/od` input) → AI treats it as a **continuation of the OmniDev session** — OmniDev rules remain active, AI uses tools to fulfill the request, then presents the Q&A prompt again.
- **User selects "End"/"结束" or types `/od x`** → AI outputs a brief closing summary and stops. The Q&A loop ends.
- **User types a new `/od` command** → AI executes it normally, then the Q&A loop continues.

#### Rules

1. The Q&A prompt is always the **very last action** — after all output, checkpoints, and phase-specific AskQuestion calls.
2. Every response within the loop also ends with the Q&A prompt (the loop persists until explicit exit).
3. When `ask_mode_after_od` is **`false`**, skip the Q&A loop entirely. The AI completes the `/od` command and stops.
4. `/od cfg -i off` disables both `interactive_mode` and `ask_mode_after_od`. `/od cfg -i on` re-enables both.

### B.11 Dynamic Skill Composition (动态 Skill 组合)

When the user raises a **troubleshooting, debugging, error investigation, or problem diagnosis** request within an `/od` session, OmniDev acts as an **orchestrator** that dynamically discovers and loads specialized external skills rather than handling everything itself.

#### B.11.1 Trigger Detection

During Phase 0 (Complexity Assessment) or when processing any `/od` message, detect if the user's request matches a **troubleshooting/diagnosis intent** by checking for these signals:

| Signal Category | Keywords / Patterns |
|-----------------|---------------------|
| **Error investigation** | 报错, 500, 4xx, 5xx, 502, 503, 504, 异常, exception, error, failed, failure, crash, panic, 崩溃 |
| **Problem diagnosis** | 排查, 排障, troubleshoot, debug, diagnose, 定位问题, 查问题, 问题分析, root cause |
| **Log analysis** | 查日志, 看日志, 日志查询, log, logging, 错误日志, trace |
| **Behavior anomaly** | 不符预期, 不对, 应该是, 但实际, unexpected, 行为异常, 返回不正确 |
| **Ops / infra** | Pod, K8s, 容器, 实例, 部署失败, 服务挂了, 超时, timeout, OOM, 内存溢出 |
| **Fix request** | 修复, 修bug, fix, hotfix, patch, 漏洞, 修正, 纠错 |

**If none of these signals are detected**, proceed with the normal OmniDev workflow (Phase 0 → sizing → phases). **If signals are detected**, enter the Skill Discovery flow (§B.11.2).

#### B.11.2 Skill Discovery (本地 Skill 扫描)

Scan the following directories for `SKILL.md` files (using `Glob` tool with pattern `**/SKILL.md`):

| Scan Path | Priority | Description |
|-----------|----------|-------------|
| `.cursor/skills/` | 1 (highest) | Project-level skills |
| `~/.cursor/skills/` | 2 | User-level Cursor skills |
| `~/.claude/skills/` | 3 | User-level Claude skills |
| `~/.agents/skills/` | 4 | User-level agent skills |

**For each discovered `SKILL.md`**, read only the **YAML frontmatter** (`name` and `description` fields) — do NOT read the full file body. This keeps the scan lightweight.

#### B.11.3 Skill Matching & Ranking

Match the user's request against each discovered skill using a two-step process:

1. **Keyword Match**: Compare the user's request keywords against the skill's `description` field. Look for overlap in:
   - Domain terms (e.g. "troubleshoot", "排查", "日志", "log", "Pod", "K8s")
   - Service/product names mentioned by the user that appear in the skill description
   - Action verbs (e.g. "查", "分析", "排查", "fix")

2. **Category Classification**: Classify each matching skill into a relevance tier:

   | Tier | Condition | Example |
   |------|-----------|---------|
   | **Direct match** | Skill's `name` or `description` explicitly mentions troubleshooting/diagnosis AND matches the user's domain | `kdb-troubleshoot` for a KDB service error |
   | **Supporting** | Skill provides a capability needed during troubleshooting (e.g. log query, pod status) but is not a full troubleshooting workflow | `cloud-logging` for log queries, `sre-aiops-assistant` for pod/K8s checks |
   | **Irrelevant** | No meaningful overlap | `weekly-requirement-capture`, `sreweb-component-table` |

   Discard **Irrelevant** skills. Keep **Direct match** and **Supporting** skills.

#### B.11.4 User Confirmation (Mandatory)

**NEVER auto-load an external skill without explicit user confirmation.**

Present the discovered skills to the user using `AskQuestion` (if `interactive_mode` is `true`, `allow_multiple: true`) or numbered prompt (if `false`).

Prompt: zh → `"🔍 检测到问题排查/修复类需求，发现以下可用的专业 Skill："` / en → `"🔍 Troubleshooting/fix request detected. Found these specialized skills:"`

| id | zh label | en label |
|----|----------|----------|
| `skill_N` (per match) | 🎯 [name] — [desc] (直接匹配) | 🎯 [name] — [desc] (direct match) |
| `skill_N` (supporting) | 🔧 [name] — [desc] (辅助能力) | 🔧 [name] — [desc] (supporting) |
| `od_only` | 不加载外部 Skill，使用 OmniDev 内置流程处理 | Skip external skills, use OmniDev built-in flow |
| `cancel` | 取消，重新描述需求 | Cancel, let me rephrase my request |

**Rules**:
- **Direct match** skills are listed first with 🎯 prefix.
- **Supporting** skills are listed after with 🔧 prefix.
- Always include the `od_only` and `cancel` escape options.
- `allow_multiple: true` — the user may select a primary troubleshooting skill plus supporting skills (e.g. `kdb-troubleshoot` + `cloud-logging` + `sre-aiops-assistant`).
- **STOP — WAIT for user selection.** Do NOT proceed until the user confirms.

#### B.11.5 Skill Loading & Execution

After the user confirms which skills to load:

1. **Read the full `SKILL.md`** of each selected skill (now reading the body, not just frontmatter).
2. **Set execution context**: The loaded skill's rules and workflow take priority for the current troubleshooting task. OmniDev's core rules (B.1–B.4) remain active as baseline guardrails.
3. **Execute the loaded skill's workflow**: Follow its steps, checkpoints, and sub-document loading rules exactly as defined in that skill.
4. **Combine supporting skills on-demand**: If the user selected supporting skills (e.g. `cloud-logging`), invoke them as needed during the primary skill's execution — for example, when `kdb-troubleshoot` reaches its "查日志" step, use the `cloud-logging` skill's rules for the log query.

#### B.11.6 Return to OmniDev Workflow

When the external skill's workflow completes (user selects "end" or the skill reaches its final checkpoint):

1. **Summarize findings**: Output a brief summary of the troubleshooting results.
2. **Bridge back to OmniDev**: If the troubleshooting identified a code fix needed, present options via `AskQuestion`:

   Prompt: zh → `"🔧 排查完成。是否需要在 OmniDev 工作流中继续修复？"` / en → `"🔧 Troubleshooting complete. Continue with a fix in OmniDev?"`

   | id | zh label | en label |
   |----|----------|----------|
   | `fix_od` | 进入 OmniDev 开发流程修复问题 (`/od -f`) | Enter OmniDev dev flow to fix (`/od -f`) |
   | `fix_plan` | 先制定修复计划再动手 (`/od [修复需求]`) | Plan the fix first (`/od [fix requirement]`) |
   | `done` | 排查结束，无需修复 | Done, no fix needed |

3. If the user chooses to fix, seamlessly transition into the OmniDev development workflow with the troubleshooting findings as input context.

#### B.11.7 Skill Composition Constraints

- **Token budget**: Loading an external skill adds to context. If multiple skills are selected, load them lazily — only read a skill's full body when its workflow step is about to execute.
- **Conflict resolution**: If the external skill's rules conflict with OmniDev's core rules (B.1–B.4), OmniDev's core rules take precedence (they are safety guardrails).
- **No recursive composition**: An external skill loaded by OmniDev cannot itself trigger B.11 to load another skill. Only OmniDev acts as the orchestrator.
- **Session isolation**: External skill execution does not produce OmniDev state files (`02-plan.md`, `03-progress.md`, etc.). It only produces its own artifacts (if any). OmniDev state files are only written when the user returns to the OmniDev workflow.

---

## C. Phase Execution Protocol (Auto-Context Loading)

### C.0 Locale-Aware File Loading

**MANDATORY**: All phase and engine instruction files are organized by locale under `phases/{locale}/` and `engine/{locale}/`. On first `/od` activation, read `locale` from `config.json` (default: `"zh"`). Use this locale value to construct all file paths below.

**Path resolution**: Replace `{L}` with the current `locale` value (`zh` or `en`):

| Target Phase/Command | File to Read Immediately |
|----------------------|--------------------------|
| Phase 0 / `/od onboard` | `.cursor/skills/od/phases/{L}/00-assessment.md` |
| Phase 1 / Phase 2 | `.cursor/skills/od/phases/{L}/01-02-planning.md` |
| Phase 3 | `.cursor/skills/od/phases/{L}/03-development.md` |
| Phase 4 / `/od qa` | `.cursor/skills/od/phases/{L}/04-testing.md` |
| `/od push`, `/od change`, `/od report`, `/od compress` | `.cursor/skills/od/engine/{L}/special-flows.md` |
| `/od learn`, `/od ln` | `.cursor/skills/od/engine/{L}/evolution.md` |

**Rules**:
- **Load only ONE locale** — never load both `zh/` and `en/` files simultaneously. This avoids wasting tokens on redundant content.
- If the locale-specific file does not exist (e.g. user set `en` but the `en/` file is missing), fall back to the root-level file (e.g. `.cursor/skills/od/phases/00-assessment.md`) as a backward-compatible default.
- All user-facing output (checkpoints, prompts, reports, summaries) MUST use the language matching the current `locale`.

After reading the instruction file, follow its `context_requires` block to load project state files.

### C.1 Phase Exit — Checkpoint

After each phase completes, output in the language matching the current `locale`. Template (use the zh/en column per `locale`):

| Line | zh | en |
|------|----|----|
| Header | ✅ **Phase N 完成: [Name]** | ✅ **Phase N Complete: [Name]** |
| Artifacts | 产出物: [...] | Artifacts: [...] |
| Context | 已加载上下文: [...] | Context loaded: [...] |
| Progress | 📍 已完成: [...] ✅ \| 剩余: [...] ⏳ | 📍 Done: [...] ✅ \| Remaining: [...] ⏳ |
| Next | 🔜 **下一阶段: Phase N+1 — [Name]** | 🔜 **Next: Phase N+1 — [Name]** |
| Will load | 将加载: [...] | Will load: [...] |
| Will do | 将执行: [...] | Will execute: [...] |

**Phase 3 special rule**: When Phase 3 (Development) completes, the checkpoint MUST include the **Change Impact Summary** (defined in `03-development.md` §2) before the standard checkpoint output above. This ensures the user sees all modified files, affected features, and dependency/config changes before deciding the next step.

**If `interactive_mode` is `false`**: Display the numbered list above. Accept number (`1`–`5`), alias (`/od n`), or full command (`/od next`). **STOP — WAIT for user reply**.

**If `interactive_mode` is `true`** (default): Use **AskQuestion** tool to present the same options as a structured choice UI. **STOP — WAIT for user selection**.

---

## D. Project Type Awareness
- **Legacy**: Follow existing conventions 100%. No forced DDD/TDD. "Write code like a sensible veteran employee."
- **Greenfield**: Full modern conventions — OpenSpec / TDD / DDD, high test coverage, deployment manifests.

## E. MCP Integration
During Phase 3 & 4, proactively use available MCP servers:
- **Database MCP**: Verify table structures, insert mock data, check data flow.
- **Browser MCP (Playwright)**: Start server → visit page → E2E test → screenshot/DOM verification.
- **Discovery**: Check `.cursor/mcp.json` before complex tasks. If critical MCP missing, suggest installation.