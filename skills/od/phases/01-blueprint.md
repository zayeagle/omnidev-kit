# Phase 1 Instructions (Blueprint)
→ Platform mapping: SKILL.md §F (Platform Abstraction Layer)


## Context Requires

```yaml
context_requires:
  read:
    - 00-project-context.md          # stack type, conventions, pitfall guide, domain knowledge
    - user-preferences.md            # code style, tech stack preferences (if exists)
  scan:
    - source directories relevant to the requirement (max 5 files)
  skip:
    - 02-plan.md, 03-progress.md, 04-design.md, 05-test-plan.md, 05-test-report.md
    - "*-history.md"
```

## 1. Requirement Analysis

1. Parse the user's requirement: identify core objectives, key entities, primary workflows, and critical constraints.
2. Check `00-project-context.md` for existing conventions and domain knowledge that apply.

**Greenfield**: Propose module boundaries aligned with DDD/OpenSpec. **Legacy**: Map to existing modules first; avoid new stacks unless justified.

---

## 2. Solution Comparison (MUST execute before outputting blueprint)

**Purpose**: Prevent AI from locking into the first idea. Explicitly compare viable approaches before committing.

Identify 2–3 viable technical approaches. For each approach, output a concise comparison.

Evaluate all approaches on these dimensions:

- Compatibility: how well it fits the existing stack (from `00-project-context.md`)
- Complexity: implementation effort, new dependencies, learning curve
- Extensibility: how easily the solution accommodates future changes

Score each approach as ✅ (strong) / ⚠️ (moderate) / ❌ (weak) on each dimension.

```markdown
### Approach A: [Name]
- **Core idea**: [1-2 sentences]
- **Best for**: [when this approach excels]
- **Main risk**: [biggest downside or fragility]
- **Key assumption**: [unvalidated premise this approach depends on]

### Approach B: [Name]
- **Core idea**: ...
- ...
```

**Rules**:

- Always include at least 2 approaches. If only one is feasible, state why others are infeasible.
- If `interactive_mode=true`, use the platform interactive prompt (§F.2) to let user select. If `false`, present with a clear recommendation.
- **STOP — WAIT for user selection** before proceeding.

---

## 3. Design Assumptions (MUST document before outputting blueprint)

After user selects the approach, explicitly list all unvalidated assumptions:

```markdown
### Design Assumptions

| # | Assumption | Risk Level | Validation |
|---|-----------|------------|------------|
| A1 | [assumption description] | 🔴 blocking / 🟡 acceptable / 🟢 low | [how to verify, or "user confirmed"] |
```

**Rules**:

- 🔴 **blocking**: if wrong, entire approach collapses — must validate before Phase 3.
- 🟡 **acceptable**: significant rework but approach still viable.
- 🟢 **low**: minor adjustment if wrong.
- Present assumptions to user for confirmation.

---

## 4. Open Questions (MUST list before finalizing)

```markdown
### Open Questions

| # | Question | Impact | Default (if not answered) |
|---|----------|--------|---------------------------|
| Q1 | [specific question] | [what decision it affects] | [reasonable default] |
```

**Rules**:

- Sort by blocking impact — blueprint-structure questions first.
- Provide a reasonable default for each.
- If `interactive_mode=true`: output the questions table as prose in chat **first**, then same turn invoke [interactive-prompt.md](../engine/interactive-prompt.md) **Open Questions batch confirmation** template (§4.9 Cursor / §5.9 Claude / §6.5 Codex) to let user accept all defaults or opt into per-question review.
  - User picks "全部接受默认值" → accept all defaults, proceed.
  - User picks "逐个调整" → re-invoke sequential single-question prompts (one per row, reusing the `Default` column as the recommended option).
- If `interactive_mode=false`: use §9 minimal text instead.

---

## 5. Output Blueprint → `01-blueprint.md`

If `01-blueprint.md` already exists with substantive content, archive it to `01-blueprint-history.md` before writing (see [document-history.md](../engine/document-history.md)).

```markdown
---
version: 1
artifact: 01-blueprint.md
approach: [selected approach name]
last_updated: [timestamp]
history_ref: 01-blueprint-history.md
---

# Blueprint: [requirement summary]

## 1. Requirement Summary
[1-2 sentences restating the confirmed requirement]

## 2. Architecture Overview
[Module boundaries, data flow — simple Mermaid only]

## 3. Module / Service Breakdown
| Module | Responsibility | Key Interfaces | Dependencies |
|--------|---------------|---------------|--------------|

## 4. Data Flow
[Simple Mermaid sequence or flow diagram]

## 5. Integration Points
- **Existing modules affected**: [list and describe impact]
- **External dependencies**: [APIs, services, data stores]
- **Frontend impact**: [yes — describe / none]

## 6. Design Assumptions (from Step 3)
[Copy confirmed assumptions table]

## 7. Open Questions (from Step 4)
[Copy resolved/confirmed questions]

## 8. Risk Log
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
```

**Diagram rules**:

- Simple Mermaid flowcharts or sequence diagrams only.
- Do NOT draw complex multi-layer architecture, class, ER, or deployment diagrams.
- Each diagram MUST have a 2–3 sentence plain-text summary for non-technical readers.

### 5.5 Architecture Conflict Check

Compare blueprint against `00-project-context.md` § Stack & Layers and § Architecture Patterns:

- New technology stack? → flag it.
- Contradicts existing patterns? → note conflict.
- Duplicates existing module? → reconsider boundaries.

Add findings to Risk Log (section 8).

---

## 6. Checkpoint → WAIT

```
✅ Phase 1 Complete: Blueprint
📦 Output: 01-blueprint.md
📍 Progress: Phase 0 ✅ → Phase 1 ✅ → Phase 2 ⏳
🔔 Next: Phase 2 — Detailed Design & Test Planning
```

### Handoff Checklist (before WAIT)

- [ ] `01-blueprint.md` written and non-empty
- [ ] Next phase's context_requires.read files exist (pre-check)
- [ ] Session snapshot auto-saved (session-memory.md §2)
- [ ] Key decisions recorded in state files
- Present next-step options: Continue to Phase 2 / Revise Blueprint / Cancel

---

## Sub-Agent Dispatch (per `sub_agents`)

| Mode | Phase 1 |
|------|---------|
| **off** | Main agent researches serially |
| **auto** (default) | S/M: serial. L/XL: max 1 explorer for source scan |
| **on** | 1 explorer per approach + 1 source explorer |

Max **2 approaches** for M; **3** for L/XL only (token savings).

→ [token-optimization.md](../engine/token-optimization.md) §2
