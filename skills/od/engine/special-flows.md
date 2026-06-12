# Special Flows & Engine Instructions

## 1. Push (`/od push`)

```yaml
context_requires:
  scan:
    - git status
    - git diff --stat
    - git diff --staged
  skip:
    - all state files
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
    - 00-project-context.md
    - 02-plan.md
    - 03-progress.md
    - 04-design.md
  scan:
    - files affected by the proposed change
```

1. Assess impact on current architecture.
2. If interactive, use `AskQuestion` to confirm: Proceed / Revise / Cancel.
3. Archive old plan, regenerate blueprint/plan.

## 3. Report (`/od report`)

```yaml
context_requires:
  read:
    - 00-project-context.md
    - 02-plan.md
    - 03-progress.md
    - metrics.json
    - archive/*
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
    - docs/omnidev-state/config.json
  skip:
    - all other state files
```

**Source**: Use `update_source_url` from `config.json`. Default: `https://github.com/zayeagle/omnidev-kit.git`.

**Steps**:

1. **Clone remote to temp directory**:
   ```
   git clone --depth 1 <update_source_url> _omnidev-kit-tmp
   ```
2. **Build file manifest** — list all files in both remote and local:

   | Remote source path | Local target path |
   |--------------------|-------------------|
   | `_omnidev-kit-tmp/rules/` | `.cursor/rules/` |
   | `_omnidev-kit-tmp/skills/od/` | `.cursor/skills/od/` |

3. **Diff & present change summary** — categorize every file:

   | Category | Meaning |
   |----------|---------|
   | **New** | Exists in remote but not locally |
   | **Changed** | Exists in both, content differs |
   | **Obsolete** | Exists locally but not in remote — will be deleted |
   | **Unchanged** | Exists in both, content identical |

   Output summary table to user.

4. **Confirm with user** — update MUST NOT proceed without explicit approval:
   - `interactive_mode=true`: AskQuestion → Confirm Update / Cancel
   - `interactive_mode=false`: text prompt, STOP — WAIT

5. **Apply changes** (only after confirmation):
   - New + Changed: copy from temp to `.cursor/`, overwriting.
   - Obsolete: delete from `.cursor/`.
   - Unchanged: skip.

6. **Cleanup**: Delete `_omnidev-kit-tmp/`.

7. **Report result**: New N / Changed N / Deleted N / Unchanged N.

**Error handling**: If `git clone` fails, report error and abort. If temp dir exists, delete first.

## 6. Install (`/od i <url>`)

Clone to `_omnidev-kit-tmp`, copy rules/skills per INSTALL.md, write `update_source_url` to `config.json`, cleanup temp directory.
