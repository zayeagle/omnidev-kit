# Metrics Collection (`metrics.json`)

**Path**: `docs/omnidev-state/metrics.json` (global, not per-branch)

**Purpose**: Event log for governance (`/od gv`), dashboard (`/od db`), and token tracking. See [token-optimization.md](token-optimization.md) for estimation rules.

---

## 1. Schema

```json
{
  "schema_version": 2,
  "last_updated": "2026-06-28T12:00:00Z",
  "requirements": [
    {
      "id": "req-2026-06-28-auth",
      "branch": "feature/auth",
      "complexity": "M",
      "started_at": "2026-06-28T10:00:00Z",
      "completed_at": null,
      "phases_completed": ["0", "2", "3"],
      "phases_skipped": ["1"],
      "tasks_total": 8,
      "tasks_completed": 5,
      "test_pass_rate": null,
      "deployed": false,
      "rework_count": 0,
      "confirmations_skipped": 0,
      "estimated_tokens_total": 12400,
      "sub_agents_spawned_total": 0
    }
  ],
  "events": [
    {
      "ts": "2026-06-28T10:00:00Z",
      "type": "phase_exit",
      "phase": 2,
      "branch": "feature/auth",
      "requirement_id": "req-2026-06-28-auth",
      "estimated_lines_loaded": 320,
      "estimated_tokens": 4800,
      "estimated_cost_tier": "medium",
      "sub_agents_spawned": 0,
      "confirmations_count": 1
    }
  ],
  "aggregates": {
    "total_requirements": 1,
    "avg_tasks_per_requirement": 8,
    "avg_tokens_per_requirement": 12400,
    "phase_skip_rate": { "1": 1.0 },
    "test_pass_rate_avg": null
  }
}
```

If file does not exist, create with `schema_version: 2`, empty arrays on first `/od` activation.

---

## 2. Write Triggers (Silent)

| Event | When | Fields Updated |
|-------|------|----------------|
| `requirement_start` | Phase 0 complete | New `requirements[]` entry |
| `phase_exit` | Each phase checkpoint | `phases_completed`, `events[]`, token fields if `log_token_estimates` |
| `phase_skip` | User skips phase | `phases_skipped`, `events[]` |
| `task_complete` | Task `[x]` in `02-plan.md` | `tasks_completed` |
| `test_complete` | Phase 4 checkpoint | `test_pass_rate` |
| `deploy` | Phase 5 checkpoint | `deployed: true` |
| `rework` | Same file 3+ edits in Phase 3 | `rework_count` |
| `learning_applied` | `/od ln` applies proposal | `events[]` |
| `compress` | `/od compress` executed | `events[]`; include `hot_lines_before/after` if occupancy §9 |
| `occupancy_guard_triggered` | context-protocol §12 breach | `events[]` |
| `resume_cold_start` | `/od re` entry | `events[]` |

**Retention**: Last 50 requirements, 200 events. Archive overflow to `archive/metrics-archive-[date].json`.

---

## 3. Token Estimation

When `config.json` → `"log_token_estimates": true` (default), compute on every `phase_exit` per [token-optimization.md](token-optimization.md) §6.

| Signal | Est. Cost Tier |
|--------|----------------|
| S / `/od -f`, sub_agents off | low |
| M, no sub-agents, design_split | medium |
| Phase 2 + 3+ workers | high |
| L/XL full + regression 10+ | high |
| Long session (>25 turns) without compress | high |

`/od gv --scope cost` reads `estimated_tokens_total` and `events[].estimated_cost_tier` for hotspot analysis.

---

## 4. Coverage Metrics (Phase 4)

Run coverage **once** per requirement. Record in `05-test-report.md` only — do not load raw coverage JSON into context.

| Stack | Command |
|-------|---------|
| Node | `npm test -- --coverage --silent` |
| Go | `go test ./... -coverprofile=coverage.out` then `go tool cover -func=coverage.out \| tail -1` |
| Python | `pytest --cov -q` |

Gates: L/XL/greenfield ≥90%; M/legacy ≥70%. Block only if `coverage_gate: true`.

---

## 5. Dashboard Input (`/od db`)

Reads `metrics.json` aggregates including `avg_tokens_per_requirement` for ROI panel.
