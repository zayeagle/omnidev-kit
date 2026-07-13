# Stash & Pop (Task Context Stash / Restore)

→ Platform mapping: SKILL.md §F.2 (Interactive Prompt)

## Overview

When the user needs to temporarily switch to another task (e.g. an urgent hotfix), `/od st` saves a full snapshot of the current work context, and `/od po` restores it on switch-back — enabling seamless multi-task switching.

## 1. Storage Layout

**Path**: `docs/omnidev-state/stash/`

```
docs/omnidev-state/stash/
├── stash-index.json          # Stash index (all stash entries)
├── <id>/                     # One subdirectory per stash
│   ├── snapshot.json         # Stash metadata
│   └── session-log.md        # Session memory snapshot
```

**Index file** `stash-index.json`:
```json
[
  {
    "id": "stash-20260603-083000",
    "branch": "feature/user-auth",
    "description": "User auth module - Phase 3 Group 2 in progress",
    "timestamp": "2026-06-03T08:30:00+08:00",
    "phase": 3,
    "task_group": 2
  }
]
```

**Snapshot file** `snapshot.json`:
```json
{
  "id": "stash-20260603-083000",
  "branch": "feature/user-auth",
  "timestamp": "2026-06-03T08:30:00+08:00",
  "phase": 3,
  "task_group": 2,
  "complexity": "M",
  "state_files": {
    "02-plan.md": "docs/omnidev-state/feature-user-auth/02-plan.md",
    "03-progress.md": "docs/omnidev-state/feature-user-auth/03-progress.md"
  },
  "uncommitted_files": ["src/services/auth.ts", "src/routes/user.ts"],
  "git_stash_ref": "stash@{0}"
}
```

## 2. `/od st` (Stash) Flow

```yaml
context_requires:
  read:
    - session-log.md              # Current session memory (if any)
    - 03-progress.md              # Current progress
  scan:
    - git status --short          # Uncommitted file list
  skip:
    - all other state files
```

### Steps

1. **Check preconditions**:
   - If there is no active `/od` workflow (no state files), prompt "No task available to stash" and exit.

2. **Generate session memory**: Write `session-log.md` per `session-memory.md` rules (if not already present); mark status `stashed`.

3. **Handle uncommitted code**:
   - Run `git status --short` to check for uncommitted changes.
   - If there are uncommitted changes, **MUST** invoke [interactive-prompt.md](interactive-prompt.md) `b0_confirm` or custom options via §4/§5/§6 → **STOP — WAIT**:

   | id | Option |
   |----|--------|
   | `git_stash` | Git stash code changes |
   | `git_commit` | Commit first, then stash the task (`git commit`) |
   | `skip_code` | Stash task context only; leave code as-is |

4. **Create snapshot**:
   - Generate stash ID: `stash-YYYYMMDD-HHmmss`
   - Create `docs/omnidev-state/stash/<id>/` directory
   - Write `snapshot.json` (metadata)
   - Copy current `session-log.md` into the stash directory
   - Update `stash-index.json`

5. **Output confirmation**:
   ```
   📦 Task stashed
   ID: stash-20260603-083000
   Branch: feature/user-auth
   Phase: Phase 3 — Group 2 in progress
   Code: [git stashed | committed | not handled]
   
   Use `/od po` to restore this task
   ```

## 3. `/od po` (Pop) Flow

```yaml
context_requires:
  read:
    - docs/omnidev-state/stash/stash-index.json  # Stash index
  skip:
    - all other files until user selects which stash to restore
```

### Steps

1. **Read index**: Load `stash-index.json`. If empty or missing, prompt "No stashed tasks" and exit.

2. **Select restore target**:
   - If only 1 stash entry, confirm whether to restore.
   - If multiple, **MUST** invoke [interactive-prompt.md](interactive-prompt.md) via §4/§5/§6 to list entries → **STOP — WAIT**:

   | id | Option |
   |----|--------|
   | `stash_N` | [branch] — [description] (Phase N, [time]) |
   | `cancel` | Cancel |

3. **Restore snapshot**:
   - Read selected stash `snapshot.json`
   - Check whether the current branch matches. If not, prompt the user to switch branches:
     ```
     ⚠️ Stashed task is on branch `feature/user-auth`, current branch is `main`.
     Switch automatically?
     ```
   - If `snapshot.json` has `git_stash_ref`, run `git stash pop`
   - Copy stash directory `session-log.md` back to `docs/omnidev-state/[branch]/session-log.md`

4. **Clean up stash**:
   - Delete stash subdirectory `docs/omnidev-state/stash/<id>/`
   - Remove the entry from `stash-index.json`

5. **Enter resume flow automatically**: Run `/od re` logic (read session-log + state files to restore context).

6. **Output confirmation**:
   ```
   ♻️ Task restored
   Branch: feature/user-auth
   Phase: Phase 3 — continuing from Group 3
   Code: [git stash restored | no restore needed]
   
   Loading context...
   ```

## 4. Constraints

- **Max stash count**: 5. When exceeded, prompt the user to clean up old stashes.
- **Expiry cleanup**: For stash entries older than 30 days, on `/od po` prompt: "This stash is over 30 days old; state files may be stale. Still restore?"
- **Branch safety**: On pop, if the target branch has been deleted, warn the user and abort restore.
- **No auto-pop**: `/od po` must be explicitly triggered by the user; never auto-restore.
