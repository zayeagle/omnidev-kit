# Session Memory (Persistent Session State)

→ Platform mapping: SKILL.md §F.2 (Interactive Prompt)

## Overview

Every **`/od re`** resumes from disk `session-log.md`. It does **not** rely on same-chat context inference. After switching chats or a crash → resume only with `/od re`.

## 1. Session Log File

**Path**: `docs/omnidev-state/[branch]/session-log.md`

**Lifecycle**: One branch keeps only the **latest 1** session-log. When a new session ends it overwrites the old one (prior key facts are already settled into state files).

## 2. Write Triggers

Auto-generate/update `session-log.md` at:

| Trigger | Action |
|---------|--------|
| User sends `/od x` or chooses "End" | Write full session-log |
| Long no-response during Q&A Loop (session ends naturally) | On next `/od re`, backfill from available context |
| `/od st` (stash) | Write session-log as part of stash |
| Phase exit (every checkpoint) | Minimal snapshot: phase, group, feature, last decision. **No state file body copy.** |

## 3. Session Log Format

```markdown
---
branch: feature/xxx
last_phase: 3
last_task_group: 2
timestamp: 2026-06-03T08:30:00+08:00
complexity: M
status: in_progress | completed | stashed
state_files: ["02-plan.md", "04-design.md", "03-progress.md"]
active_feature: F2
active_group: 2
context_hot: ["02-plan Group 2", "features/F2.md"]
mid_task: T6
mid_task_files: ["src/pages/users.tsx", "src/api/users.ts"]
resume_payload: null
resume_payload_at: null
---

## Session Goal
[1-2 sentences describing the user's original requirement]

## Key Decisions
- **[Decision point]**: Chose [Option A], reason: [rationale]
- **[Decision point]**: User requested [specific preference]

## Progress
- Phase 0: ✅ Complexity M, recommended Plan → Dev → Test
- Phase 1: ⏭️ Skipped
- Phase 2: ✅ Plan generated, 8 tasks / 3 groups
- Phase 3: 🔄 In progress, Group 2/3 done, T6 interrupted (files: src/pages/users.tsx, src/api/users.ts)
- Phase 4: ⏳ Not started
- Phase 5: ⏳ Not started (L/XL deploy phase)

## Incomplete Items
- [-] T6: User list frontend page (Group 3) — modified src/pages/users.tsx, src/api/users.ts
- [ ] T7: Integration tests (Group 3)
- [ ] Phase 4 testing not yet run

## User Feedback Highlights
- Require API response format `{code, data, message}`
- Prefer backend first, then frontend
- Skipped Blueprint (not needed at M complexity)

## Resume Instructions
Next continue: T6 already modified src/pages/users.tsx, src/api/users.ts — resume from breakpoint; read `02-plan.md` Group 3. T6 depends on T3 API output.
```

## 4. Write Rules

1. **Minimalism**: Keep session-log within **50 lines**. Record only what helps resume execution; do not copy state file bodies.
2. **Decisions first**: Emphasize "why" over "what" — the latter already lives in state files.
3. **Must capture user feedback**: Verbal preferences, corrections, and requests during the session must go in `## User Feedback Highlights`, even if they did not trigger evolution-log.
4. **Interrupted task record**: When `/od x` interrupts a `[-]` task, YAML frontmatter MUST record `mid_task` + `mid_task_files`, and mark modified files under `## Incomplete Items` + `## Resume Instructions`.
5. **Do not block exit**: Writing session-log is the last step of the session — write silently while outputting the closing summary; no user confirmation required.

## 5. Read Scenarios

| Command | Behavior |
|---------|----------|
| `/od re` | **Must read** `session-log.md` (disk). Restore breakpoint; load phase `context_requires`. Do not read chat history. |
| `/od re [payload]` | Same + **§6.1** payload parse. |
| `/od` (new requirement, same branch) | If an `in_progress` session-log exists, prompt: resume with `/od re` or end old session with `/od x`. |
| `/od st` | session-log is saved with stash. |
| `/od po` | session-log is restored with stash. |

---

## 6. Resume Flow (`/od re`)

```yaml
context_requires:
  read:
    - docs/omnidev-state/config.json
    - session-log.md                 # YAML + Resume Instructions only
    - 02-plan.md                     # frontmatter + active group ONLY
    - 03-progress.md                 # blockers + snapshot ONLY
  read_on_demand:
    - 04-design.md                   # index only, if Phase 3/4
    - 00-project-context.md          # phase slice on first use
  skip:
    - 01-blueprint.md, 05-test-plan.md, features/*.md bulk
    - 05-test-report.md, 06-release-notes.md
    - conversation history replay
```

### Steps

1. **Read session-log.md** (if exists):
   - Extract `last_phase`, `last_task_group`, `status` from YAML frontmatter
   - Restore decision context from `## Key Decisions`
   - Restore user preference context from `## User Feedback Highlights`
   - Get resume guidance from `## Resume Instructions`

1.5. **Verify state file integrity**: Cross-check `state_files` manifest against disk. If any missing: report "⚠️ Session state incomplete. Missing: [files]. Recoverable: [yes/no]." Ask user.

2. **Read state files**: Load plan and progress per `context_requires`

3. **Locate resume point**:
   - If session-log exists: use `last_phase` + `last_task_group`
   - If missing: infer from `03-progress.md` and `02-plan.md` (first incomplete task)

4. **Report to user** and confirm:
   ```
   ♻️ Session Resumed
   Branch: [branch]
   Last progress: Phase [N] — [description]
   Remaining: [task list]
   ```
   Use platform interactive prompt (SKILL.md §F.2) (if interactive): Continue / Restart / Cancel

5. **Load phase instructions**: Based on resume point, load corresponding `phases/` file

6. **Check for unprocessed learning signals**: If `evolution-log.jsonl` has `processed: false` signals, append reminder.

---

## 6.1 Resume with Payload (`/od re [xxx]`)

**Syntax** (parse after activation):

```
/od re [payload]
/od resume [payload]
```

- `payload` = all text after `re`/`resume`, trimmed. Empty → pure §6 resume.
- Examples: `/od re`, `/od re continue Group 3`, `/od re ch change field to email`, `/od re -f fix login 500`, `/od re n`

### Flow (MANDATORY order)

```
Step A: Cold resume (§6 Steps 1–5 + §8) — load session-log, state slices, report resume point
Step B: Parse payload (if non-empty)
Step C: Route payload (table below)
Step D: Execute routed workflow at resumed phase — NO restart from Phase 0 unless user confirms
```

**Acknowledgment** (≤6 lines after Step A):

```
♻️ Session Resumed
Branch: [branch] · Phase [N] Group [G]
Payload: [payload or "none"]
Next: [routed action]
```

### Payload Router (after resume)

| Payload pattern | Route | Load / action |
|-----------------|-------|---------------|
| *(empty)* | Pure resume | [interactive-prompt.md](interactive-prompt.md) §Resume — Continue / Restart / Cancel |
| `n`, `next` | Phase advance | Current phase checkpoint → next phase protocol |
| `ad …`, `adj …`, `adjust …` | Revise | Current phase instruction §adjust |
| `-f …` | Fast dev | `phases/03-development.md` + payload as requirement |
| `-p …` | Plan only | `phases/01-blueprint.md` or Phase 2 per context |
| `ch …`, `change …` | Change mgmt | [special-flows.md](special-flows.md) §2 with payload |
| `qa` | Testing | `phases/04-testing.md` |
| `sk …`, `bk …`, `al` | Phase nav | Per commands.md Phase Navigation |
| `h`, `help` | Help | `engine/commands.md` |
| **Free text** | §6.1.1 classify | See below |

**Nested command rule**: If payload starts with a known `/od` subcommand token, strip it and route — do NOT treat as plain text.

### 6.1.1 Free-Text Payload Classification

When payload is free text (e.g. `/od re change login to OAuth`):

| Class | Signals | Action |
|-------|---------|--------|
| **A: Requirement change** | change / modify / add / remove / adjust / replace / instead / add / remove | B.14 doc sync → [special-flows.md](special-flows.md) §2 (lightweight vs structural) at **current** `last_phase` |
| **B: Continue hint** | continue / resume / still / as planned | Append to `## User Feedback Highlights`; execute resume point with no extra routing |
| **C: Phase instruction** | test first / write tests first / deploy / review | Route to Phase 4/5/`/od rv` per keywords |
| **D: Default (work intent)** | anything else | Log payload → `session-log.md` `resume_payload` + `## User Feedback Highlights`; **continue current phase** at `last_task_group` incorporating payload |

**Forbidden**:
- Ignoring payload after resume
- Restarting Phase 0 for payload without user confirm (offer via interactive prompt)
- Ad-hoc code before payload class A completes doc sync

### 6.1.2 Session-Log Updates (on `/od re [payload]`)

Append to YAML frontmatter when payload non-empty:

```yaml
resume_payload: "[user text]"
resume_payload_at: "[ISO timestamp]"
```

Append to `## User Feedback Highlights`:

```
- [resume] [timestamp]: [payload]
```

Log `metrics.json`: `type: "resume_with_payload"`, fields: `payload_class`, `last_phase`.

### 6.1.3 Interactive Prompt (payload + resume)

When payload is non-empty and class A or ambiguous, use [interactive-prompt.md](interactive-prompt.md) §Resume with payload:

| id | label |
|----|-------|
| `resume_execute` | Continue from breakpoint and handle payload [default] |
| `change_full` | Run requirement-change doc sync, then continue |
| `restart` | Discard breakpoint; treat payload as new requirement from Phase 0 |
| `cancel` | Cancel |

When payload empty, use standard §Resume (Continue / Restart / Cancel).

---

## 7. Session Exit Flow (`/od x`)

When user ends session (`/od x` or selects "End"):

1. **Generate session-log.md** (per §3-§4 rules):
   - Record current phase, progress, key decisions, user feedback
   - Mark status: `in_progress` (if tasks remain) or `completed`
   - Write to `docs/omnidev-state/[branch]/session-log.md`

2. **Update user-preferences.md** (if new preference signals detected this session)

3. **Output closing summary**:
   ```
   ✅ Session Complete
   Completed: [summary of completed tasks/phases]
   Remaining: [incomplete items, if any]
   Session memory saved. Use `/od re` to resume anytime.
   ```

4. **No next-step prompt** — `/od x` is a termination signal.

## 8. Minimal Resume (Cold Start — max 200 lines)

Per [context-lifecycle.md](context-lifecycle.md) §10:

1. session-log YAML + Resume Instructions only (≤20 lines) — skip body unless needed
2. Active phase instruction only
3. `02-plan.md` frontmatter + **active group section only**
4. `03-progress.md` `## Blockers` + `## State Snapshot` only
5. `04-design.md` index only (if Phase 3/4)
6. `00-project-context.md` — **defer** until first need; then load phase-specific slice

**Forbidden on resume**: replay conversation history, load `*-history.md`, load 01-blueprint, load full 05-test-plan, load all features/.

Log `metrics.json` event `type: "resume_cold_start"`.

## 9. Codex Compaction-Resilient Resume

Codex automatically compacts conversation history when token limits are exceeded. This interacts with `/od re` in specific ways:

### 9.1 Session-Log as Compaction Shield

The `session-log.md` YAML frontmatter is the **only reliable source of phase state** after a Codex compaction. Design it accordingly:

- All critical fields MUST be in YAML (`last_phase`, `last_task_group`, `active_feature`, `status`, `state_files`), not only in prose sections.
- Prose sections (`## Session Goal`, `## Key Decisions`, etc.) are supplementary — the AI can recover without them.
- `## Resume Instructions` should contain **actionable next steps**, not historical context.

### 9.2 Post-Compaction Resume Protocol

When `/od re` is triggered and the AI suspects compaction occurred (truncated context, summary markers, inability to recall prior turns):

1. **Trust only YAML frontmatter** of `session-log.md`. Ignore any phase/state information recovered from conversation memory — it may be a compaction artifact.
2. **Aggressively reload from disk**: Re-read all files listed in `state_files` from disk, even if the AI "remembers" their contents. Compaction summaries may distort or omit details.
3. **Report the recovery state**:
   ```
   ♻️ Session Resumed (post-compaction recovery)
   Branch: [branch]
   Last progress (from session-log): Phase [N] — Group [G]
   Reloaded [N] state files from disk.
   ```
4. **Reset occupancy estimates**: Set HOT to 80, WARM to 40 (defensive defaults per context-lifecycle §8).
5. **Do NOT attempt to recover conversation history**. Prior user decisions live in `session-log.md` `## Key Decisions` and `## User Feedback Highlights`.

### 9.3 Compaction-Safe Writing Practices

During an active `/od` session on Codex, write to `session-log.md` at these checkpoints (in addition to normal triggers in §2):

| Trigger | What to write |
|---------|--------------|
| After every task completion | Update `last_task_group` and `active_group` in YAML frontmatter |
| After user makes a key decision | Append to `## Key Decisions` immediately — don't wait for session end |
| After user gives feedback/correction | Append to `## User Feedback Highlights` immediately |
| Every 10 turns | Update `## Resume Instructions` with current "next step" |

This ensures that even if Codex compacts before a normal `/od x` saves the full session-log, the file contains up-to-date recovery state.

### 9.4 Integration

- [context-lifecycle.md](context-lifecycle.md) §11.1 — Codex compaction coexistence
- SKILL.md §F.8 — Codex Context Compaction Awareness
- `metrics.json` event `type: "resume_post_compaction"` when compaction is suspected
