# Self-Learning & Evolution Engine

```yaml
context_requires:
  read:
    - 00-project-context.md          # project conventions, pitfall guide, domain knowledge
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

---

## 1. Continuous Phase Learning (全生命周期持续学习)

**Core Principle**: Learning is NOT a post-mortem activity. Like a human engineer who builds domain expertise with every task they complete, the AI must actively capture domain knowledge at **every phase exit** throughout the requirement lifecycle.

### 1.1 Phase-Level Learning Triggers

| Phase | What to Learn | Capture Target |
|-------|--------------|----------------|
| **Phase 0 (Assessment)** | Project architecture patterns, tech stack conventions, dependency topology, business domain vocabulary | `00-project-context.md` § Domain Knowledge |
| **Phase 1 (Blueprint)** | Business flow patterns, cross-module relationships, common edge cases for this domain, architectural constraints | `00-project-context.md` § Domain Knowledge |
| **Phase 2 (Planning)** | Task decomposition patterns for this project, typical dependency structures, parallel-safe boundaries | `00-project-context.md` § Domain Knowledge |
| **Phase 3 (Development)** | Code patterns, naming conventions, error handling idioms, API design patterns, common pitfalls encountered | `00-project-context.md` § AI Pitfall Guide + § Domain Knowledge |
| **Phase 4 (Testing)** | Typical failure modes, effective mock strategies for this project's dependencies, coverage gaps | `00-project-context.md` § AI Pitfall Guide |

### 1.2 Phase Exit Learning Protocol

At **every phase checkpoint** (before presenting next-step options), silently execute:

1. **Reflect**: What new understanding about this project's business domain, architecture, or conventions was gained in this phase?
2. **Filter**: Is this insight project-specific and reusable for future requirements? (Discard one-off observations)
3. **Deduplicate**: Is this already recorded in `00-project-context.md`?
4. **Append**: If novel and reusable, append to the appropriate section in `00-project-context.md`:

```markdown
## Domain Knowledge
<!-- Auto-accumulated by OmniDev across all phases -->

### Business Scenarios
- [Module X]: Handles [business flow], key entities are [A, B, C], edge cases include [...]
- [Module Y]: Responsible for [business logic], depends on [external service Z]

### Architecture Patterns
- API layer follows [pattern]: [route] → [controller] → [service] → [repository]
- Error handling convention: [describe observed pattern]
- State management: [describe pattern]

### Cross-Module Dependencies
- [Module A] ←→ [Module B]: Connected via [mechanism], changing A requires [...]
- [Service X] → [Queue Y] → [Consumer Z]: Async flow, typical latency [...]
```

### 1.3 Learning Rules

- Phase learning is **always silent** — never ask user permission to record domain knowledge.
- Only **append** to `00-project-context.md`, never overwrite existing entries.
- Keep each insight to **1-2 lines max**. Concise over verbose.
- `§ Domain Knowledge` section capped at **50 lines**. When approaching limit, consolidate older entries.
- This captures **business domain understanding**, NOT task progress (that goes to state files).

---

## 2. Learning Data Sources

1. **User Corrections**: "don't do this", "change to XXX", manual edits.
2. **Repeated Patterns**: Same manual adjustment 3+ times.
3. **Error & Retry Signals**: Anti-pattern → resolution (tests, lint, build).
4. **Explicit Feedback**: `/od ln [feedback]`.
5. **Phase Observations**: Domain knowledge, architecture patterns, business flow understanding captured at each phase exit.

## 3. Learning Log Format (`evolution-log.jsonl`)

```json
{"ts":"2026-03-29T10:00:00Z","type":"correction","category":"style","signal":"User prefers single quotes","source":"user_edit","confidence":0.7}
{"ts":"2026-03-29T11:00:00Z","type":"domain","category":"business_flow","signal":"Order module: payment callback must verify idempotency via order_id","source":"phase_3","confidence":0.9}
{"ts":"2026-03-29T12:00:00Z","type":"architecture","category":"pattern","signal":"All services use repository pattern with interface injection","source":"phase_0","confidence":0.95}
```

**Extended types for continuous learning**:
- `domain` — business scenario understanding
- `architecture` — structural patterns and conventions
- `dependency` — cross-module/service relationships
- `pitfall` — learned from errors during development

## 4. Learning Triggers

### Passive (Silent, No User Interaction)
- **Every phase exit**: Capture domain/architecture insights (§1.2)
- **Error resolution**: When a build/test/lint error is fixed, log the anti-pattern
- **User correction**: When user modifies AI output, log the deviation

### Active (Requires `/od ln` or Threshold)
- Accumulation: 5+ same category signals → propose rule/convention
- High Confidence: `confidence >= 0.95` → propose after 1 occurrence
- Phase 4 end → comprehensive retrospective
- Explicit `/od ln` → full learning cycle
- `/od re` (if unprocessed signals exist)

## 5. Learning Actions (`/od ln`)

1. **Retrospective**: Scan progress docs/archives for errors/corrections AND domain insights.
2. **Extract Pitfalls**: Write lessons to `[AI Pitfall Guide]` in `00-project-context.md`. Log as `error_resolution` in `evolution-log.jsonl`.
3. **Consolidate Domain Knowledge**: Review `§ Domain Knowledge` section, merge redundant entries, elevate high-confidence patterns.
4. **Aggregate**: Read `evolution-log.jsonl`, cluster by `category`, dedupe against `evolution-history.md`, rank by confidence.
5. **Proposals**: Rule Amendment, Pitfall Guide, New Skill, Workflow Tweak, Context Convention, Domain Knowledge Update.
6. **Present**: If `interactive_mode` is `true`, use `AskQuestion` to adopt/reject/adjust proposals. Otherwise, text prompt.
7. **Apply**: Patch files, mark signals `processed`, append `evolution-history.md`.

## 6. Passive Learning (Silent)

- Append to `[AI Pitfall Guide]` in `00-project-context.md`.
- Append to `[Domain Knowledge]` in `00-project-context.md`.
- Update `metrics.json`.
- Append JSONL.
- **Rule/skill changes ALWAYS need explicit user approval via `/od ln`.**
- **Domain knowledge accumulation does NOT need user approval** — it is observational, not prescriptive.

## 7. Safety Guardrails

- Never remove/weaken `/od` prefix requirement, checkpoints, security guardrails.
- Rollback: `/od ln --rb [N]` using git history + `evolution-history.md`.
- Confidence: `< 0.5` never proposed; `0.5–0.8` needs 3+ occurrences; `>= 0.8` can propose after 1.
- Domain knowledge entries are append-only and non-destructive — they inform but never override explicit user decisions.
- `§ Domain Knowledge` section capped at 50 lines to prevent context bloat.
