# OmniDev Kit Installation & Usage Guide

> **To AI Assistant (Cursor / Claude Code / Codex)**:
> Read this file and install per platform below. Copy **`skills/od/`** (full overwrite) and **`rules/`** (Cursor only, merge if needed).
>
> **Install strategy**
> - `skills/od/`: **full overwrite** — `rm -rf <target>/od/` then `cp -r` so renames/deletes in the kit are reflected.
> - `rules/` (Cursor): merge into `.cursor/rules/` if user rules exist.
> - Project state: create `docs/omnidev-state/` and copy **`docs/omnidev-state/config.json`** + **`metrics.json`** from this kit (do not hand-roll a partial config).

After install, tell the user: start with **`/od ob`** (onboard) or **`/od [requirement]`**.

---

## 1. What is OmniDev?

Workflow skill activated by **`/od` prefix**. Six phases (0–5): assess → blueprint → design/plan → dev → test → deploy.

**State** lives in `docs/omnidev-state/` (plans, design, tests, release notes, session-log). **Active + history** file pairs preserve document evolution.

See [README.md](README.md) for highlights; [SKILL.md](skills/od/SKILL.md) for full rules.

### Platforms

| Platform | Prompts | Workers | Skill path |
|----------|---------|---------|------------|
| **Cursor** | `AskQuestion` | Built-in | `.cursor/skills/od/` |
| **Claude Code** | `AskUserQuestion` | `Task` | `.claude/skills/` or `~/.claude/skills/` |
| **Codex** | `request_user_input` | `create_thread` | `~/.codex/skills/od/` |

PAL details: `skills/od/SKILL.md` §F.

**Codex Default-mode popups** (recommended):

```toml
# ~/.codex/config.toml
[features]
default_mode_request_user_input = true
```

Then restart Codex. Without this, OmniDev uses structured text fallback (still works).

---

## 2. Install Methods

### Method A: Remote URL (recommended)

User command:

```
/od install https://github.com/zayeagle/omnidev-kit.git
```

1. Clone repo to a temp dir.
2. Install per platform (Method B).
3. Set `update_source_url` in `config.json` to that Git URL.
4. Remove temp dir.

### Method B: Local kit directory

#### Cursor

1. Create `.cursor/rules/` if missing; copy `rules/*.mdc`.
2. **Full overwrite**: `rm -rf .cursor/skills/od/` → copy `skills/od/` → `.cursor/skills/od/`.
3. Commit `.cursor/rules/` and `.cursor/skills/` (do not gitignore them unless intentional).
4. Create `docs/omnidev-state/`; copy `config.json` + `metrics.json` from kit `docs/omnidev-state/`.
5. Set `update_source_url` in `config.json` if installing from a fork.

#### Claude Code

1. Target: `.claude/skills/od/` (project) or `~/.claude/skills/od/` (user).
2. **Full overwrite** `skills/od/` into target.
3. Append to `CLAUDE.md` (do not overwrite):

   ```markdown
   ## OmniDev Workflow
   Type `/od` to activate. See `.claude/skills/od/SKILL.md`.
   ```

4. Create `docs/omnidev-state/`; copy `config.json` + `metrics.json` from kit.

#### Codex

1. **Full overwrite**: `~/.codex/skills/od/` ← `skills/od/`.
2. Optional: copy `rules/03-omnidev-workflow.codex.md` for trigger hints.
3. `codex skills refresh` or restart session.
4. Create `docs/omnidev-state/`; copy `config.json` + `metrics.json`.
5. Recommend `platform_override: "codex"` in `config.json` if auto-detect fails.
6. Enable `default_mode_request_user_input` in `~/.codex/config.toml` (see §1).

---

## 3. Config template

**Copy the kit file** — do not omit keys:

`docs/omnidev-state/config.json` (from this repo) includes:

| Key | Purpose |
|-----|---------|
| `interactive_mode` | Popup-first UX (default `true`) |
| `sub_agents` / `phase_workers` | Task & phase worker spawn (`auto`) |
| `design_split` | Design index + `features/*.md` |
| `e2e_required_fullstack` / `unit_gate_blocking` | Test gates |
| `deploy_modes` / `deploy_use_makefile` / `deploy_autonomy` | Phase 5 deploy |
| `max_resident_lines` | Context budget (300) |
| `update_source_url` | `/od up` source |

Merge existing project values only for URLs and overrides; new installs should start from the kit template.

---

## 4. Output artifacts

Under **`docs/omnidev-state/`**:

| Path | Content |
|------|---------|
| `00-project-context.md` | Stack, domain knowledge |
| `[branch]/01-blueprint.md` … `06-release-notes.md` | Phase outputs |
| `[branch]/*-history.md` | Append-only document history |
| `[branch]/session-log.md` | Resume checkpoint (`/od re`) |
| `metrics.json` | Silent telemetry |
| `config.json` | Workflow toggles |

Phase 5 may add project **`Makefile`** and **`deploy/`** (docker · k8s · binary one-click scripts).

---

## 5. Manual install (short)

| Platform | Steps |
|----------|-------|
| Cursor | rules → `.cursor/rules/`; skills → `.cursor/skills/od/`; state dir + config |
| Claude | skills → `.claude/skills/od/`; CLAUDE.md trigger; state dir + config |
| Codex | skills → `~/.codex/skills/od/`; state dir + config; Codex popup flag |

Then: `/od ob` or `/od [requirement]`.

---

## 6. Platform notes for installers

- Map tools via **PAL** (`SKILL.md` §F) — never hardcode Cursor-only APIs on Claude/Codex.
- **Never auto-commit** — `/od ps` only when user asks.
- **Legacy deploy**: Phase 5 audits existing Makefile/deploy; modifications need user consent unless `deploy_autonomy: full` or `/od al`.
- **Codex compaction**: persist to state files before long tool runs (`session-memory.md`, §F.8).
