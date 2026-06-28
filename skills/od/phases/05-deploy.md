# Phase 5 Instructions (Deploy & Release)

```yaml
context_requires:
  read:
    - 00-project-context.md          # stack, topology, stability_level, project_type
    - 02-plan.md                     # verify all tasks complete
    - 05-test-report.md              # test gate — must pass before deploy
    - 05-test-plan.md                # regression status
  scan:
    - Dockerfile, docker-compose*.yml, k8s/**/*.yaml, helm/**/*
    - .github/workflows/*, .gitlab-ci.yml, Jenkinsfile
    - package.json scripts, Makefile, deploy/
  scan_limit: 10
  skip:
    - 01-blueprint.md, 04-design.md  # upstream — essence in plan/report
  unload:
    - "Phase 4 instruction file (04-testing.md) full text"
    - "Phase 4 test runner raw outputs"
  summarize_before_exit:
    target: 06-release-notes.md
    discard_after_write:
      - "deploy script dry-run raw outputs"
    retain:
      - 06-release-notes.md
      - 05-test-report.md
      - metrics.json                 # updated with deploy event
```

## Overview

Phase 5 prepares the requirement for production delivery: deployment checklist, environment docs, release notes, and optional CI/CD verification. **Only run for L/XL complexity or when user explicitly requests deploy.**

**Entry gate** (all must pass):
- [ ] All tasks in `02-plan.md` marked `[x]`
- [ ] `05-test-report.md` shows no blocking failures
- [ ] User confirmed Change Impact Summary from Phase 3

---

## Step 1: Deployment Readiness Check

1. Read existing deploy manifests from scan results.
2. Compare against changes in `05-test-report.md` and Phase 3 impact summary.
3. Output readiness table:

| Check | Status | Notes |
|-------|--------|-------|
| DB migrations applied / documented | ✅/❌/N/A | |
| New env vars documented | ✅/❌/N/A | |
| Breaking API changes versioned | ✅/❌/N/A | |
| Rollback procedure defined | ✅/❌ | |
| CI pipeline green (if exists) | ✅/❌/N/A | |

**Project type adjustments**:
- **Legacy**: Reuse existing deploy pipeline; document deltas only.
- **Greenfield**: Generate or verify Dockerfile, CI workflow, health-check endpoint, deploy manifest stubs if missing.

**Monorepo**: Deploy per affected package/service. List each service separately in release notes with independent version tags if applicable.

---

## Step 2: Environment & Config Documentation

Append or update a `## Deployment` section in `06-release-notes.md` (or project `README` if user prefers):

```markdown
## Deployment

### Prerequisites
- [Runtime version, DB version, etc.]

### Environment Variables
| Variable | Required | Description | Default |
|----------|----------|-------------|---------|

### Deploy Steps
1. [Step-by-step for this project's existing pipeline]

### Rollback
1. [How to revert this release]
```

---

## Step 3: Release Notes → 06-release-notes.md

```markdown
---
version: [semver or date-based tag]
requirement_ref: [brief requirement ID or summary]
last_updated: [timestamp]
deploy_target: [staging | production | both]
test_report_ref: 05-test-report.md
---

# Release Notes: [Title]

## Summary
[1-3 sentences: what shipped and why]

## Changes
### Added
- [Feature / file / API]

### Changed
- [Modified behavior]

### Fixed
- [Bug fixes from this requirement]

### Removed / Deprecated
- [Breaking removals with migration path]

## API Changes
| Endpoint | Change Type | Migration |
|----------|-------------|-----------|

## Database Migrations
| Migration | Description | Rollback |
|-----------|-------------|----------|

## Test Summary
- Smoke: [N/N passed]
- Regression: [N/N passed]
- Link: `05-test-report.md`

## Known Issues
- [Issue] — [workaround or planned fix]

## Deployment Checklist
- [ ] Migrations run
- [ ] Env vars set
- [ ] Smoke test on staging
- [ ] Monitor alerts configured
```

---

## Step 4: Deploy Execution (Optional)

**Default**: Document-only. Do NOT run production deploy without explicit user request.

If user confirms deploy:
1. Run project's existing deploy command (from Makefile, CI, or documented script).
2. Post-deploy smoke: re-run critical TC-IDs from `05-test-plan.md`.
3. Record deploy timestamp and result in `06-release-notes.md`.

---

## Step 5: Metrics Update

Append deploy event to `metrics.json` per [engine/metrics.md](../engine/metrics.md) §2.

---

## Step 6: Checkpoint → WAIT

```
✅ Phase 5 Complete: Deploy & Release
📦 Outputs:
  - 06-release-notes.md — Release notes and deploy docs
📊 Progress: Phase 0 ✅ → … → Phase 4 ✅ → Phase 5 ✅
```

Present next-step options: Push (`/od ps`) / Sync to Issue (`/od sy`) / Done.

### Handoff Checklist (before WAIT)
- [ ] `06-release-notes.md` written and non-empty
- [ ] Deploy checklist complete or explicitly deferred with reason
- [ ] Session snapshot auto-saved (see session-memory.md §2)
- [ ] metrics.json updated with `deploy` event
