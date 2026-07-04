# OmniDev Kit

[English](README.md)

面向 **Cursor · Claude Code · Codex** 的 AI **工程化交付**工作流。以 **`/od`** 前缀激活（非 `/od` 消息不进入工作流）。

将 Agent 约束为：**评估 → 蓝图 → 设计计划 → 开发 → 测试 → 部署**，状态落盘、分层测试、一键部署、可断点续做。

## 工作流（Phase 0–5）

```
Phase 0 评估 → Phase 1 蓝图 → Phase 2 设计+计划 → Phase 3 开发 → Phase 4 测试 → Phase 5 部署
     按 S/M/L/XL 复杂度裁剪阶段（S 级可跳过蓝图/计划）
```

| 阶段 | 产出（`docs/omnidev-state/`） |
|------|-------------------------------|
| 0 | `00-project-context.md` |
| 1 | `01-blueprint.md` |
| 2 | `02-plan.md`、`04-design.md`、`features/*.md`、`05-test-plan.md` |
| 3 | 代码 + `03-progress.md` |
| 4 | `05-test-report.md`（门禁） |
| 5 | `06-release-notes.md`、`Makefile`、`deploy/**` 一键脚本 |

## 核心特色

- **B.0** — 不确定就问；删改/生产默认不擅自执行
- **弹窗优先** — 三端原生交互 + 结构化伪弹窗回退
- **文档历史** — 每个产出 `active` + `*-history.md` 双文件，可追溯演进
- **分层测试** — UNIT（阻塞）· INT · E2E（Playwright）· SMK（冒烟）· REG — 按复杂度与全栈信号自动组合
- **一键部署** — `make deploy` / docker · k8s · binary；历史项目先审计、改 deploy 须用户同意
- **上下文预算** — HOT+WARM ≤300 行；阶段指令按需加载
- **多 Agent** — 1 主编排 + L/XL 可选 Worker；交接只认 state 文件
- **跨会话** — `/od re`、`/od re [payload]`、stash/pop、治理审计 `/od gv`

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
