# AI Governance & Cost Audit

→ Platform mapping: SKILL.md §F (Platform Abstraction Layer)
 (`/od gv` or `/od governance`)

```yaml
context_requires:
  read:
    - docs/omnidev-state/config.json
    - docs/omnidev-state/metrics.json
    - docs/omnidev-state/00-project-context.md
    - docs/omnidev-state/user-preferences.md
    - docs/omnidev-state/[branch]/02-plan.md
    - docs/omnidev-state/[branch]/03-progress.md
    - docs/omnidev-state/[branch]/05-test-report.md
    - docs/omnidev-state/[branch]/session-log.md
    - docs/omnidev-state/evolution-log.jsonl
  scan:
    - git log --since="<since-window>"
    - git diff --stat HEAD~20
  skip:
    - source code full-file reads
```

**Trigger mode**: Manual only ? run when user types `/od gv` or `/od governance`.

**Flags**:

- `--scope <all|phase0|phase1|phase2|phase3|phase4|phase5|learning|cost|compliance|quality>`
- `--since <7d|14d|30d|90d>` (default: 14d)

---

## Real-Time Warning Thresholds

During Phase 3, append to Change Impact Summary when triggered:

| Trigger | Threshold | Severity |
|---------|-----------|----------|
| File rework | Same file 3+ edits | ?? High |
| Task rework | Same group 2+ times | ?? Critical |
| Rollback | 2+ reverts | ?? High |
| Test loop | Same test fails 3+ times | ?? Critical |
| Token guard | context-protocol §11 breach | ?? High |

---

## Analysis Dimensions

1. **Cost & Token Efficiency**
   - `estimated_tokens_total`, `events[].estimated_cost_tier` from metrics.json
   - Flag M complexity with `sub_agents_spawned_total` > 0
   - Recommend per [token-optimization.md](token-optimization.md)
2. **Governance Compliance** — B.0, B.15, B.17, B.19 (active + history pairs), state files
3. **Quality & Risk** ? rework, test gates, skipped steps
4. **Learning Health** ? evolution-log quality

---

## Output

`docs/omnidev-state/ai-governance-cost-[YYYY-MM-DD].md`

Sections: Executive Summary, Token & Cost, Compliance, Quality, Learning, Top 5 Actions.

Does NOT auto-apply changes ? requires `/od ln` approval.
