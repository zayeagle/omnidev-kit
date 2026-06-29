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

2. If `interactive_mode` is `true`, use platform interactive prompt (SKILL.md §F.2):
   - **One-click auto**: `git add .` → auto-generate message → commit → push.
   - **Manual select**: wait for user to `git add`, then generate message.
   - **Cancel**.
3. If `interactive_mode` is `false`, wait for user to `git add`, then generate message.
4. Confirm message (platform interactive prompt §F.2 if interactive).
5. `git commit` + `git push origin <current-branch>`.

**Never commit unless user explicitly confirms** (aligns with git safety rules).

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

- **Lightweight**: modifies details within an existing feature (e.g., field rename, validation rule change). Strategy: update `04-design.md` + `05-test-plan.md` inline with CHANGE_LOG markers. Do NOT regenerate `02-plan.md`.
- **Structural**: alters architecture, data flow, or feature boundaries. Strategy: full regeneration of `04-design.md` + `05-test-plan.md` + `02-plan.md` traceability.

Present the classification to user for confirmation before proceeding.

For Structural changes: spawn 1 worker per feature to regenerate `04-design.md` sections in parallel, then 1 worker per feature for `05-test-plan.md`. Main agent handles `02-plan.md` traceability merge and final sync report.

2. **变更影响报告**: Present a structured impact report:

   ```
   📋 **需求变更影响分析**
   📝 变更描述: [description]
   📂 受影响文件:
     - 01-blueprint.md: [impact description]
     - 02-plan.md: [impact description]
     - ...
   ✅ 未受影响: [list]
   ⏳ 尚未生成: [list — will be generated in later phases]
   ```

3. If interactive, use platform interactive prompt (SKILL.md §F.2) to confirm: Proceed / Revise / Cancel.
4. **全局文档同步** (per B.14, after confirmation):
   - Archive old versions of affected files (append `<!-- CHANGE_LOG -->` marker).
   - Update each affected state file to reflect the new requirements.
   - Regenerate blueprint/plan sections as needed.
5. **同步完成报告**: Output final sync summary per B.14 protocol.

### 2.2 Sub-Agent Dispatch for Structural Changes

Same as §2.1 Structural path. On worker failure, follow [context-protocol.md](context-protocol.md) §10.

---

## 3. Report (`/od report` / `/od rp`)

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
4. Include: executive summary, AI-assisted achievements, progress, blockers, next week plan, metrics aggregates from [metrics.md](metrics.md).

---

## 3.1 Next-Step Prompt Format (B.8)

After every phase checkpoint, present **2–4 next actions** via platform interactive prompt (SKILL.md §F.2) (Chinese labels when `interactive_mode=true`):

| Option | Typical Label (zh) |
|--------|-------------------|
| Continue next phase | 继续下一阶段 (`/od n`) |
| Revise current output | 修订当前产出 (`/od ad`) |
| Skip optional phase | 跳过 [phase] (`/od sk`) |
| End / Push / Deploy | 结束 / 推送 / 部署 (context-dependent) |
| Help | 查看命令 (`/od h`) — **always last option** |

**Rules**:
- MUST STOP and WAIT after presenting options.
- User may reply with number, alias, or full command.
- For S/M complexity, offer "跳过确认直接继续" only when B.15 allows reduced confirmations.

---

## 4. Context Pruning (`/od compress`)

**Triggers:** `03-progress.md` > 100 lines, HOT+WARM > 300 lines, 15+ turns in same phase, or `/od compress`.

**Action:**
1. Archive resolved logs to `docs/omnidev-state/archive/progress-archive-[date].md`.
2. Condense `03-progress.md` to frontmatter + blockers + 3 active tasks (≤50 lines).
3. Execute [context-occupancy.md](context-occupancy.md) §9 purge + occupancy report.
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

---

## 6. Update (`/od up`)

```yaml
context_requires:
  read:
    - docs/omnidev-state/config.json
  skip:
    - all other state files
```

**Source**: Use `update_source_url` from `config.json`. Default: `https://github.com/zayeagle/omnidev-kit.git`.

**Steps**:

1. Clone remote to temp: `git clone --depth 1 <update_source_url> _omnidev-kit-tmp`
2. Build file manifest:

   | Remote source path | Local target path (Cursor / Claude Code / Codex) |
   |--------------------|--------------------------------------------------|
   | `_omnidev-kit-tmp/rules/` | `.cursor/rules/` (Cursor only; others skip) |
   | `_omnidev-kit-tmp/skills/od/` | `.cursor/skills/od/` / `.claude/skills/od/` (or `~/.claude/skills/od/`) / `~/.codex/skills/od/` |

   **Platform mapping for step 5 (apply)**: Consult SKILL.md §F.7 for per-platform install targets. Key rules:
   - **Cursor**: Copy rules → `.cursor/rules/`, skills → `.cursor/skills/od/`.
   - **Claude Code**: Copy skills → `.claude/skills/od/` (project-level, fallback to `~/.claude/skills/od/` user-level). Skip `rules/`.
   - **Codex**: Copy skills → `~/.codex/skills/od/` (user-level only). Skip `rules/`.
   - **Platform auto-detection**: Use §F.1 table at the start of the update flow to determine current platform.

   **Kit repo layout**: Source files live at repo root `skills/od/` and `rules/` — same structure as install source.

3. Diff & present change summary (New / Changed / Obsolete / Unchanged).
4. Confirm with user — update MUST NOT proceed without explicit approval.
5. Apply changes (only after confirmation).
6. Cleanup: Delete `_omnidev-kit-tmp/`.
7. Report result: New N / Changed N / Deleted N / Unchanged N.

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

Clone to `_omnidev-kit-tmp`, then copy to platform-specific targets per SKILL.md §F.7:

1. **Detect platform** using §F.1 table (auto-detect or `config.json` `platform_override`).
2. **Copy skills**: `_omnidev-kit-tmp/skills/od/` → platform target path (Cursor: `.cursor/skills/od/`, Claude Code: `.claude/skills/od/` or `~/.claude/skills/od/`, Codex: `~/.codex/skills/od/`).
3. **Copy rules**: Cursor only — `_omnidev-kit-tmp/rules/` → `.cursor/rules/`. Claude Code and Codex skip this step (they trigger via SKILL.md).
4. Write `update_source_url` to `docs/omnidev-state/config.json`.
5. Cleanup: Delete `_omnidev-kit-tmp/`.

**Non-destructive merge**: Never overwrite existing user rules without reading and merging first. For Codex, run `codex skills refresh` if available after copying.
