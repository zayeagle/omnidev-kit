# OmniDev Kit Installation & Usage Guide

> **To AI Assistant (Cursor / Claude Code / Codex, etc.)**: 
> When the user hands you this document, please immediately read all `.mdc` and `.md` files in this directory. Based on the user's development platform, automatically copy these rule files to the corresponding platform configuration directory (e.g., `.cursor/rules/` for Cursor, or `.claude/skills/` for Claude Code).
> 
> **⚠️ Core Merge Strategy**:
> If the user's project already has a `.cursorrules` file or `.cursor/rules/` directory, **ABSOLUTELY DO NOT overwrite them directly**! You must:
> 1. Read the user's existing rules.
> 2. Perform a **non-destructive merge** of OmniDev's rules with the user's existing architecture/language conventions (e.g., retain the user's original Go/React coding style rules, and only add OmniDev's workflow and state management mechanisms as supplementary clauses).
> 
> After installation, report success to the user and remind them that they can start the standard workflow by typing `/od` or directly stating their requirements.

## 1. What is OmniDev Kit?

OmniDev Kit is an advanced AI coding assistant enhancement toolkit that integrates the core essence of `obra/superpowers`, `everything-claude-code`, `planning-with-files`, and `OpenSpec`.

It forces the AI to follow this workflow:
1. **Brainstorming & Blueprint**: Think first, mine potential needs, output a global product state, and wait for user confirmation.
2. **Planning**: Break down features, prioritize, and wait for user confirmation.
3. **Spec-Driven & State Sync**: Persist state in `docs/omnidev-state/` using dual-state storage (YAML+MD), supporting interruption recovery and multi-person collaboration.
4. **Automated Testing & Verification**: Use MCP to simulate data flows and output test reports.
5. **Deployment Docs**: Automatically generate necessary configuration, environment dependency docs, and an "Efficiency Bill".

## 2. Automatic Installation Guide (For AI to Execute)

AI Assistant, please execute the following steps:

### Method A: Install from Remote Repository URL (Recommended)

If the user provides a **Git repository URL** (e.g., `https://github.com/zayeagle/omnidev-kit.git`) instead of a local path, execute the following steps:

1. Use the Shell tool to clone the repository to a **temporary directory** (e.g., `_omnidev-kit-tmp` in the system temp folder or project root).
2. Follow the same installation steps as **Method B** below, using the cloned temporary directory as the source. **Important**: In step 7, use the Git URL provided by the user as the `update_source_url` value.
3. After installation is complete, **delete the temporary directory** to keep the project clean.

This allows users to install OmniDev Kit with the command:
> `/od install https://github.com/zayeagle/omnidev-kit.git`

### Method B: Install from Local Directory

If the user has already cloned or downloaded `omnidev-kit` locally:

#### For Cursor Users:
1. Check if the `.cursor/rules/` folder exists in the project root; if not, create it.
2. Copy all `.mdc` files from the `omnidev-kit/rules/` directory into the `.cursor/rules/` directory.
3. Check if the `.cursor/skills/` folder exists in the project root; if not, create it.
4. Copy the `omnidev-kit/skills/od/` directory (containing `SKILL.md` and all subdirectories) into `.cursor/skills/od/`. This enables the `/od` slash command in Cursor's autocomplete.
5. Ensure the project root's `.gitignore` **does not contain** `.cursor/rules/` or `.cursor/skills/` (both should be committed to the repo).
6. Create a `docs/omnidev-state/` folder in the project root (for storing state and output docs).
7. Write the source repository URL into `docs/omnidev-state/config.json` so that `/od update` knows where to fetch future updates. If the file already exists, merge; if not, create it:
   ```json
   {
     "interactive_mode": true,
     "ask_mode_after_od": true,
     "update_source_url": "<the Git URL used for installation>"
   }
   ```

#### For Claude Code / Codex Users:
1. Check if `.claude/skills/` or the corresponding platform's skills directory exists in the project root.
2. Convert the rules under `omnidev-kit/rules/` to the corresponding platform's format (e.g., `SKILL.md`) and save them.
3. Copy the `omnidev-kit/skills/od/SKILL.md` as a reference for creating platform-specific skill triggers.
4. Create a `docs/omnidev-state/` folder in the project root.

## 3. Manual Installation Guide

If you want to install manually:
1. Copy the files in `omnidev-kit/rules/` to your IDE's rules directory (e.g., `.cursor/rules/` for Cursor).
2. Copy the `omnidev-kit/skills/od/` directory to `.cursor/skills/od/` (enables the `/od` slash command in Cursor's autocomplete).
3. Create a new folder named `docs/omnidev-state/` in the project root.
4. Say to the AI: "Start the OmniDev workflow, I want to develop [your requirement]" or directly type `/od [your requirement]`.

## 4. Output Artifacts Description

All documents generated driven by this toolkit (requirement blueprints, development plans, progress states, test reports, release notes) will be uniformly stored in the **`docs/omnidev-state/`** folder in the project root to avoid polluting the main codebase directory.