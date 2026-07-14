# Special Flows & Engine Instructions

→ Platform mapping: SKILL.md §F.2 (Interactive Prompt), §F.3 (Sub-Agent), §F.4 (Slash Command)

## 1. Push (`/od push` / `/od ps`)

```yaml
context_requires:
  scan:
    - git status
    - git diff --stat
    - git diff --staged
  skip:
    - all state files
```

1. `git diff --stat HEAD` — generate **Change Impact Summary** and display to user:

   ```
   📋 **Pre-Push Impact Summary**

   ### File Changes (N files)
   | Operation | File Path | Description |
   |-----------|----------|-------------|
   | 📝 Modified | src/routes/user.ts | Added login endpoint |
   | 🆕 Added | src/services/auth.ts | Authentication service module |
   | 🗑️ Deleted | src/utils/legacy.ts | Removed legacy auth logic |

   ### Feature Impact
   - **[Module]**: [impact description]

   ### Dependency & Config Changes
   - [List changes, or "None"]
   ```

2. **MUST** invoke [interactive-prompt.md](interactive-prompt.md) §3.6 `push_confirm` via §4/§5/§6 (same turn):
   - `commit` — `git add` (per convention) → use the message above → commit → push
   - `edit_msg` — user edits the message, then confirms again
   - `cancel` — cancel
3. Execute `git commit` + `git push` only after the user confirms via UI pick or `/od y` equivalent.
4. **Never commit** without interactive confirm (aligns with git safety). Do not ask in prose “Commit?” without calling the tool.

---

## 2. Change Management (`/od change` / `/od ch`)

```yaml
context_requires:
  read:
    - 00-project-context.md
    - 01-blueprint.md
    - 02-plan.md
    - 03-progress.md
    - 04-design.md
    - 05-test-plan.md
    - 06-release-notes.md
  scan:
    - files affected by the proposed change
  note: only read files that exist; skip missing files silently
```

1. **Impact assessment**: Assess impact on current architecture and all existing state files.

### 2.1 Change Classification

Determine whether the change is:

- **Lightweight**: modifies details within an existing feature (e.g., field rename, validation rule change). Strategy: update `04-design.md` + `05-test-plan.md` inline with CHANGE_LOG markers. Do NOT regenerate `02-plan.md`. Archive feature snapshot to `04-design-history.md` only if the feature file content changes substantively.
- **Structural**: alters architecture, data flow, or feature boundaries. Strategy: **archive** then regenerate `04-design.md` + `05-test-plan.md` + `02-plan.md` per [document-history.md](document-history.md).

Present the classification to user via §3.6 `change_confirm` (or classify first, then `change_confirm`) — **MUST** §4/§5/§6 → **STOP — WAIT**.

For Structural changes: spawn 1 worker per feature to regenerate `04-design.md` sections in parallel, then 1 worker per feature for `05-test-plan.md`. Main agent handles `02-plan.md` traceability merge and final sync report.

2. **Change impact report**: Present a structured impact report:

   ```
   📋 **Requirement Change Impact Analysis**
   📝 Change description: [description]
   📂 Affected files:
     - 01-blueprint.md: [impact description]
     - 02-plan.md: [impact description]
     - ...
   ✅ Unaffected: [list]
   ⏳ Not yet generated: [list — will be generated in later phases]
   ```

3. **MUST** invoke §3.6 `change_confirm` via §4/§5/§6 → **STOP — WAIT** (Proceed / Revise / Cancel).
4. **Global document sync** (per B.14, after confirmation):
   - Archive previous active content to paired `*-history.md` per [document-history.md](document-history.md) §2 (before any overwrite).
   - Update each affected **active** state file to reflect the new requirements.
   - Regenerate blueprint/plan sections as needed.
5. **Sync completion report**: Output final sync summary per B.14 protocol.

### 2.2 Sub-Agent Dispatch for Structural Changes

Same as §2.1 Structural path. On worker failure, follow [context-lifecycle.md](context-lifecycle.md) §10.

---

## 3. Report (`/od report` / `/od rp`)

```yaml
context_requires:
  read:
    - 00-project-context.md
    - 02-plan.md
    - 03-progress.md
    - metrics.json
  scan:
    - git log --since="7 days ago"
  note: "*-history.md — grep ARCHIVE headers only (version, reason, summary); never load full snapshots"
```

1. Read active state files; grep `*-history.md` for archive headers only.
2. Analyze `git log` (past 7 days).
3. Generate management-ready report in `docs/omnidev-state/weekly-report-[date].md`.
4. Include: executive summary, AI-assisted achievements, progress, blockers, next week plan, metrics aggregates from [metrics.md](metrics.md).

---

## 3.1 Next-Step Prompt Format (B.8)

After every phase checkpoint, call [interactive-prompt.md](interactive-prompt.md):
- Cursor → §3.1 catalog + §4 `AskQuestion` (same turn, mandatory when tool present)
- Claude Code → §3.1 catalog + §5 `AskUserQuestion` (same turn, mandatory)
- Codex → §3.1 catalog + §6 `request_user_input` (same turn, mandatory)
- On failure → pseudo-popup §8 → **STOP — WAIT**

Standard checkpoint options (Chinese labels when `interactive_mode=true` use English below):

| Option | Typical Label |
|--------|---------------|
| Continue next phase | Continue to next phase (`/od n`) |
| Revise current output | Revise current output (`/od ad`) |
| Skip optional phase | Skip [phase] (`/od sk`) |
| End / Push / Deploy | End / Push / Deploy (context-dependent) |
| Help | View commands (`/od h`) — **always last option** |

**Rules**:
- MUST STOP and WAIT after presenting options (native UI or text fallback).
- User picks in UI **or** sends **full `/od` command** in next message (`/od n`, `/od ad`, …).
- Bare numbers/aliases (`1`, `n`, `continue`) without `/od` → **do NOT** activate — normal chat.
- If native prompt fails → text fallback same turn ([interactive-prompt.md](interactive-prompt.md) §8); fallback text must show `/od` commands (never bare `1`/`2`/`3`).

---

## 4. Context Pruning (`/od compress`)

**Triggers:** `03-progress.md` > 100 lines, HOT+WARM > 300 lines, 15+ turns in same phase, or `/od compress`.

**Action:**
1. Append current `03-progress.md` snapshot to `03-progress-history.md` per [document-history.md](document-history.md) §6.1.
2. Condense `03-progress.md` to frontmatter + blockers + 3 active tasks (≤50 lines).
3. Execute [context-lifecycle.md](context-lifecycle.md) §9 purge + occupancy report.
4. Reset WARM to: session-log YAML + 02-plan active group + 04-design index.

**Output** (≤8 lines):
```
📊 Context Occupancy
HOT: N/150 · WARM: N/250
Purged: [categories]
Reload: [paths if needed]
```

---

## 5. Error Handling (B.10)

When any step fails (build, test, tool error, deploy):

1. **Log**: Record error message, command, file path in `03-progress.md` under `## Blockers` or session-log.
2. **Diagnose**: Identify root cause — do not retry blindly.
3. **Propose fix**: Structured proposal with impact scope (files, features, rollback).
4. **Confirm** (B.0): STOP — WAIT for user approval before applying fix.
5. **Retry limit**: Same error 3 times → escalate to user with `/od gv` suggestion.

### 5.1 Test Failures (Phase 4)

Per [test-strategy.md](test-strategy.md) §7 Gap Backfill:

| Layer fail | Default action |
|------------|----------------|
| UNIT | Fix implementation or test; re-run; blocks gate |
| INT | Check API contract → G1 design update if spec wrong |
| E2E | Playwright fix / env G3 / UI bug → re-run |
| Missing spec | G1/G2 backfill — **never skip Required layer** |

Log `gate_status: FAIL` in report; offer `/od ad` Phase 3/4 loop.

## 6. Update (`/od up`)

```yaml
context_requires:
  read:
    - docs/omnidev-state/config.json
  skip:
    - all other state files
```

**Source**: Use `update_source_url` from `config.json`. Default: `https://github.com/zayeagle/omnidev-kit.git`.

### 6.1 Install scope (`project` | `user`)

| Flag | Meaning |
|------|---------|
| `/od up` | **Default `project`** |
| `/od up --scope project` / `/od up -s project` | Project-level install |
| `/od up --scope user` / `/od up -s user` | User-level install |

Optional: `config.json` → `install_scope` (`"project"` \| `"user"`) overrides the default when the flag is omitted. Explicit `--scope` / `-s` always wins.

**Target matrix** (resolve after platform detect §F.1):

| Platform | `project` (default) | `user` |
|----------|---------------------|--------|
| **Cursor** | `.cursor/skills/od/` + merge `.cursor/rules/` + project `AGENTS.md` | `~/.cursor/skills/od/` only (no project rules / AGENTS) |
| **Claude Code** | `.claude/skills/od/` | `~/.claude/skills/od/` |
| **Codex** | No project skill path — **remap to `user`** with one-line notice; install `~/.codex/skills/od/` | `~/.codex/skills/od/` |

Announce resolved scope + target path in the change summary before confirm.

### 6.2 Steps

1. Parse scope (flag → config `install_scope` → **`project`**). Detect platform (§F.1). Codex+`project` → remap to `user` + notice.
2. Clone remote to temp: `git clone --depth 1 <update_source_url> _omnidev-kit-tmp`
3. Build file manifest against **resolved targets** (skills always; Cursor `project` also rules + AGENTS).

   **Apply rules** (step 6):
   - **Cursor `project`**: `rm -rf .cursor/skills/od/; cp -r …/skills/od/ .cursor/skills/od/`. Rules: non-destructive merge into `.cursor/rules/`. Refresh project `AGENTS.md` OmniDev section if kit ships one.
   - **Cursor `user`**: `rm -rf ~/.cursor/skills/od/; cp -r …/skills/od/ ~/.cursor/skills/od/`. Skip rules / AGENTS.
   - **Claude Code**: `rm -rf <target>/od/; cp -r …/skills/od/ <target>/od/` (`project` → `.claude/skills/od/`, `user` → `~/.claude/skills/od/`). Skip `rules/`.
   - **Codex**: `rm -rf ~/.codex/skills/od/; cp -r …/skills/od/ ~/.codex/skills/od/`. Skip `rules/`. Prefer `codex skills refresh` after copy.

   **Kit repo layout**: SSOT at `skills/od/` + `rules/`. Maintainers: `scripts/sync-skills.*` then `scripts/check-compliance.*`.

4. Diff & present change summary (New / Changed / Obsolete / Unchanged) vs resolved target. Include `scope=` and path.
5. Confirm — [interactive-prompt.md](interactive-prompt.md) `up_confirm`. MUST NOT apply without approval.
6. Apply (after confirm): skills = full overwrite (delete-then-copy); Cursor `project` rules = non-destructive merge.
7. Cleanup `_omnidev-kit-tmp/`.
8. Report: scope, target path, New N / Changed N / Deleted N / Unchanged N.
9. **Board seed** ([board.md](board.md) §7): ensure `docs/omnidev-state/` exists; if `flow-board.json` / `flow-board.md` missing, copy from skill `templates/`; merge `board_ui` / `board_default_mode` / `board_cursor_canvas` into `config.json` when keys absent. Do not overwrite in-progress board state.

---

## 7. Dashboard (`/od db` / `/od dashboard`)

```yaml
context_requires:
  read:
    - metrics.json
    - 00-project-context.md
    - archive/metrics-archive-*.json
    - weekly-report-*.md
  scan:
    - git log --since="30 days ago" --oneline
  skip:
    - source code
```

Generate `docs/omnidev-state/dashboard-[date].md`:

```markdown
# OmniDev Efficiency Dashboard

## Summary (30 days)
- Requirements completed: N
- Avg tasks per requirement: N
- Test pass rate avg: N%
- Phase skip rate: [chart/table]
- Deploy count: N

## ROI Indicators
| Metric | Value | Trend |
|--------|-------|-------|
| Time to first commit | [est] | ↑/↓ |
| Rework rate (files 3+ edits) | N% | |
| Regression failure rate | N% | |

## Top Bottlenecks
1. [Phase or pattern] — [suggestion]

## Token Efficiency (30 days)
| Metric | Value |
|--------|-------|
| Avg tokens/requirement | N |
| High-tier phase exits | N |
| Sub-agents spawned | N |
| Compress events | N |

## Recommendations
- P0: [...]
- P1: [...]
```

If `metrics.json` missing or empty, note "Insufficient data — complete 1+ full workflow cycles."

---

## 8. Sync to Issue (`/od sy` / `/od sync`)

```yaml
context_requires:
  read:
    - 02-plan.md
    - 05-test-report.md
    - 06-release-notes.md
    - session-log.md
  scan:
    - git log -1 --format=%B
```

Sync OmniDev artifacts to external trackers. **Requires `gh` CLI for GitHub** or user-provided Jira API config in `config.json`.

### 8.1 GitHub Issue / PR Comment

Template body:

```markdown
## OmniDev Summary
**Requirement**: [from session-log]
**Complexity**: [S/M/L/XL]
**Status**: [phases completed]

### Deliverables
- Plan: `docs/omnidev-state/[branch]/02-plan.md`
- Test report: [pass/fail counts]
- Release notes: [link or summary]

### Test Results
| Type | Passed | Failed |
|------|--------|--------|
| Smoke | N | N |
| Regression | N | N |

### Action Items
- [ ] [from 05-test-report.md §7]
```

**Steps**:
1. Ask user: target Issue # / PR # / create new issue.
2. Preview body → confirm → `gh issue comment` or `gh pr comment`.
3. Output sync report with URL.

### 8.2 Jira (Optional)

If `config.json` contains `jira_base_url` and `jira_project_key`:
- Map fields: Summary ← session goal, Description ← release notes, Labels ← complexity + branch.
- User must confirm before API call.

---

## 9. Install (`/od i <url>`)

Same **install scope** as §6.1 (`project` default; `--scope` / `-s` / config `install_scope`).

```
/od i <url>
/od i <url> --scope project
/od i <url> --scope user
```

Clone to `_omnidev-kit-tmp`, then copy to targets from §6.1 matrix (SKILL.md §F.7):

1. Parse scope → detect platform (§F.1). Codex+`project` → remap to `user` + notice.
2. **Copy skills (full overwrite)** to resolved skill target.
3. **Copy rules / AGENTS**: Cursor `project` only — merge `rules/` → `.cursor/rules/`; refresh project `AGENTS.md` if applicable. Cursor `user` / Claude / Codex: skip.
4. Write `update_source_url` (and optionally `install_scope` if user asked to persist) to `docs/omnidev-state/config.json`.
5. **Board seed**: copy `templates/flow-board.json` + `templates/flow-board.md` into `docs/omnidev-state/` if missing; merge board config keys (`board_ui`, `board_default_mode`, `board_cursor_canvas`) if absent.
6. Cleanup `_omnidev-kit-tmp/`. Codex: `codex skills refresh` if available.

**Full overwrite policy**: Skills = delete-then-copy. Cursor project rules = non-destructive merge.
