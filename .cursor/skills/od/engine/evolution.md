# Self-Learning & Evolution Engine

→ Platform mapping: SKILL.md §F (Platform Abstraction Layer)


```yaml
context_requires:
  read:
    - 00-project-context.md
    - evolution-log.jsonl            # LAST 50 entries only
    - evolution-history.md           # LAST 20 entries only
  read_limits:
    evolution-log.jsonl: 50
    evolution-history.md: 20
  scan:
    - 03-progress.md
    - rules/*.mdc                               # Cursor-only — skip this scan on Claude Code / Codex
  scan_limit: 5
  skip:
    - archive/*
    - skills/od/SKILL.md
```

---

## 1. Continuous Phase Learning

**Core Principle**: Capture domain knowledge at **every phase exit**, not only post-mortem.

### 1.1 Phase-Level Learning Triggers

| Phase | What to Learn | Capture Target |
|-------|--------------|----------------|
| Phase 0 | Architecture patterns, stack, topology, domain vocabulary | `00-project-context.md` § Domain Knowledge |
| Phase 1 | Business flows, cross-module relationships, edge cases | § Domain Knowledge |
| Phase 2 | Implementation patterns, test coverage patterns, interfaces | § Domain Knowledge |
| Phase 3 | Code patterns, naming, error handling, API design, pitfalls | § AI Pitfall Guide + § Domain Knowledge |
| Phase 4 | Failure modes, mock strategies, coverage gaps | § AI Pitfall Guide |

**Confidence by source**:

- phase_0/phase_1: high weight
- phase_3: low weight unless observed **2+ times** in same session (or 1 time if high-impact error)
- user_edit: medium weight
- error_resolution: high weight

### 1.2 Phase Exit Learning Protocol

At every phase checkpoint, silently:

1. **Reflect**: New understanding gained?
2. **Filter**: Project-specific and reusable?
3. **Deduplicate**: Already in `00-project-context.md`?
4. **Append**: If novel, append 1–2 lines to § Domain Knowledge or § AI Pitfall Guide
5. **Log**: Append to `evolution-log.jsonl`

### 1.3 Learning Rules

- Always **silent** for domain knowledge — no user permission needed
- **Append only**, never overwrite
- § Domain Knowledge capped at **50 lines** — consolidate when full
- Rule/skill changes require `/od ln` user approval

---

## 2. Learning Data Sources

1. User corrections
2. Repeated patterns (3+ same adjustment)
3. Error & retry signals
4. Explicit `/od ln [feedback]`
5. Phase observations

---

## 3. Learning Log Format (`evolution-log.jsonl`)

```json
{"ts":"2026-03-29T10:00:00Z","type":"correction","category":"style","signal":"User prefers single quotes","source":"user_edit","confidence":0.7,"processed":false}
{"ts":"2026-03-29T11:00:00Z","type":"domain","category":"business_flow","signal":"Order module: payment callback must verify idempotency","source":"phase_3","confidence":0.9,"processed":false}
```

**Types**: `correction`, `domain`, `architecture`, `dependency`, `pitfall`, `prevention_rule`

---

## 4. Learning Triggers

### Passive (Silent)

- Every phase exit (§1.2)
- Error resolution
- User correction of AI output

### Active (Requires `/od ln` or Threshold)

- 5+ same-category signals → propose rule
- `confidence >= 0.95` → propose after 1 occurrence
- Phase 4 end → comprehensive retrospective
- Explicit `/od ln`

---

## 5. Learning Actions (`/od ln`)

1. Retrospective scan
2. Extract pitfalls → § AI Pitfall Guide
3. Consolidate § Domain Knowledge
4. Aggregate evolution-log.jsonl, dedupe, rank
5. Proposals: Rule Amendment, Pitfall Guide, New Skill, Workflow Tweak, Domain Update
6. Present via platform interactive prompt (SKILL.md §F.2) (if interactive)
7. Apply approved changes; mark signals `processed: true`

---

## 6. Passive Learning Side Effects

- Update `metrics.json` on `learning_applied` event
- Append JSONL
- **Never** auto-change rules/skills without `/od ln` approval

---

## 7. Safety Guardrails

- Never remove `/od` prefix requirement, checkpoints, security guardrails
- Rollback: `/od ln --rb [N]`
- Confidence `< 0.5`: never propose; `0.5–0.8`: needs 3+ occurrences; `>= 0.8`: can propose after 1
- Domain knowledge is informative — never overrides explicit user decisions
