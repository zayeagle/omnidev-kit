# OmniDev Kit

[English](README.md)

OmniDev Kit 是一个 AI 驱动的开发工作流工具包，将 AI 从「只会按指令敲代码的打字员」升级为**「懂成本控制、会做架构设计、能自己写测试、且永远不会忘事的高级研发工程师」**。

**支持 Cursor · Claude Code · Codex 三个平台** — 详见 [平台抽象层](skills/od/SKILL.md#f-platform-abstraction-layer-pal)。

## 架构总览

```
┌─────────────────────────────────────────────────────┐
│                   OmniDev (/od)                     │
│           编排层 & 核心规则 (多 Agent 适配)             │
│  ┌──────────┬──────────┬──────────┬──────────────┐  │
│  │ B.0      │ 上下文   │ 影响面   │ 交互模式      │  │
│  │ 不确定就问│ 生命周期 │ 分析确认 │ + 命令提示    │  │
│  └──────────┴──────────┴──────────┴──────────────┘  │
│                        │                             │
│  ┌─────────────────────▼───────────────────────────┐│
│  │         阶段引擎（按需加载 / 摘要替代 / 卸载）      ││
│  │  Phase 0 → Phase 1 → Phase 2 → Phase 3 → Ph.4  ││
│  │  评估       蓝图       计划       开发      测试   ││
│  └──────────────────────────────────────────────────┘│
│                        │                             │
│  ┌─────────────────────▼───────────────────────────┐│
│  │              记忆 & 持久化层                       ││
│  │  Session Memory │ User Preferences │ Stash/Pop  ││
│  └──────────────────────────────────────────────────┘│
│                        │                             │
│  ┌─────────────────────▼───────────────────────────┐│
│  │         动态 Skill 组合引擎 (B.9)                ││
│  │  识别意图 → 扫描本地 Skill → 用户确认              ││
│  │  → 加载执行 → 桥接回 OmniDev                      ││
│  └──────────────────────────────────────────────────┘│
│                        │                             │
│  ┌─────────────────────▼───────────────────────────┐│
│  │              自我进化引擎                          ││
│  │  观察 → 学习 → 提案 → 应用（需用户确认）            ││
│  └──────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────┘
```

## 支持平台

OmniDev Kit 内置 **平台抽象层 (PAL)**，自动适配各 Agent 的原生能力：

| 功能 | Cursor | Claude Code | Codex |
|------|:------:|:-----------:|:-----:|
| 斜杠命令 (`/od`) | ✅ 原生支持 | ✅ SKILL.md | ✅ SKILL.md |
| 交互式提示 | ✅ `AskQuestion` | ✅ `AskUserQuestion` | ✅ `request_user_input` (Plan 模式) / 文本回退 |
| Sub-Agent / 并行 Worker | ✅ 内置并行 | ✅ `Task` 工具 | ✅ 线程模型 (`create_thread` + `send_message_to_thread`) |
| Skill 发现 | ✅ `.cursor/skills/` | ✅ `.claude/skills/` | ✅ `~/.codex/skills/` |
| MCP 集成 | ✅ `.cursor/mcp.json` | ✅ `.claude/mcp.json` | ✅ `list_mcp_resources` + `read_mcp_resource` |
| 多选交互 | ✅ `allow_multiple` | ✅ `multiSelect` | ✅ 编号提示 + 逗号分隔回复 |
| 上下文压缩 | N/A | N/A | ✅ 自动压缩 — 防御性状态写入 (§F.8) |
| 平台检测 | 自动 | 自动 | 自动（支持 env/config 手动覆盖） |
| 状态文件 & 记忆 | ✅ 跨平台 | ✅ 跨平台 | ✅ 跨平台 |

详见: [SKILL.md §F](skills/od/SKILL.md#f-platform-abstraction-layer-pal)。

---

## 核心特色

### 1. 第一性原理 — 不确定就问，禁止自我发挥 (B.0)

**最高优先级规则，贯穿所有 phase、所有命令、所有决策点。**

在整个工作流中，凡遇到不确定、不清楚、有歧义、有多种可能的情况，一律停下来问用户确认。覆盖范围包括但不限于：需求分析、技术方案选择、代码风格判断、阶段跳过/保留、上下文卸载、依赖框架选择、代码删除/重构。

> 判断标准：如果你需要说"我假设..."、"我猜测..."、"应该是..."，那就说明你不确定——停下来问。

具体应用：
- **需求对齐**：需求模糊时必须确认核心诉求、最终目标、交付标准和本质问题。
- **问题修复**：Bug Fix / Security Fix 必须先输出完整方案，多方案择优，待用户确认后再动手。

### 2. 上下文生命周期管理 (B.5)

三层机制控制上下文膨胀，同时确保依赖链完整：

- **按需加载**：每个阶段通过 `context_requires` 声明所需文件，AI 只加载声明的文件。`scan_limit` 控制扫描上限。
- **摘要替代**：大文件（> 100 行）读取后提取关键信息；Grep 结果（> 20 条）只保留 Top 10；Shell 输出（> 50 行）提取关键行。
- **沉淀后卸载**：Phase 退出时将关键产出写入 state file（沉淀），然后标记原始工具输出为过期（卸载）。**State files 和用户决策永不卸载。**

依赖链保护：

```
Phase 0 → 00-project-context.md → Phase 1, 2, 3, 4（永不卸载）
Phase 2 → 02-plan.md            → Phase 3, 4（永不卸载）
Phase 3 → 03-progress.md        → Phase 4（永不卸载）
```

### 3. 跨会话记忆系统

三个记忆模块实现"永远不忘事"：

| 模块 | 文件 | 功能 |
|------|------|------|
| **Session Memory** (B.10) | `session-log.md` | 会话结束时自动生成摘要（目标、决策、进度、反馈），`/od re` 恢复时读取，实现断点续传 |
| **User Preferences** (B.11) | `user-preferences.md` | 被动采集行为模式（代码风格、阶段跳过习惯、输出详细程度），每次激活时轻量加载（≤ 30 行） |
| **Stash/Pop** (B.12) | `stash/` | 多任务切换：`/od st` 保存完整快照（state files + git stash），`/od po` 恢复并自动 `/od re` |

### 4. 轻量交互提示 (B.8)

每个阶段或命令执行完毕后，通过 **AskQuestion** 交互对话框直接呈现 **2-4 个最相关的下一步操作**，让用户一键选择即可继续：

- **精简聚焦**：不展示冗长的命令列表，只给出当前状态下最合理的下一步
- **上下文感知**：根据当前进度和状态智能推荐选项
- **零记忆负担**：用户无需记住任何命令，直接在对话框中选择

### 5. 动态 Skill 组合（B.9）

OmniDev 不是孤立的单体工具，而是一个**编排器**，能动态发现和组合专业 Skill：

- **自动检测**用户输入中的排查/调试/修复意图关键词。
- **扫描本地 Skill**：项目级 + 用户级（`.cursor/skills/`、`.claude/skills/`、`~/.cursor/skills/`、`~/.claude/skills/`、`~/.codex/skills/`、`~/.agents/skills/`）共 6 个目录。
- **分级匹配**：🎯 直接匹配 vs 🔧 辅助能力。
- **用户确认后才加载**（支持多选组合），**按需加载不浪费上下文**。

### 6. 项目类型感知与自适应约束

- **历史项目**：AI 像「懂事的老员工」，100% 遵循现有规范，禁止强行引入 DDD/TDD。
- **全新项目**：全面启用现代软件工程规范 — 规范驱动开发、TDD/DDD、高覆盖率测试。
- `/od onboard` 扫描时自动识别 fullstack / frontend-only / backend-only / monorepo。

### 7. 智能自适应调度（T-Shirt Sizing）

- **S**：直接修复，跳过蓝图/计划。
- **M**：跳过蓝图 → 计划 → 开发 → 测试。
- **L/XL**：完整流程：蓝图 → 计划 → 开发 → 测试 → 部署。

### 8. 谋定而后动的工程纪律

- **强制脑暴**：禁止听到需求就写代码，必须先思考边界、异常和用户体验。
- **开发前修改范围确认**：写代码前必须先分析当前架构、代码风格、调用链，明确修改边界和影响面，输出风险评估，**经用户确认后才能动手**。
- **开发后影响面确认**：每组任务完成后，对比实际变更与预定范围，标注偏差，**用户确认后才能继续**。
- **需求变更管理**（`/od ch`）：中途变更需求时自动输出影响评估，归档旧方案，生成新蓝图。
- **自动快照防错**：修改代码前强制 Git Commit 备份。

### 9. DevSecOps 与韧性编码

Phase 3 强制执行安全与韧性编码：
- **安全设计**：IDOR/BOLA 防护、注入防护、SSRF/CSRF 防护、敏感数据脱敏。
- **标准级别**：结构化错误响应、超时控制、优雅降级、入口校验。
- **高级别**（用户指定）：熔断器、退避重试、舱壁隔离、优雅降级、限流。

### 10. 质量保证 — 测试（Phase 4）

- **依赖拓扑映射**：写测试前先梳理所有存储/三方/微服务依赖。
- **Mock 策略分级**：接口 Mock → 内存假实现 → 容器桩 → HTTP 桩 → MCP 驱动。
- **场景覆盖矩阵**：正常路径、校验、冲突、依赖故障、安全（IDOR/SQLi）、并发。
- **系统级韧性测试**：网络延迟、超时、高并发（P99 < 200ms）、内存压力。
- **覆盖率门槛**：>= 90% 语句/分支覆盖率。

### 11. 全生命周期自学习引擎

- **持续阶段学习**：每个 Phase 退出时静默采集业务领域知识、架构模式、模块关系，自动积累到 `00-project-context.md` 的 `§ Domain Knowledge` 中。
- **复合效应**：完成 3-5 个需求后，AI 对项目的业务场景理解接近在项目组工作数月的工程师，Bug 定位速度大幅提升。
- **被动学习**：`/od` 会话中自动记录纠正、模式和错误修复。
- **智能提案**：信号积累到阈值时生成规则/技能改进提案。
- **用户掌控**：规则变更须通过 `/od ln` 明确批准；领域知识积累无需批准（观察性质，非处方性质）。
- **安全护栏**：不能削弱核心规则，可通过 `/od ln --rb [N]` 回滚。

### 12. 企业汇报与运维

- **一键周报**（`/od rp`）：结合 git 历史 + 状态文件生成汇报级周报。
- **AI 治理与成本审计**（`/od gv`）：手工触发，输出 Token/成本效率、流程合规、质量风险与改进优先级报告，支持 `--scope`、`--since` 参数。
- **推送流程**（`/od ps`）：修改影响总结 → 暂存 → 生成提交信息 → 推送。
- **效能账单**：每次交付后 ROI 指标追加到 `metrics.json`。
- **手动更新**（`/od up`）：预览差异后确认才应用，绝不自动覆盖。

## 指令速查表

### 核心命令

| 指令 | 别名 | 说明 |
|------|------|------|
| `/od [需求]` | — | 引导式工作流：评估复杂度 → 推荐阶段 |
| `/od -f [需求]` | — | 快速模式：跳过蓝图/计划，直接开发 |
| `/od -p [需求]` | — | 仅规划：只输出蓝图和计划，不写代码 |
| `/od h` | `/od help` | 显示所有命令 |
| `/od ob` | `/od onboard` | 扫描项目，生成上下文文档 |
| `/od gv` | `/od governance` | AI 治理与成本审计（手工触发） |
| `/od gv --scope <...>` | — | 指定审计范围（phase3 / learning / cost / compliance / quality 等） |
| `/od gv --since <7d\|14d\|30d\|90d>` | — | 指定审计时间窗口（默认 14d） |
| `/od rv` | `/od review` | 代码审查（只读） |
| `/od qa` | — | 依赖分析 → Mock → 场景覆盖 → 韧性测试 |
| `/od ch [新需求]` | `/od change` | 需求变更管理 |
| `/od ln` | `/od learn` | 自学习：回顾错误 + 提炼规则 + 演化提案 |
| `/od rp` | `/od report` | 生成周报 |
| `/od ps` | `/od push` | 提交并推送代码 |
| `/od re` | `/od resume` | 恢复上次中断的会话（读取 session-log） |
| `/od up` | `/od update` | 更新 OmniDev Kit |
| `/od i <url>` | `/od install` | 从远程 Git 仓库安装 |

### 会话管理

| 指令 | 别名 | 说明 |
|------|------|------|
| `/od st` | `/od stash` | 暂存当前任务（state files + git stash） |
| `/od po` | `/od pop` | 恢复暂存的任务并自动 resume |
| `/od x` | `/od cancel` | 结束当前会话（自动保存 session-log） |

### 阶段导航

| 指令 | 别名 | 说明 |
|------|------|------|
| `/od n` | `/od next` | 继续下一阶段 |
| `/od ad` | `/od adj` | 修订当前阶段输出 |
| `/od sk` | `/od skip` | 跳过某个阶段 |
| `/od bk` | `/od back` | 返回某个阶段 |
| `/od al` | `/od all` | 执行所有剩余阶段 |

### 配置

| 指令 | 说明 |
|------|------|
| `/od cfg` | 查看当前配置和用户偏好 |
| `/od cfg -i on\|off` | 开关交互模式 |

## 目录结构

```text
omnidev-kit/
├── INSTALL.md
├── README.md
├── README.zh-CN.md
├── rules/
│   ├── 01-omnidev-workflow.mdc         # Cursor 触发器（alwaysApply: false）
│   ├── 02-omnidev-workflow.claude.md   # Claude Code 触发器（alwaysApply: false）
│   └── 03-omnidev-workflow.codex.md    # Codex 触发器（alwaysApply: false）
├── scripts/
│   └── clean-cursor-state.ps1          # 工具脚本：清理 Cursor 状态
└── skills/
    └── od/
        ├── SKILL.md                    # 主规范 — 唯一真相源
        ├── phases/
        │   ├── 00-assessment.md        # Phase 0: 评估与 Onboard
        │   ├── 01-02-planning.md       # Phase 1-2: 蓝图与计划
        │   ├── 03-development.md       # Phase 3: 开发与 DevSecOps
        │   └── 04-testing.md           # Phase 4: 测试与收尾
        └── engine/
            ├── commands.md             # 命令参考表（按需加载）
            ├── context-protocol.md     # 卸载/转场/预算规则（按需加载）
            ├── evolution.md            # 自我进化引擎（按需加载）
            ├── governance.md           # AI 治理与成本审计（按需加载）
            ├── session-memory.md       # 会话记忆 + 恢复/退出流程
            ├── stash.md                # Stash/Pop 实现（按需加载）
            ├── skill-composition.md    # 动态 Skill 组合（按需加载）
            ├── special-flows.md        # Push/Change/Report/Update 流程
            └── user-preferences.md     # 用户偏好采集规则
```

## 快速开始

**方式一：通过远程仓库地址安装（推荐）**

```
/od install https://github.com/zayeagle/omnidev-kit.git
```

**方式二：从本地目录安装**

将 `INSTALL.md` 拖入 AI 助手对话框，说：「请帮我安装这个工具包」。AI 会自动检测你的平台（Cursor / Claude Code / Codex）并安装到正确路径。

### 各平台快速参考

| 平台 | 安装目标 | 激活方式 |
|------|---------|---------|
| **Cursor** | `.cursor/skills/od/` + `.cursor/rules/` | 对话中输入 `/od` |
| **Claude Code** | `.claude/skills/od/` 或 `~/.claude/skills/od/` | 对话中输入 `/od` |
| **Codex** | `~/.codex/skills/od/` | 对话中输入 `/od`。如自动检测失败，设置 `OMNIDEV_PLATFORM=codex` 或 `config.json` `platform_override: "codex"`。 |

安装后输入 `/od [你的需求]` 或 `/od ob`（项目扫描）开始。
