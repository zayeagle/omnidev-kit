# OmniDev Command Reference

All commands support **short aliases** (1-2 letters). Users can also reply with **numbers** (e.g. `1`, `2`, `3`) when presented with numbered options at any checkpoint.

## Core Commands

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

## Phase Navigation (阶段导航)

| Command | Alias | 说明 |
|---------|-------|------|
| `/od n` | `/od next` | 下一阶段 |
| `/od ad [内容]` | `/od adj` | 修订当前阶段输出 |
| `/od sk [阶段]` | `/od skip` | 跳过某个阶段 |
| `/od bk [阶段]` | `/od back` | 返回某个阶段 |
| `/od al` | `/od all` | 执行所有剩余阶段（不暂停） |

## Confirmation (确认操作)

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
