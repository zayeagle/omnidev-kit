# OmniDev Kit

[English](README.md)

**软件开发 AI 指挥层**。以 **`/od`** 激活 — 不是普通对话。

将 AI 约束为可验证的工程交付链路：**评估 → 设计 → 计划 → 开发 → 测试 → 部署** — 状态落盘、门禁放行、开箱部署、断点续做。

## 工作流（Phase 0–5）

```
评估 → 蓝图 → 设计+计划 → 开发 → 测试 → 部署
```

状态与产出统一沉淀于 `docs/omnidev-state/` — 跨会话、跨 Agent、跨交接的唯一事实源。

## 核心特色

- **治理优先** — 关键决策人机共审，删改与生产默认不擅自执行
- **质量门禁** — 分层测试与阶段卡点，未过门不交付
- **开箱即部署** — 发布说明、脚本与一键路径，交付即上线
- **多 Agent 就绪** — 单一编排 + 可选 Worker，state 文件即交接契约
- **跨会话连续** — 暂停、恢复、需求演进，上下文不丢不散

## 平台支持（PAL）

| | Cursor | Claude Code | Codex |
|---|:---:|:---:|:---:|
| 触发 | `/od` 前缀 | `/od` 前缀 | `/od` 前缀 |
| 交互 | `AskQuestion` | `AskUserQuestion` | `request_user_input` + 回退 |
| 并行 | 内置 Worker | `Task` | `create_thread` |
| 安装 | `.cursor/skills/od/` | `.claude/skills/` | `~/.codex/skills/od/` |

详见 [SKILL.md §F](skills/od/SKILL.md#f-platform-abstraction-layer-pal)

## 常用命令

| 命令 | 说明 |
|------|------|
| `/od [需求]` | 启动工作流（Phase 0） |
| `/od -f [需求]` | 快速开发（S 级） |
| `/od ob` | 项目扫描 / Onboard |
| `/od n` / `/od ad` / `/od sk` | 阶段导航 |
| `/od re` / `/od re [payload]` | 恢复会话（可带变更/意图） |
| `/od ch` | 需求变更 + 文档同步 |
| `/od qa` | 测试阶段 |
| `/od ps` | 提交推送（需用户确认） |
| `/od al` | 执行剩余阶段（完整流水线部署权限） |
| `/od h` | 完整命令列表 |

配置：`docs/omnidev-state/config.json` · 交互开关：`/od cfg -i on|off`

## 仓库结构

```text
omnidev-kit/
├── INSTALL.md
├── README.md / README.zh-CN.md
├── rules/                    # 三端触发规则
├── docs/omnidev-state/       # config.json、metrics 模板
└── skills/od/
    ├── SKILL.md              # 唯一规范源
    ├── phases/               # 00-assessment … 05-deploy
    └── engine/               # activation、test-strategy、document-history 等
```

运行时状态在 **业务项目** 内：`docs/omnidev-state/[branch]/`。

## 快速开始

**安装**

```
/od install https://github.com/zayeagle/omnidev-kit.git
```

或将 [INSTALL.md](INSTALL.md) 交给 Agent，按平台自动安装。

**使用**

```
/od ob          # 首次：扫描项目
/od [你的需求]
```

| 平台 | 安装位置 |
|------|----------|
| Cursor | `.cursor/skills/od/` + `.cursor/rules/` |
| Claude Code | `.claude/skills/od/` 或 `~/.claude/skills/od/` |
| Codex | `~/.codex/skills/od/` |

**Codex Default 模式弹窗** — 在 `~/.codex/config.toml` 添加：

```toml
[features]
default_mode_request_user_input = true
```

## 文档

- [INSTALL.md](INSTALL.md) — 安装与配置模板
- [skills/od/SKILL.md](skills/od/SKILL.md) — 完整规则
- [skills/od/engine/commands.md](skills/od/engine/commands.md) — 全部命令
