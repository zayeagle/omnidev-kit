# Phase 5 Instructions (Deploy & Release)
→ Platform mapping: SKILL.md §F (Platform Abstraction Layer)


```yaml
context_requires:
  read:
    - 00-project-context.md          # project_type: legacy|greenfield, stack
    - 02-plan.md                     # verify all tasks complete
    - 05-test-report.md              # test gate — must pass before deploy
    - 05-test-plan.md                # regression / smoke TC-IDs
    - docs/omnidev-state/config.json # deploy_modes, deploy_autonomy
  scan:
    - Dockerfile, docker-compose*.yml, k8s/**/*.yaml, helm/**/*
    - .github/workflows/*, .gitlab-ci.yml, Jenkinsfile
    - package.json scripts, Makefile, deploy/, scripts/deploy/
    - "**/build.sh", "**/install.sh"
  scan_limit: 12
  skip:
    - 01-blueprint.md, 04-design.md
    - "*-history.md"
  unload:
    - "Phase 4 instruction file (04-testing.md) full text"
    - "Phase 4 test runner raw outputs"
  summarize_before_exit:
    target: 06-release-notes.md
    discard_after_write:
      - "deploy script dry-run raw outputs"
    retain:
      - 06-release-notes.md
      - deploy/ (or project deploy assets)
      - 05-test-report.md
      - metrics.json
```

---

## Overview — Core Responsibility

**Phase 5 核心职责**：准备 **构建 + 部署脚本/清单**，使项目可按选定模式交付。

| 项目类型 | 核心动作 |
|----------|----------|
| **Greenfield（新项目）** | **创建** 三套默认可用部署模式脚本（见 §1） |
| **Legacy（历史项目）** | **审计** 现有资产；缺失/有问题时 **必须 B.0 征得用户同意** 才能新增或修改 |
| **Full pipeline 模式** | 用户明确要求跑完整流水线时，**自主补齐**（该增增、该改改），见 §0 |

**触发条件**：L/XL 复杂度，或用户显式要求部署 / Phase 5 / 「完成整个流水线」。

**Entry gate** (all must pass):
- [ ] All tasks in `02-plan.md` marked `[x]`
- [ ] `05-test-report.md` **Gate Status: PASS** (or user B.0 CONFIRMED conditional)
- [ ] Required test layers executed per `05-test-plan.md`
- [ ] User confirmed Change Impact Summary from Phase 3

---

## §0 Deploy Autonomy Mode（修改权限）

| Mode | 触发 | Legacy 项目行为 |
|------|------|-----------------|
| **conservative**（默认） | 常规 Phase 5 | 发现缺失/错误 → **STOP**，interactive prompt 征得同意后才能改 deploy/CI/Dockerfile/k8s |
| **full** | `/od al`、用户说「完成整个流水线/端到端交付/全自动部署」、`config.deploy_autonomy: "full"` | **自主完成**：缺失则新增，有问题则修复，无需逐项确认（仍禁止未授权 **生产** 执行） |

Log choice to `session-log.md` `## 关键决策`: `deploy_autonomy: conservative|full`.

**Production deploy execution** remains **always** user-confirmed — even in `full` mode (B.0 for prod).

---

## §1 Default Deploy Modes + One-Click Entry（Greenfield 必须支持）

新项目（greenfield）或 `full` 模式下 legacy 缺失时，默认提供 **三种模式** + **统一一键入口**（`config.json` → `deploy_modes`，默认三项全开）。

### §1.0 One-Click Design Principle

**一键部署** = 仓库根目录 **单条命令** 完成「检查 → 构建 → 部署/启动」，无需手动串联多步脚本。

| 入口（优先级） | 命令示例 | 说明 |
|----------------|----------|------|
| **Makefile**（推荐，根目录） | `make deploy` / `make deploy-docker` / `make deploy-k8s` / `make deploy-binary` | 统一编排；`make deploy-help` 列出用法 |
| **统一脚本** | `./deploy/deploy.sh docker\|k8s\|binary` | Makefile 内部调用此脚本 |
| **package.json**（Node 项目补充） | `npm run deploy:docker` 等 | 可选；须 delegate 到 `deploy/deploy.sh` |

**Greenfield 必须交付**：
1. 根目录 **`Makefile`** — 含 `build`, `deploy`, `deploy-docker`, `deploy-k8s`, `deploy-binary`, `deploy-dry-run`, `deploy-help`
2. **`deploy/deploy.sh`** — 模式路由 + 预检 + 调用子模式一键脚本
3. 各模式 **单文件一键脚本**（见下表）

每个一键脚本 MUST：
- 从仓库根目录可执行（`cd` 到根或使用 `ROOT=$(git rev-parse --show-toplevel)`）
- 支持 `--dry-run`（只打印将执行的步骤）
- 支持 `ENV=staging|production`（默认 staging；production 需显式 env 或二次确认）
- 预检：依赖工具（docker/kubectl/go/node）、必需 env var
- 失败时 `set -e` + 明确错误信息 + 非零退出码
- 末尾输出 **Deploy Result** 摘要（模式、耗时、访问 URL/端口）

### §1.1 Mode Layout（三种模式 + 一键脚本）

| Mode | 一键脚本 | 底层资产 | 一条命令效果 |
|------|----------|----------|--------------|
| **docker** | `deploy/docker/deploy.sh` | `Dockerfile`, `docker-compose.yml` | build 镜像 → compose up -d → health check |
| **k8s** | `deploy/k8s/deploy.sh` | `deployment.yaml`, `service.yaml`, `configmap.yaml` | build+push（或 load）→ `kubectl apply` → rollout status |
| **binary** | `deploy/binary/deploy.sh` | 内嵌 build | compile → 安装到 `bin/` 或 systemd → 启动/重启 |

Plus **`deploy/README.md`** — 一键命令速查、环境变量、回滚。

### §1.2 Root Makefile Template（Greenfield 必含）

```makefile
.PHONY: build deploy deploy-docker deploy-k8s deploy-binary deploy-dry-run deploy-help

deploy-help:
	@echo "One-click deploy:"
	@echo "  make deploy MODE=docker|k8s|binary  (default: docker)"
	@echo "  make deploy-docker | deploy-k8s | deploy-binary"
	@echo "  make deploy-dry-run MODE=..."

build:
	@./deploy/deploy.sh $(MODE) --build-only

deploy:
	@./deploy/deploy.sh $(or $(MODE),docker)

deploy-docker:
	@./deploy/deploy.sh docker

deploy-k8s:
	@./deploy/deploy.sh k8s

deploy-binary:
	@./deploy/deploy.sh binary

deploy-dry-run:
	@./deploy/deploy.sh $(or $(MODE),docker) --dry-run
```

Legacy 项目若已有 Makefile：**追加**上述 deploy targets（conservative 模式须用户同意后再改）。

### §1.3 Unified Router — `deploy/deploy.sh`

```bash
#!/usr/bin/env bash
# Usage: ./deploy/deploy.sh [docker|k8s|binary] [--dry-run] [--build-only]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-docker}"
exec "$ROOT/deploy/$MODE/deploy.sh" "${@:2}"
```

### §1.4 Stack-specific behavior

Adapt scripts to `00-project-context.md` stack:

| Stack | docker | k8s | binary |
|-------|--------|-----|--------|
| Node | multi-stage Dockerfile, `npm run build` | Deployment + Service + probes | `npm run build` → dist + node start |
| Go | scratch/alpine binary in Docker | Deployment + liveness/readiness | `go build -o bin/app` |
| Python | gunicorn/uvicorn image | same pattern | venv + gunicorn |
| Fullstack | frontend static + API container or compose 2 services | separate deployments or single chart | API binary + static serve |

**Legacy Makefile rule**: 若根目录已有 Makefile，优先 **扩展 deploy targets** 调用 `deploy/deploy.sh`；不要删除现有 build/test targets。

### §1.5 Monorepo

Per affected `[pkg:name]`:
- `deploy/docker/<pkg>/deploy.sh`, `deploy/k8s/<pkg>/deploy.sh`, `deploy/binary/<pkg>/deploy.sh`
- Makefile: `make deploy PKG=<name> MODE=docker`

---

## §2 Legacy Project — Audit First（历史项目）

**Before any write**, scan and output **Deploy Asset Audit**:

```markdown
## Deploy Asset Audit

| Asset | Path | Status | Issue |
|-------|------|--------|-------|
| **Makefile** | ./Makefile | ✅/❌/⚠️ | deploy targets present? |
| **One-click router** | deploy/deploy.sh | ✅/❌ | unified entry |
| Dockerfile | ./Dockerfile | ✅ ok | — |
| docker one-click | deploy/docker/deploy.sh | ✅/❌ | |
| docker-compose | — | ❌ missing | no compose file |
| k8s one-click | deploy/k8s/deploy.sh | ✅/❌ | |
| k8s manifests | deploy/k8s/ | ⚠️ partial | no Service |
| binary one-click | deploy/binary/deploy.sh | ✅/❌ | |
| CI deploy job | .github/workflows/deploy.yml | ⚠️ broken | no push step |

**deploy_modes_coverage**: docker ✅ | k8s ❌ | binary ❌
**one_click_ready**: make deploy ✅/❌ | ./deploy/deploy.sh ✅/❌
**Recommended action**: [add k8s stubs | fix Service | ...]
```

### §2.1 Conservative mode (default)

| Audit result | Action |
|--------------|--------|
| Asset **ok** | Document only; reuse in release notes |
| **missing** or **broken** | **STOP** → interactive prompt per §2.2 — **禁止** silent add/modify |
| User **declines** | Document gap in `06-release-notes.md` § Known Issues / Deferred; do NOT modify |

### §2.2 Consent prompt (legacy — required)

```
发现部署资产问题：
1. [问题摘要]
建议：[新增 Makefile deploy targets + deploy/deploy.sh | 新增 deploy/k8s/deploy.sh ...]

请选择：
1. 同意 — 按建议新增/修改（含 Makefile）[默认]
2. 仅文档 — 只写 release notes，不改仓库
3. 取消 —  defer Phase 5 脚本变更
```

**Destructive edits** (change existing Makefile targets, Dockerfile, prod CI): mark `[需确认]`; default **不执行** per B.0.

### §2.3 Full pipeline mode

Skip §2.2 per-item prompts. Deliver **one-click** deploy for all three modes + root Makefile. Log all changes in release notes § Changes → Infrastructure.

---

## Step 1: Build & One-Click Deploy Scripts

1. Determine `project_type` + `deploy_autonomy` from context
2. **Greenfield / full**:
   - Create root **`Makefile`** (§1.2)
   - Create **`deploy/deploy.sh`** router (§1.3)
   - Create **`deploy/{docker,k8s,binary}/deploy.sh`** one-click scripts (§1.1)
3. **Legacy / conservative**: Audit §2 only; modify Makefile/deploy after consent
4. **Node 项目**（可选）：`package.json` scripts delegate to `make deploy-*` — 不替代 Makefile
5. Run **`make deploy-dry-run MODE=docker`** (and k8s/binary if applicable); record in readiness table

---

## Step 2: Deployment Readiness Check

| Check | Status | Notes |
|-------|--------|-------|
| **Makefile** deploy targets exist | ✅/❌ | `make deploy-help` works |
| **deploy/deploy.sh** router | ✅/❌ | |
| docker **one-click** dry-run ok | ✅/❌/N/A | `make deploy-dry-run MODE=docker` |
| k8s one-click dry-run ok | ✅/❌/N/A | `kubectl apply --dry-run=client` |
| binary one-click produces artifact | ✅/❌/N/A | |
| DB migrations documented | ✅/❌/N/A | |
| New env vars documented | ✅/❌/N/A | |
| Rollback procedure per mode | ✅/❌ | |
| CI pipeline references deploy (if exists) | ✅/❌/N/A | |

---

## Step 3: Environment & Config Documentation

Append `## Deployment` to `06-release-notes.md`:

```markdown
## Deployment

### One-Click Commands（复制即用）
```bash
make deploy-help
make deploy                    # default docker
make deploy-docker
make deploy-k8s
make deploy-binary
make deploy-dry-run MODE=k8s
./deploy/deploy.sh docker --dry-run
```

### Supported Modes
| Mode | One-click | Target |
| docker | `make deploy-docker` | local / VM |
| k8s | `make deploy-k8s` | cluster |
| binary | `make deploy-binary` | local binary |

### Prerequisites
### Environment Variables
### Deploy Steps (per mode)
### Rollback (per mode)
```

---

## Step 4: Release Notes → `06-release-notes.md`

Archive previous to `06-release-notes-history.md` if replacing ([document-history.md](../engine/document-history.md)).

Include:
- Infrastructure **Added/Changed** (new deploy scripts, k8s, Dockerfile)
- `deploy_modes`: which modes delivered
- Test summary link
- Deployment checklist per mode

---

## Step 5: Deploy Execution (Optional)

**Default**: prepare scripts + docs only. **Do NOT** run production deploy without explicit user request.

If user confirms **target environment** (staging/production):
1. Run **`make deploy-<mode>`** or `ENV=staging make deploy MODE=<mode>`
2. Post-deploy smoke: critical TC-IDs from `05-test-plan.md`
3. Record timestamp + mode + one-click command + result in `06-release-notes.md`

---

## Step 6: Metrics & Checkpoint

- `metrics.json` → `deploy` event with `deploy_modes`, `deploy_autonomy`
- Checkpoint → `/od ps` / `/od sy` / Done

### Handoff Checklist

- [ ] Greenfield: **Makefile** + `deploy/deploy.sh` + **docker/k8s/binary one-click** scripts
- [ ] `make deploy-help` and `make deploy-dry-run` succeed (or documented N/A)
- [ ] Legacy conservative: no deploy file changed without user consent
- [ ] Legacy full / greenfield: audit gaps resolved or documented
- [ ] `deploy/README.md` + `06-release-notes.md` non-empty
- [ ] metrics.json updated

---

## Anti-Patterns

| ❌ | ✅ |
|----|-----|
| Legacy: silently rewrite Dockerfile | Audit → consent → change |
| Multi-step manual deploy chain | **One-click** `make deploy-*` |
| Greenfield without Makefile | Root **Makefile** required |
| Legacy: overwrite Makefile without consent | Extend deploy targets after audit + consent |
| Prod deploy without user confirm | Scripts ok; prod needs explicit yes |
| full pipeline but skip broken k8s | Fix or stub + document in release notes |
