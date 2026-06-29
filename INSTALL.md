# OmniDev Kit Installation & Usage Guide

> **To AI Assistant (Cursor / Claude Code / Codex / etc.)**:
> When the user hands you this document, please immediately read all `.md`, `.mdc`, and rule files in this directory. Based on the user's development platform, automatically copy these files to the corresponding platform configuration directory.
>
> **⚠️ Core Merge Strategy**:
> If the user's project already has platform-specific config files (e.g., `.cursorrules`, `.cursor/rules/`, `CLAUDE.md`, `~/.codex/skills/`), **ABSOLUTELY DO NOT overwrite them directly**! You must:
> 1. Read the user's existing rules.
> 2. Perform a **non-destructive merge** of OmniDev's rules with the user's existing architecture/language conventions (e.g., retain the user's original Go/React coding style rules, and only add OmniDev's workflow and state management mechanisms as supplementary clauses).
>
> After installation, report success to the user and remind them that they can start the standard workflow by typing `/od` or directly stating their requirements.

---

## 1. What is OmniDev Kit?

OmniDev Kit is an advanced AI coding assistant enhancement toolkit that transforms the AI from "a typist who only writes code on command" into a **"senior R&D engineer who understands cost control, architecture design, writes their own tests, and never forgets."**

It forces the AI to follow this workflow:
1. **Assessment & Blueprint**: Think first, analyze complexity, output a global product state, and wait for user confirmation.
2. **Planning**: Break down features, prioritize, and wait for user confirmation.
3. **Spec-Driven & State Sync**: Persist state in `docs/omnidev-state/` supporting interruption recovery and multi-person collaboration.
4. **Automated Testing & Verification**: Dependency analysis → Mock strategy → Scenario coverage → Resilience testing.
5. **Deployment Docs**: Automatically generate necessary configuration, environment dependency docs, and an "Efficiency Bill".

### Supported Platforms

| Platform | Slash Command | Interactive Prompt | Sub-Agent | Skill Discovery | Full Workflow |
|----------|:---:|:---:|:---:|:---:|:---:|
| **Cursor** | ✅ Native | ✅ `AskQuestion` | ✅ Built-in workers | ✅ `.cursor/skills/` | ✅ Full |
| **Claude Code** | ✅ Via SKILL.md | ✅ `AskUserQuestion` | ✅ `Task` tool | ✅ `.claude/skills/` | ✅ Full |
| **Codex** | ✅ Via SKILL.md | ✅ `request_user_input` (Plan mode) + text fallback | ✅ Thread-based (`create_thread` + `send_message_to_thread`) | ✅ `~/.codex/skills/` | ✅ Full |

See `skills/od/SKILL.md` §F for the full Platform Abstraction Layer.

---

## 2. Automatic Installation Guide (For AI to Execute)

### Method A: Install from Remote Repository URL (Recommended)

If the user provides a **Git repository URL** (e.g., `https://github.com/zayeagle/omnidev-kit.git`) instead of a local path, execute the following steps:

1. Use the Shell tool to clone the repository to a **temporary directory** (e.g., `_omnidev-kit-tmp` in the system temp folder or project root).
2. Follow the same installation steps as **Method B** below, using the cloned temporary directory as the source. **Important**: In step 7, use the Git URL provided by the user as the `update_source_url` value.
3. After installation is complete, **delete the temporary directory** to keep the project clean.

This allows users to install OmniDev Kit with the command:
> `/od install https://github.com/zayeagle/omnidev-kit.git`

### Method B: Install from Local Directory

If the user has already cloned or downloaded `omnidev-kit` locally, follow the section below that matches the user's AI coding assistant platform.

---

#### 🖥️ For Cursor Users

1. Check if the `.cursor/rules/` folder exists in the project root; if not, create it.
2. Copy all `.mdc` files from the `omnidev-kit/rules/` directory into the `.cursor/rules/` directory.
3. Check if the `.cursor/skills/` folder exists in the project root; if not, create it.
4. Copy the entire `omnidev-kit/skills/od/` directory (containing `SKILL.md` and all subdirectories) into `.cursor/skills/od/`. This enables the `/od` slash command in Cursor's autocomplete.
5. Ensure the project root's `.gitignore` **does not contain** `.cursor/rules/` or `.cursor/skills/` (both should be committed to the repo).
6. Create a `docs/omnidev-state/` folder in the project root (for storing state and output docs).
7. Copy `docs/omnidev-state/metrics.json` template from the kit (or create empty schema per `skills/od/engine/metrics.md`) for governance and dashboard tracking.
8. Write the source repository URL into `docs/omnidev-state/config.json` so that `/od update` knows where to fetch future updates. If the file already exists, merge; if not, create it:
   ```json
   {
     "interactive_mode": true,
     "ask_mode_after_od": true,
     "auto_checkpoint": false,
     "confirmation_level": "auto",
     "coverage_gate": false,
     "sub_agents": "auto",
     "design_split": true,
     "log_token_estimates": true,
     "max_read_lines": 150,
     "context_mode": "slim",
     "max_hot_lines": 150,
     "max_resident_lines": 300,
     "checkpoint_max_lines": 12,
     "update_source_url": "<the Git URL used for installation>"
   }
   ```

---

#### 🖥️ For Claude Code Users

1. Determine install scope — **project-level** (`.claude/` in project root) or **user-level** (`~/.claude/`). If the user is sharing the project with a team, prefer project-level.
2. Create the skills directory (project: `.claude/skills/od/`, or user: `~/.claude/skills/od/`).
3. Copy the entire `omnidev-kit/skills/od/` directory (containing `SKILL.md` and all subdirectories) into the target `skills/od/` directory. This enables OmniDev as a Claude Code custom slash command via SKILL.md.
4. Check if `CLAUDE.md` exists in the project root. If it does, **append** (do not overwrite) the following trigger reference:
   ```markdown
   ## OmniDev Workflow
   To activate the OmniDev workflow, type `/od` followed by a command (e.g., `/od h` for help, `/od ob` for project onboard).
   See `.claude/skills/od/SKILL.md` for the full specification.
   ```
   If `CLAUDE.md` does not exist, create it with the above content plus minimal project context.
5. Create a `docs/omnidev-state/` folder in the project root (for storing state and output docs).
6. Copy `docs/omnidev-state/metrics.json` template from the kit, or create empty schema per `skills/od/engine/metrics.md`.
7. Write config.json per Cursor step 8 above.

---

#### 🖥️ For Codex Users

1. Create the user-level skills directory: `~/.codex/skills/od/` (Codex skills are user-level by convention).
2. Copy the entire `omnidev-kit/skills/od/` directory (containing `SKILL.md` and all subdirectories) into `~/.codex/skills/od/`. Codex will detect this skill via its `SKILL.md` frontmatter.
3. After copying, run a skill cache refresh if available: `codex skills refresh` or restart the Codex session.
4. Create a `docs/omnidev-state/` folder in the project root (for storing state and output docs).
5. Copy `docs/omnidev-state/metrics.json` template from the kit, or create empty schema per `skills/od/engine/metrics.md`.
6. Write config.json per Cursor step 8 above, including `platform_override: "codex"` for reliable platform detection:: The `interactive_mode` setting controls whether OmniDev uses `request_user_input` for checkpoints and skill selection. When `interactive_mode: false`, prompts are text-only.
>
> **Codex Plan mode caveat**: `request_user_input` is only available in Plan mode. In non-Plan mode sessions, OmniDev automatically falls back to numbered text prompts per SKILL.md §F.2. Set `OMNIDEV_PLATFORM=codex` or `config.json` → `platform_override: "codex"` if platform auto-detection fails.
>
> **Context compaction**: Codex auto-compacts conversations. OmniDev's Codex-specific protocols (SKILL.md §F.8, session-memory.md §9) ensure state survives compaction through defensive disk writes and YAML-first session-log design.
>
> **Multi-agent via threads**: Use `create_thread` + `send_message_to_thread` for parallel task execution on Codex (SKILL.md §F.3). Overhead is ~4000 tokens per thread (not 8000).

---

## 3. Manual Installation Guide

If you want to install manually:

### Cursor
1. Copy files in `omnidev-kit/rules/` to `.cursor/rules/`.
2. Copy `omnidev-kit/skills/od/` to `.cursor/skills/od/`.
3. Create `docs/omnidev-state/` in project root.
4. Type `/od [your requirement]` or `/od ob` to onboard.

### Claude Code
1. Copy `omnidev-kit/skills/od/` to `.claude/skills/od/`.
2. Add `/od` trigger reference to `CLAUDE.md`.
3. Create `docs/omnidev-state/` in project root.
4. Type `/od [your requirement]` or `/od ob` to onboard.

### Codex
1. Copy `omnidev-kit/skills/od/` to `~/.codex/skills/od/`.
2. Create `docs/omnidev-state/` in project root.
3. Type `/od [your requirement]` or `/od ob` to onboard.

---

## 4. Output Artifacts Description

All documents generated by this toolkit (requirement blueprints, development plans, progress states, test reports, release notes) are stored in **`docs/omnidev-state/`**. Phase 5 (Deploy) produces `06-release-notes.md` per `skills/od/phases/05-deploy.md`.

---

## 5. Platform Adaptation Reference

For AI assistants installing on Claude Code or Codex: when engine files reference platform-specific mechanisms (e.g., `AskQuestion`, built-in workers, `.cursor/mcp.json`), consult the Platform Abstraction Layer at `skills/od/SKILL.md` §F for the correct platform mapping. Do NOT hardcode Cursor-specific tools on non-Cursor platforms.
