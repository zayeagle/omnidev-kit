# AI Governance & Cost Audit (`/od gv` or `/od governance`)

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
    - git log --since="<since-window>"   # default: 14 days ago; overridden by --since
    - git diff --stat HEAD~20
  skip:
    - source code full-file reads
```

**Trigger mode**: Manual only. This flow MUST run only when user explicitly types `/od gv` or `/od governance`.

**Supported flags (manual command parsing)**:
- `--scope <all|phase0|phase1|phase2|phase3|phase4|learning|cost|compliance|quality>`
- `--since <7d|14d|30d|90d>`
- Defaults: `scope=all`, `since=14d`
- Examples:
  - `/od gv`
  - `/od gv --scope phase3`
  - `/od gv --scope compliance --since 30d`

**Execution rules for flags**:
1. If `--scope` is provided, prioritize that domain in analysis and trim unrelated sections to concise notes.
2. If `--since` is provided, all time-based scans/log analysis must honor that window.
3. Invalid flag values → stop and ask user to choose a valid value (AskQuestion if interactive).

## Analysis Dimensions

1. **Cost & Token Efficiency**
   - Estimate token usage by phase/work type from available logs/metrics.
   - If exact token data is unavailable, provide relative cost hotspots with confidence notes.
   - Output: high-cost phases, likely causes, optimization opportunities.

2. **Governance Compliance**
   - Check adherence to B.0 (ask-before-act, requirement alignment, fix protocol).
   - Check whether required confirmations (scope confirmation, impact confirmation) were executed.
   - Check whether state files and session memory were properly maintained.

3. **Quality & Risk**
   - Rework signals: repeated edits, repeated failures, reopen-style patterns.
   - Testing discipline signals: coverage gates, resilience test completion, unresolved blockers.
   - Security/process risks: skipped steps, missing impact checks, weak rollback readiness.

4. **Learning Health**
   - Signal quality in `evolution-log.jsonl`: duplicates, low-confidence noise, unresolved items.
   - Practicality of accumulated `Domain Knowledge`: reusable vs stale entries.

## Output

Generate: `docs/omnidev-state/ai-governance-cost-[YYYY-MM-DD].md`

If flags are used, include suffixes: `docs/omnidev-state/ai-governance-cost-[YYYY-MM-DD]-[scope]-[since].md`

Sections:
1. Executive Summary
2. Token & Cost Findings
3. Governance Compliance Findings
4. Quality & Risk Findings
5. Learning System Health
6. Top 5 Actions (with P0/P1/P2 priority and expected ROI)

## Interaction Rules

- If `interactive_mode` is `true`, use AskQuestion to let user choose:
  - `仅查看报告` (read-only)
  - `按优先级生成改进计划` (plan only)
  - `取消`
- If `interactive_mode` is `false`, output the report and wait for next manual command.
- This command does NOT auto-apply rule/skill changes. Any such change still requires `/od ln` approval.
