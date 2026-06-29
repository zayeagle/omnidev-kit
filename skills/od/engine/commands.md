# OmniDev Command Reference

→ Platform mapping: SKILL.md §F (Platform Abstraction Layer)

All commands support **short aliases** (1–2 letters). Users may reply with **numbers** at checkpoints.

## Core Commands

| Command | Alias | 说明 |
|---------|-------|------|
| `/od [需求]` | — | 引导式工作流：评估 → 推荐阶段 → 可跳过 |
| `/od -f [需求]` | — | 快速模式：跳过蓝图/计划，直接开发（S 级确认规则） |
| `/od -p [需求]` | — | 仅规划：蓝图 + 计划，不写代码 |
| `/od h` | `/od help` | 显示所有命令 |
| `/od ob` | `/od onboard` | 扫描项目，生成上下文文档 |
| `/od rp` | `/od report` | 生成周报 |
| `/od gv` | `/od governance` | AI 治理与成本审计（手工触发） |
| `/od gv --scope <...>` | — | phase0–5 / learning / cost / compliance / quality |
| `/od gv --since <7d\|14d\|30d\|90d>` | — | 审计时间窗口（默认 14d） |
| `/od rv` | `/od review` | 代码审查（只读） |
| `/od qa` | — | 测试阶段快捷入口（Phase 4） |
| `/od ch [新需求]` | `/od change` | 需求变更管理 |
| `/od ln` | `/od learn` | 自学习：错误回顾 + 规则演化 |
| `/od ln -r` | — | 查看学习日志和待处理提案 |
| `/od ln -a` | — | 自动应用所有待处理提案 |
| `/od ln --rb [N]` | — | 回滚第 N 条演化 |
| `/od up` | `/od update` | 更新 OmniDev Kit |
| `/od i <url>` | `/od install` | 从 Git 仓库安装 |
| `/od ps` | `/od push` | 提交并推送（需用户确认） |
| `/od st` | `/od stash` | 暂存任务上下文 |
| `/od po` | `/od pop` | 恢复暂存上下文 |
| `/od sy` | `/od sync` | 同步到 GitHub Issue / Jira |
| `/od db` | `/od dashboard` | 生成效率 ROI 面板 |
| `/od re` | `/od resume` | 恢复上次会话 |
| `/od cfg` | `/od config` | 查看配置 |
| `/od cfg -i on\|off` | — | 开关交互模式 |

## Phase Navigation

| Command | Alias | 说明 |
|---------|-------|------|
| `/od n` | `/od next` | 下一阶段 |
| `/od ad [内容]` | `/od adj` | 修订当前阶段输出 |
| `/od sk [阶段]` | `/od skip` | 跳过阶段（0–5） |
| `/od bk [阶段]` | `/od back` | 返回阶段 |
| `/od al` | `/od all` | 执行剩余阶段（减少中间确认，仍遵守 B.15 安全确认） |

## Confirmation

Interactive confirmations use the platform native prompt mechanism (SKILL.md §F.2). In text-only/CLI mode, users reply with command aliases (e.g., `y`, `n`, `ad`).

| Command | Alias | 说明 |
|---------|-------|------|
| `/od y` | `/od confirm` | 确认当前操作 |
| `/od x` | `/od cancel` | 取消 / 结束会话 |
| `/od em [msg]` | — | 修改提交信息（`/od ps` 流程） |
| `/od ln y` | — | 接受所有学习提案 |
| `/od ln y [N,N]` | — | 接受指定编号提案 |
| `/od ln x` | — | 拒绝所有提案 |
| `/od ln ad [N] [反馈]` | — | 调整指定提案 |

## Config Options (`config.json`)

| Key | Default | 说明 |
|-----|---------|------|
| `interactive_mode` | `true` | 平台交互提示（见 §F.2） |
| `ask_mode_after_od` | `true` | `/od` 后进入问答模式 |
| `update_source_url` | kit repo URL | `/od up` 源 |
| `auto_checkpoint` | `false` | Phase 3 前 git stash（非 commit） |
| `confirmation_level` | `"auto"` | `full` / `reduced` / `minimal` — B.15 |
| `coverage_gate` | `false` | 覆盖率未达标是否阻塞 |
| `sub_agents` | `"auto"` | `off` / `auto` / `on` — Sub-Agent 策略 |
| `design_split` | `true` | 设计 index + `features/*.md` |
| `log_token_estimates` | `true` | phase_exit 写入 metrics |
| `max_read_lines` | `150` | 单次 Read 行数上限 |
| `context_mode` | `"slim"` | `slim` / `standard` — 上下文占用策略 |
| `max_hot_lines` | `150` | HOT 层行数上限 |
| `max_resident_lines` | `300` | HOT+WARM 合计上限 |
| `checkpoint_max_lines` | `12` | Checkpoint 输出上限 |
| `platform_override` | `null` | 手动覆盖平台检测：`"cursor"`, `"claude_code"`, `"codex"`, `"cli_other"`, 或 `null` (自动) |
| `codex_compaction_multiplier` | `1.3` | Codex 平台 token 估算倍率（补偿 invisible compaction 开销） |
| `codex_conservative_occupancy` | `true` | Codex 平台是否启用防御性上下文占用策略 |
| `codex_thread_overhead_tokens` | `4000` | Codex 平台每个 sub-agent 线程的 token 开销 |
| `codex_max_turns_before_compress` | `15` | Codex 平台触发压缩的 turn 阈值（比默认 25 更保守） |
| `jira_base_url` | — | `/od sy` Jira（可选） |
| `jira_project_key` | — | Jira 项目键（可选） |

See [engine/context-occupancy.md](engine/context-occupancy.md), [engine/token-optimization.md](engine/token-optimization.md), [engine/metrics.md](engine/metrics.md), SKILL.md §F.8 (Codex compaction).
