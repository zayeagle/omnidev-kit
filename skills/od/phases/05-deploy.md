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

**Phase 5 core responsibility**: prepare **build + deploy scripts/manifests** so the project can be delivered in the selected mode(s).

| Project type | Core action |
|--------------|-------------|
| **Greenfield (new project)** | **Create** three default ready-to-use deploy mode scripts (see §1) |
| **Legacy (existing project)** | **Audit** existing assets; if missing/broken, **must get B.0 user consent** before adding or modifying |
| **Full pipeline mode** | When user explicitly requests the full pipeline, **autonomously complete** (add what is missing, fix what is broken); see §0 |

**Trigger**: L/XL complexity, or user explicitly requests deploy / Phase 5 / "complete the full pipeline".

**Entry gate** (all must pass):
- [ ] All tasks in `02-plan.md` marked `[x]`
- [ ] `05-test-report.md` **Gate Status: PASS** (or user B.0 CONFIRMED conditional)
- [ ] Required test layers executed per `05-test-plan.md`
- [ ] User confirmed Change Impact Summary from Phase 3

---

## §0 Deploy Autonomy Mode (modification permissions)

| Mode | Trigger | Legacy project behavior |
|------|---------|-------------------------|
| **conservative** (default) | Normal Phase 5 | On missing/broken → **STOP**, interactive prompt for consent before changing deploy/CI/Dockerfile/k8s |
| **full** | `/od al`, user says "complete the full pipeline / end-to-end delivery / fully automatic deploy", `config.deploy_autonomy: "full"` | **Autonomous completion**: add if missing, fix if broken, no per-item confirmation (still forbid unauthorized **production** execution) |

Log choice to `session-log.md` `## Key Decisions`: `deploy_autonomy: conservative|full`.

**Production deploy execution** remains **always** user-confirmed — even in `full` mode (B.0 for prod).

---

## §1 Default Deploy Modes + One-Click Entry (Greenfield must support)

For new projects (greenfield) or when legacy is missing assets under `full` mode, provide **three modes** by default + a **unified one-click entry** (`config.json` → `deploy_modes`, all three on by default).

### §1.0 One-Click Design Principle

**One-click deploy** = a **single command** from the repo root that completes "check → build → deploy/start", without manually chaining multiple scripts.

| Entry (priority) | Command example | Notes |
|------------------|-----------------|-------|
| **Makefile** (recommended, repo root) | `make deploy` / `make deploy-docker` / `make deploy-k8s` / `make deploy-binary` | Unified orchestration; `make deploy-help` lists usage |
| **Unified script** | `./deploy/deploy.sh docker\|k8s\|binary` | Called by Makefile internally |
| **package.json** (Node projects, supplemental) | `npm run deploy:docker`, etc. | Optional; must delegate to `deploy/deploy.sh` |

**Greenfield must deliver**:
1. Root **`Makefile`** — with `build`, `deploy`, `deploy-docker`, `deploy-k8s`, `deploy-binary`, `deploy-dry-run`, `deploy-help`
2. **`deploy/deploy.sh`** — mode router + preflight + calls per-mode one-click scripts
3. Per-mode **single-file one-click scripts** (see table below)

Each one-click script MUST:
- Be runnable from repo root (`cd` to root or use `ROOT=$(git rev-parse --show-toplevel)`)
- Support `--dry-run` (print steps only)
- Support `ENV=staging|production` (default staging; production needs explicit env or second confirmation)
- Preflight: required tools (docker/kubectl/go/node), required env vars
- On failure: `set -e` + clear error message + non-zero exit code
- End with a **Deploy Result** summary (mode, duration, access URL/port)

### §1.1 Mode Layout (three modes + one-click scripts)

| Mode | One-click script | Underlying assets | One-command effect |
|------|------------------|-------------------|--------------------|
| **docker** | `deploy/docker/deploy.sh` | `Dockerfile`, `docker-compose.yml` | build image → compose up -d → health check |
| **k8s** | `deploy/k8s/deploy.sh` | `deployment.yaml`, `service.yaml`, `configmap.yaml` | build+push (or load) → `kubectl apply` → rollout status |
| **binary** | `deploy/binary/deploy.sh` | embedded build | compile → install to `bin/` or systemd → start/restart |

Plus **`deploy/README.md`** — one-click command cheat sheet, env vars, rollback.

### §1.2 Root Makefile Template (required for Greenfield)

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

If a legacy project already has a Makefile: **append** the deploy targets above (in conservative mode, get user consent before changing).

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

**Legacy Makefile rule**: if a root Makefile already exists, prefer **extending deploy targets** that call `deploy/deploy.sh`; do not delete existing build/test targets.

### §1.5 Monorepo

Per affected `[pkg:name]`:
- `deploy/docker/<pkg>/deploy.sh`, `deploy/k8s/<pkg>/deploy.sh`, `deploy/binary/<pkg>/deploy.sh`
- Makefile: `make deploy PKG=<name> MODE=docker`

---

## §2 Legacy Project — Audit First (existing projects)

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
| **missing** or **broken** | **STOP** → interactive prompt per §2.2 — **do not** silently add/modify |
| User **declines** | Document gap in `06-release-notes.md` § Known Issues / Deferred; do NOT modify |

### §2.2 Consent prompt (legacy — required)

**MUST** invoke [interactive-prompt.md](../engine/interactive-prompt.md) §3.10 `deploy_consent` via §4/§5/§6 (same turn).

First output a ≤6-line issue summary, then show the popup:

| Option id | Meaning |
|-----------|---------|
| `apply_fix` | Add/modify as recommended (including Makefile) [default] |
| `docs_only` | Write release notes only; do not change the repo |
| `cancel` | Defer Phase 5 script changes |

**Destructive edits** (changing existing Makefile/Dockerfile/prod CI): extra `b0_confirm`; default **do not execute**. Do not use numbered prose "please choose: 1/2/3". **STOP — WAIT**.

### §2.3 Full pipeline mode

Skip §2.2 **per-item** consent only when `deploy_autonomy: full` or `/od al`. Still required:
- Phase-end `checkpoint` (B.8)
- Production execution `deploy_prod` (B.0)
- Destructive changes to existing prod CI/Dockerfile → extra `b0_confirm`

Deliver **one-click** deploy for all three modes + root Makefile. Log changes in release notes.

---

## Step 1: Build & One-Click Deploy Scripts

1. Determine `project_type` + `deploy_autonomy` from context
2. **Greenfield / full**:
   - Create root **`Makefile`** (§1.2)
   - Create **`deploy/deploy.sh`** router (§1.3)
   - Create **`deploy/{docker,k8s,binary}/deploy.sh`** one-click scripts (§1.1)
3. **Legacy / conservative**: Audit §2 only; modify Makefile/deploy after consent
4. **Node projects** (optional): `package.json` scripts delegate to `make deploy-*` — do not replace Makefile
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

### One-Click Commands (copy-paste ready)
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

**Default**: prepare scripts + docs only. **Do NOT** run production deploy without interactive confirm.

If user requests deploy to **staging/production**:

1. **MUST** invoke §3.10 `deploy_prod` (production) or use `b0_confirm` for staging as well (blocking) via §4/§5/§6 → **STOP — WAIT**
2. On `yes`: run **`make deploy-<mode>`** or `ENV=staging make deploy MODE=<mode>`
3. Post-deploy smoke: critical TC-IDs from `05-test-plan.md`
4. Record timestamp + mode + one-click command + result in `06-release-notes.md`

## Step 6: Metrics & Checkpoint

- `metrics.json` → `deploy` event with `deploy_modes`, `deploy_autonomy`
- **MUST** invoke §3.1 `checkpoint` (B.8) via §4/§5/§6 → **STOP — WAIT** (when options include `/od ps` semantics, use a label that points to `/od ps`)

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
| Greenfield: only docker, skip k8s/binary | Three one-click modes default |
| Legacy: overwrite Makefile without consent | Extend deploy targets after audit + consent |
| Prod deploy without user confirm | Scripts ok; prod needs explicit yes |
| full pipeline but skip broken k8s | Fix or stub + document in release notes |
