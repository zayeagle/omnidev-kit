# Self-Learning & Evolution Engine (`/od ln`)

```yaml
context_requires:
  read:
    - 00-project-context.md          # project conventions, pitfall guide
    - evolution-log.jsonl            # LAST 50 entries only (tail -50); skip older signals
    - evolution-history.md           # LAST 20 entries only; used for dedup
  read_limits:
    evolution-log.jsonl: 50          # max 50 most recent JSONL lines
    evolution-history.md: 20         # max 20 most recent evolution entries
  scan:
    - 03-progress.md                 # current progress only
    - .cursor/rules/*.mdc            # current rules — needed to draft amendments
  scan_limit: 5                      # max 5 rule files
  skip:
    - archive/*                      # do NOT scan archives — too large, diminishing returns
    - skills/od/SKILL.md             # already in context from activation; do NOT re-read
    - branch-specific state files other than 03-progress.md
```

## 1. Learning Data Sources

1. **User Corrections**: "不要这样做", "改成 XXX", manual edits.
2. **Repeated Patterns**: Same manual adjustment 3+ times.
3. **Error & Retry Signals**: Anti-pattern → resolution (tests, lint, build).
4. **Explicit Feedback**: `/od ln [feedback]`.

## 2. Learning Log Format (`evolution-log.jsonl`)

`{"ts":"2026-03-29T10:00:00Z","type":"correction","category":"style","signal":"User prefers single quotes","source":"user_edit","confidence":0.7}`

## 3. Learning Triggers

- Accumulation: 5+ same category.
- High Confidence: `confidence >= 0.95`.
- Phase 4 end.
- Explicit `/od ln`.
- `/od re` (if unprocessed signals exist).

## 4. Learning Actions (`/od ln`)

1. **Retrospective**: Scan progress docs/archives for errors/corrections.
2. **Extract Pitfalls**: Write lessons to `[AI Pitfall Guide]` in `00-project-context.md`. Log as `error_resolution` in `evolution-log.jsonl`.
3. **Aggregate**: Read `evolution-log.jsonl`, cluster by `category`, dedupe against `evolution-history.md`, rank by confidence.
4. **Proposals**: Rule Amendment, Pitfall Guide, New Skill, Workflow Tweak, Context Convention.
5. **Present**: If `interactive_mode` is `true`, use `AskQuestion` to adopt/reject/adjust proposals. Else, text prompt.
6. **Apply**: Patch files, mark signals `processed`, append `evolution-history.md`.

## 5. Passive Learning (Silent)

- Append to `[AI Pitfall Guide]`.
- Update `metrics.json`.
- Append JSONL.
- **Rule/skill changes ALWAYS need explicit user approval via `/od ln`.**

## 6. Safety Guardrails

- Never remove/weaken `/od` prefix requirement, checkpoints, security guardrails.
- Rollback: `/od ln --rb [N]` using git history + `evolution-history.md`.
- Confidence: `< 0.5` never proposed; `0.5–0.8` needs 3+ occurrences; `>= 0.8` can propose after 1.