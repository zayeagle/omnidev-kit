# Special Flows & Engine Instructions

## 1. Push (`/od push`)

```yaml
context_requires:
  scan:
    - git status                     # modified files list
    - git diff --stat                # file-level change summary
    - git diff --staged              # after staging, for commit message generation
  skip:
    - all state files                # push doesn't need OmniDev state
```

1. `git diff --stat HEAD` → generate **Change Impact Summary** and display to user:
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
2. If `interactive_mode` is `true`, use `AskQuestion`:
   - **One-click auto**: `git add .` -> auto-generate message -> commit -> push.
   - **Manual select**: wait for user to `git add`, then generate message.
   - **Cancel**.
3. If `interactive_mode` is `false`, wait for user to `git add`, then generate message.
4. Confirm message (AskQuestion if interactive).
5. `git commit` + `git push origin <current-branch>`.

## 2. Change Management (`/od change`)

```yaml
context_requires:
  read:
    - 00-project-context.md          # stack info for impact scope
    - 02-plan.md                     # current plan to assess impact against
    - 03-progress.md                 # what's already done (can't undo)
    - 04-design.md                   # architectural constraints
  scan:
    - files affected by the proposed change
```

1. Assess impact on current architecture.
2. If interactive, use `AskQuestion` to confirm: Proceed / Revise / Cancel.
3. Archive old plan, regenerate blueprint/plan.

## 3. Report (`/od report`)

```yaml
context_requires:
  read:                              # report needs the full picture
    - 00-project-context.md
    - 02-plan.md
    - 03-progress.md
    - metrics.json
    - archive/*                      # historical progress
  scan:
    - git log --since="7 days ago"
```

1. Read all state files + `archive/`.
2. Analyze `git log` (past 7 days).
3. Generate management-ready report in `docs/omnidev-state/weekly-report-[date].md`.
4. Include: executive summary, AI-assisted achievements, progress, blockers, next week plan.

## 4. Context Pruning (`/od compress` or Auto-trigger)

**Triggers:** `03-progress.md` > 200 lines, 3+ M-level tasks done, or `/od compress`.
**Action:**
1. Archive resolved logs to `docs/omnidev-state/archive/progress-archive-[date].md`.
2. Condense to 1-2 sentence summary at top of `03-progress.md`.
3. Retain: YAML frontmatter, current blockers, next action.
4. Keep `03-progress.md` under 50 lines.

## 5. Update (`/od up`)

```yaml
context_requires:
  read:
    - docs/omnidev-state/config.json   # load update_source_url
  skip:
    - all other state files
```

**Source**: Always use the `update_source_url` from `config.json`. If not set, default to `https://github.com/zayeagle/omnidev-kit.git`.

**Steps**:

1. **Clone remote to temp directory**:
   ```
   git clone --depth 1 <update_source_url> _omnidev-kit-tmp
   ```
2. **Build file manifest** — list all files under the following directories in both remote (`_omnidev-kit-tmp/`) and local (`.cursor/`):

   | Remote source path | Local target path |
   |--------------------|-------------------|
   | `_omnidev-kit-tmp/rules/` | `.cursor/rules/` |
   | `_omnidev-kit-tmp/skills/od/` | `.cursor/skills/od/` |

3. **Diff & present change summary** — compare remote vs local and categorize every file:

   | Category | Meaning |
   |----------|---------|
   | **New** | File exists in remote but not locally |
   | **Changed** | File exists in both, content differs |
   | **Obsolete** | File exists locally but not in remote — will be deleted |
   | **Unchanged** | File exists in both, content identical |

   Output a summary table to the user:
   ```
   📦 OmniDev Kit Update Preview
   ┌────────────┬──────────────────────────────────┐
   │ Operation  │ File                              │
   ├────────────┼──────────────────────────────────┤
   │ 🆕 New     │ skills/od/phases/05-deploy.md     │
   │ 📝 Changed │ skills/od/SKILL.md                │
   │ 📝 Changed │ rules/01-omnidev-workflow.mdc     │
   │ 🗑️ Obsolete│ skills/od/engine/deprecated.md    │
   │ ✅ Same    │ skills/od/phases/00-assessment.md │
   └────────────┴──────────────────────────────────┘
   ```

4. **Confirm with user** — the update **MUST NOT** proceed without explicit user approval:

   - If `interactive_mode` is `true`: use **AskQuestion** tool:
     - **Confirm Update**: Apply all changes listed above.
     - **Cancel**: Abort, delete temp directory, no changes.
   - If `interactive_mode` is `false`: display numbered prompt:
     ```
     Please choose:
       1. Confirm Update — apply all changes above (`/od y`)
       2. Cancel (`/od x`)
     ```

   **STOP — WAIT for user reply.** Do NOT proceed until the user confirms.

5. **Apply changes** (only after user confirms):
   - **New + Changed files**: Copy from `_omnidev-kit-tmp/` to `.cursor/`, overwriting existing files.
   - **Obsolete files**: Delete from `.cursor/`.
   - **Unchanged files**: Skip.

6. **Cleanup**: Delete `_omnidev-kit-tmp/` directory.

7. **Report result**:
   ```
   ✅ OmniDev Kit Update Complete
      New: N files
      Changed: N files
      Deleted: N files
      Unchanged: N files
   ```

**Error handling**:
- If `git clone` fails (network, auth, etc.): report error, suggest checking URL and network, abort.
- If temp directory already exists from a previous failed update: delete it first, then retry.

## 6. Install (`/od i <url>`)

**Steps**: Clone to `_omnidev-kit-tmp`, copy rules/skills per INSTALL.md, write `update_source_url` to `config.json`, cleanup temp directory.

## 7. Resume (`/od re`)

```yaml
context_requires:
  read:
    - docs/omnidev-state/config.json          # locale, interactive_mode
    - docs/omnidev-state/user-preferences.md  # user behavior preferences (if exists)
    - session-log.md                          # session memory (if exists) — CRITICAL for resume
    - 00-project-context.md
    - 02-plan.md                              # resume needs plan to locate position
    - 03-progress.md                          # current progress
  skip:
    - 01-blueprint.md, 04-design.md
    - 05-test-report.md, 06-release-notes.md
```

### Steps

1. **Read session-log.md** (if exists):
   - Extract `last_phase`, `last_task_group`, `status` from YAML frontmatter
   - Restore decision context from `## Key Decisions`
   - Restore user preference context from `## User Feedback`
   - Get specific resume guidance from `## Resume Instructions`

2. **Read state files**: Load plan and progress per `context_requires`

3. **Locate resume point**:
   - If session-log exists: use `last_phase` + `last_task_group` to locate
   - If session-log missing: infer from `03-progress.md` and `02-plan.md` (find first incomplete task)

4. **Report to user** and confirm:
   ```
   ♻️ Session Resumed
   Branch: [branch]
   Last progress: Phase [N] — [description]
   Remaining: [task list]
   ```
   Use AskQuestion (if interactive) to confirm: Continue / Restart / Cancel

5. **Load phase instructions**: Based on resume point, load the corresponding `phases/{L}/` file and enter normal workflow

### Check for unprocessed learning signals

If `evolution-log.jsonl` exists with `processed: false` signals, append a reminder at the end of resume output.

## 8. Session Exit (`/od x`)

When the user ends the session (types `/od x` or selects "End"), execute before outputting closing summary:

1. **Generate session-log.md** (per `engine/session-memory.md` rules):
   - Record current phase, progress, key decisions, user feedback
   - Mark status as `in_progress` (if tasks remain) or `completed`
   - Write to `docs/omnidev-state/[branch]/session-log.md`

2. **Update user-preferences.md** (if new preference signals detected this session):
   - Check for new preferences per `engine/user-preferences.md` collection rules
   - If any, silently update `docs/omnidev-state/user-preferences.md`

3. **Output closing summary**:
   ```
   ✅ Session Complete
   Completed: [summary of completed tasks/phases]
   Remaining: [incomplete items, if any]
   Session memory saved. Use `/od re` to resume anytime.
   ```

4. **Q&A Loop does NOT trigger** — `/od x` is a termination signal, do not append Q&A prompt
