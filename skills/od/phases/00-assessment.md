# Phase 0 & Onboard Instructions
→ Platform mapping: SKILL.md §F (Platform Abstraction Layer)


## Context Requires

```yaml
context_requires:
  read:
    - 00-project-context.md          # cached stack info; may not exist
  scan:
    - package.json, go.mod, pom.xml  # only if 00-project-context.md missing
    - top-level directory listing     # quick ls for structure signals
  skip:
    - 01-blueprint.md, 02-plan.md, 03-progress.md, 04-design.md  # not yet created
  summarize_before_exit:
    target: 00-project-context.md
    discard_after_write:
      - "project scan tool outputs (package.json, go.mod reads, directory listings)"
    retain:
      - 00-project-context.md        # ❗ all downstream phases depend on this
      - "user's complexity/phase selection decisions"  # ❗ persist to session-log
  unload: []
```

## 1. Project Stack Detection (`/od onboard` or Phase 0 init)

Before sizing, scan the project once (results cached in `00-project-context.md` § Stack & Layers; re-scan only if missing):

1. **Frontend signals**: `package.json` (react, vue, next, etc.), `src/pages`, `vite.config.*`.
2. **Backend signals**: `go.mod`, `requirements.txt`, `pom.xml`, `package.json` (express, nestjs), `cmd/`, `internal/`.
3. **Classify**: `fullstack` | `frontend-only` | `backend-only` | `monorepo`.
4. **Dependency Topology Scan**:
   - Storage (DB, Cache, MQ, Search, S3): scan `config/*.yml`, `.env`, driver imports (`gorm`, `redis`, `kafka`).
   - Third-Party (HTTP APIs, gRPC, SDKs): scan `http.Client`, `axios`, `.proto`, AWS/Sentry SDKs.
5. **Stability Level**: `high` (if user requested high availability/stability) else `standard`.
6. Output to `docs/omnidev-state/00-project-context.md` (mark `project_type: legacy` or `greenfield`). Include `## Stack & Layers`, `## Dependency Topology`, and `## Stability Level`.

### Monorepo Detection

If multiple `package.json` / `go.mod` at subdirectories or workspace config (`pnpm-workspace.yaml`, `lerna.json`, `go.work`):
- Set `project_structure: monorepo`
- List packages/services in `## Stack & Layers` with paths
- Phase 2+ tasks must tag affected package: `[pkg:web]`, `[pkg:api]`, etc.

### Project Type Guidance

| Type | Phase 0 behavior |
|------|------------------|
| **Legacy** | Scan existing conventions; recommend minimal new dependencies |
| **Greenfield** | Recommend OpenSpec/TDD structure; suggest CI + coverage from start |

---

## 2. Phase 0: Complexity Assessment (T-Shirt Sizing)

- **S**: Skip blueprint/plan → Dev → Test directly.
- **M**: Skip blueprint → Plan → Dev → Test.
- **L/XL**: Full workflow: Blueprint → Plan → Dev → Test → Deploy.

**Output format:**

```markdown
## OmniDev Phase 0: Requirement Analysis & Complexity Assessment
**Requirement Analysis**: [1-2 sentences]
**Project Structure**: [fullstack | frontend-only | backend-only | monorepo] — frontend: [fw/none], backend: [fw/none]
**Complexity Assessment**: [S/M/L/XL] — [reason]
**Stability Level**: [standard | high] — [reason]
**Frontend Impact**: [yes — frontend changes needed | no — backend-only change | n/a]
**Recommended Strategy**: [phases]
**Confirmation Level**: [full | reduced | minimal] — per B.15
```

**If `interactive_mode` is `true`**: Use the platform interactive prompt (§F.2) to let the user confirm/adjust complexity and select phases to execute.

### S-Level Tasks

- Do NOT generate full state files (`02-plan.md`, etc.).
- **Still write**: minimal `session-log.md` on exit (for `/od re`) and `metrics.json` event if user opts to track.
- Resolve requirement directly; offer optional lightweight progress note in conversation only.

---

## Sub-Agent Dispatch (per `sub_agents` in config.json)

| Mode | Phase 0 |
|------|---------|
| **off** | Main agent scans directly |
| **auto** (default) | 1 explorer only if monorepo; else main agent |
| **on** | 2 explorers (stack + topology) |

→ [token-optimization.md](../engine/token-optimization.md) §2

### Handoff Checklist (before WAIT)

- [ ] All state files for this phase written to disk and non-empty: `00-project-context.md` (except S-level)
- [ ] Next phase's context_requires.read files all exist on disk (pre-check)
- [ ] Session snapshot auto-saved (see session-memory.md §2)
- [ ] Key decisions recorded in state files (not just conversation history)
- [ ] metrics.json updated with requirement_start event (skip for S unless tracking enabled)
