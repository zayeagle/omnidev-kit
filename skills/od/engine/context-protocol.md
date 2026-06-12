# Context Protocol (On-Demand)

**Load this file ONLY during Phase transitions or when `/od compress` is triggered.**

---

## 1. Content Classification & Unload Rules

| Content Type | Example | Unloadable? | Condition |
|-------------|---------|-------------|-----------|
| **Raw tool output** | Read file content, Grep results, Shell logs, git diff | ✅ Yes | Key info already extracted into state file or checkpoint |
| **Intermediate reasoning** | Requirement analysis, approach comparison | ✅ Yes | Conclusion written to state file |
| **Phase instruction file** | `00-assessment.md`, `01-02-planning.md` | ✅ Yes | Already exited that phase |
| **State files** | `02-plan.md`, `03-progress.md`, `00-project-context.md` | ❌ Never | Downstream phases reload via `context_requires.read` |
| **User decisions & feedback** | Phase skip choices, API format requirements | ❌ Never | Must persist in session-log or user-preferences |

## 2. Dependency Chain

```
Phase 0 → 00-project-context.md → Phase 1, 2, 3, 4 (never unload)
Phase 1 → 01-blueprint.md       → Phase 2 (unloadable after Phase 2; essence in 02-plan.md)
Phase 2 → 02-plan.md            → Phase 3, 4 (never unload)
Phase 3 → 03-progress.md        → Phase 4 (never unload)
Phase 4 → 05-test-report.md     → session end (never unload early)
```

**Any state file referenced in a downstream `context_requires.read` MUST NOT be unloaded.**

## 3. Phase Exit Protocol

When exiting Phase N (after Checkpoint, before loading Phase N+1):

1. **Persist to state file**: Write key outputs (decisions, conclusions, technical findings) to the target state file. Ensure nothing needed downstream depends solely on conversation history.

2. **Transition summary** (≤ 5 lines):
   ```
   📌 Phase N context summary:
   - [What was persisted and where]
   - [Key concerns for next phase]
   - [User decisions/preferences]
   ```

3. **Mark unloadable content**:
   ```
   ⏹️ Raw outputs no longer needed (key info in state files):
   - Phase N instruction file full text
   - Phase N Read/Grep/Shell raw returns
   - Phase N intermediate reasoning
   ✅ Still valid (state files, will reload on demand):
   - [List state files written/updated by this phase]
   ```

## 4. Phase Entry Protocol

When entering Phase N+1:

1. Load new phase instruction file
2. Re-read dependent state files from filesystem (NOT from conversation history)
3. Skip content listed in previous phase's `unload` declaration
4. Active context should now consist of:
   - SKILL.md core rules (resident)
   - Current phase instruction (just loaded)
   - State files per `context_requires.read` (just re-read from disk)
   - user-preferences.md (if exists, resident)
   - Previous transition summary (≤ 5 lines)

## 5. Backtrack Rule

If Phase N+1 needs a detail not persisted in state files:
1. First check state files
2. If missing: re-read the source file from project (allowed)
3. Forbidden: scrolling back through conversation history for raw tool outputs

## 6. Context Budget

| Context Type | Budget | Trimmable? | Over-limit Action |
|-------------|--------|-----------|-------------------|
| SKILL.md core rules | Resident (~280 lines) | ❌ | Do not trim |
| Current phase instruction | 1 file (~60-100 lines) | ❌ | Do not trim |
| State files (context_requires.read) | Total ≤ 200 lines | ⚠️ Trim but never skip | Read only frontmatter + active section if too long |
| Tool call results (single) | ≤ 100 lines | ✅ | Summarize per B.5.2 |
| Historical tool results (cumulative) | Last 3 summaries only | ✅ | Older results marked expired |
| Transition summary | ≤ 5 lines/phase | ✅ | Keep only most recent |
| user-preferences.md | ≤ 30 lines | ❌ | Resident |

## 7. Trim Safety Rules

Before trimming anything, verify:
1. Not referenced in downstream `context_requires.read` → if yes, **do not trim**
2. Does not contain explicit user decisions → if yes, **persist first**
3. Is not a state file → state files are **never trimmed**

Safely trimmable:
- Raw tool outputs (if key info already extracted)
- Previous phase instruction files
- Intermediate reasoning (if conclusions already in output)

## 8. Auto-Compress Trigger

When AI detects context approaching capacity (slow responses, missing earlier info, truncated results):
1. Trigger `/od compress`: archive old progress, keep `03-progress.md` under 50 lines
2. Mark all tool outputs older than 3 turns as expired
3. Re-read from state files if prior info needed

## 9. `summarize_before_exit` Mechanism

```yaml
context_requires:
  summarize_before_exit:
    target: "02-plan.md"
    discard_after_write:
      - "source code scan results"
      - "intermediate Shell logs"
    retain:
      - "user decisions and feedback"
      - "state files in next phase's context_requires.read"
```

`discard_after_write` may only list raw tool outputs and intermediate processes — never state files or user decisions.
