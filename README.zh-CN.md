# OmniDev Kit

[English](README.md)

OmniDev Kit 将 AI 从**「只会按指令敲代码的打字员」**升维为**「懂成本控制、会做架构设计、能自己写测试、且永远不会忘事的高级研发工程师」**。

以 **`/od`** 激活 — 一条有状态的交付链路，从意图到上线。不是普通闲聊。

## 工作流

```
评估 → 蓝图 → 设计+计划 → 开发 → 测试 → 部署
```

按 S/M/L/XL 自适应裁剪流程 — 小任务轻量快跑，大项目不失工程纪律。  
全部状态沉淀于 `docs/omnidev-state/` — 可审计、可续作、可交接。

## 你将获得

- **工程纪律** — 先想后写、变更先确认、过门才交付
- **持久记忆** — 会话恢复、偏好学习、任务暂存 — 上下文越用越厚
- **自适应严谨** — 大需求走全链路，小修复走快车道
- **质量到生产** — 分层测试、覆盖率门禁、发布说明、一键部署
- **持续进化** — 领域知识与工作流规则在你掌控下不断沉淀

## 常用命令

| 命令 | 说明 |
|------|------|
| `/od [需求]` | 启动工作流（Phase 0） |
| `/od -f [需求]` | 快速开发（S 级） |
| `/od ob` | 项目扫描 / Onboard |
| `/od n` / `/od ad` / `/od sk` | 阶段导航 |
| `/od re` / `/od re [payload]` | 恢复会话 |
| `/od ch` | 需求变更 + 文档同步 |
| `/od qa` | 测试阶段 |
| `/od ps` | 提交推送（需用户确认） |
| `/od al` | 执行剩余阶段 |
| `/od h` | 完整命令列表 |

配置：`docs/omnidev-state/config.json` · 交互开关：`/od cfg -i on|off`

## 仓库结构

```text
omnidev-kit/
├── INSTALL.md
├── README.md / README.zh-CN.md
├── rules/                    # Agent 触发规则
├── docs/omnidev-state/       # config.json、metrics 模板
└── skills/od/
    ├── SKILL.md              # 唯一规范源
    ├── phases/               # 00-assessment … 05-deploy
    └── engine/               # activation、test-strategy、document-history 等
```

运行时状态在 **业务项目** 内：`docs/omnidev-state/[branch]/`。

## 快速开始

```
/od install https://github.com/zayeagle/omnidev-kit.git
/od ob
/od [你的需求]
```

或将 [INSTALL.md](INSTALL.md) 拖入 AI 助手 — 自动检测环境并安装到正确路径。

## 文档

- [INSTALL.md](INSTALL.md) — 安装与配置
- [skills/od/SKILL.md](skills/od/SKILL.md) — 完整规范
- [skills/od/engine/commands.md](skills/od/engine/commands.md) — 全部命令
