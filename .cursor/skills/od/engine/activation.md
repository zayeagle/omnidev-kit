# OmniDev Activation Bootstrap (MANDATORY)

**Execute this file only when [trigger-gate.md](trigger-gate.md) activates (Signal A or B).**

Load path: resolve from installed skill root (`skills/od/engine/activation.md` or `.cursor/skills/od/engine/activation.md` or `~/.codex/skills/od/engine/activation.md`).

---

## 0. Trigger Gate (HARD — NO EXCEPTIONS)

→ **Authoritative spec**: [trigger-gate.md](trigger-gate.md)

**Quick decision** (current user message):

| Signal | Condition | Action |
|--------|-----------|--------|
| **A** | `/^\s*\/od(\s|$|[\u4e00-\u9fff])/i` | Full bootstrap §1–§6 |
| **B** | Skill explicitly attached/invoked this turn | Full bootstrap §1–§6 |
| **None** | No `/od`, no skill attach | **STOP** — zero OmniDev loading |

**No Signal C.** Bare `1`/`n`/`continue` without `/od` → normal chat. Resume → **`/od re` only** (disk via `session-log.md`).

**Platform skill-invoke signals (Signal B)**:
- **Cursor**: `manually_attached_skills` / `@od` / SKILL body inlined — NOT mere `available_skills` listing
- **Claude Code**: SKILL.md loaded into active context this turn
- **Codex**: od skill invoked for this message — NOT manifest-only

**Forbidden when triggered (A/B/C):**
- Jumping straight to code without loading phase instruction file
- Ignoring SKILL.md because "skill wasn't suggested" (if Signal B, skill IS attached)
- Treating requirements as casual coding without Phase 0 (unless `/od -f` or explicit skip)

**Forbidden when NOT triggered:**
- Loading any OmniDev file "just in case"
- Touching `docs/omnidev-state/**` during normal chat

---

## 1. First Turn Protocol (ZERO text before tools)

On `/od` activation, **first response MUST be tool call(s)** — no assistant prose before tools.

**Minimum first-turn reads** (parallel when possible):

| # | File | Purpose |
|---|------|---------|
| 1 | `docs/omnidev-state/config.json` | interactive_mode, platform_override (see §1.1 if not found) |
| 2 | This file (`activation.md`) | bootstrap (may already be in context from SKILL) |
| 3 | Target instruction file per §3 | phase or engine doc |

Optional same turn: `user-preferences.md`, `session-log.md` (if `/od re` or in-progress branch).

### 1.1 Config Fallback (config.json not found)

If `docs/omnidev-state/config.json` does not exist (first run, greenfield project):

```
Defaults:
  interactive_mode: true
  design_split: false
  confirmation_level: auto
  context_mode: slim
  sub_agents: auto
  platform_override: null
```

Proceed with these defaults. Do NOT fail or ask the user — initialization happens silently in Phase 0.

---

## 2. Platform Detection (store for session)

Check `config.json` → `platform_override` first. If null, detect:

| Priority | Signal | Platform |
|----------|--------|----------|
| 1 | `AskQuestion` in tool list | **cursor** |
| 2 | `AskUserQuestion` in tool list | **claude_code** |
| 3 | `request_user_input` OR `create_thread` in tool list | **codex** |
| 4 | `Task` tool without AskQuestion | **claude_code** (likely) |
| 5 | None of above | **cli_other** |

Persist to session-log frontmatter: `platform: cursor|claude_code|codex|cli_other`

→ Full PAL: SKILL.md §F.1 · Interactive: [interactive-prompt.md](interactive-prompt.md)

---

## 3. Command Router

Parse message after `/od` (Signal A), or use full user text as payload (Signal B without prefix):

| Pattern | Load file | Start phase |
|---------|-----------|-------------|
| *(Signal B, no `/od` prefix)* | `phases/00-assessment.md` | **0** (payload = user message) |
| `/od h`, `/od help` | `engine/commands.md` | — |
| `/od re`, `/od resume` | `engine/session-memory.md` | resume from session-log |
| `/od re [payload]`, `/od resume [payload]` | `engine/session-memory.md` §6.1 | resume + route payload per workflow |
| `/od ob`, `/od onboard` | `phases/00-assessment.md` | 0 |
| `/od -f [需求]` | `phases/03-development.md` | 3 (fast) |
| `/od -p [需求]` | `phases/01-blueprint.md` | 1 |
| `/od qa` | `phases/04-testing.md` | 4 |
| `/od ps`, `/od push` | `engine/special-flows.md` §1 | — |
| `/od ch`, `/od change` | `engine/special-flows.md` §2 | — |
| `/od gv`, `/od ln`, `/od st`, `/od po`, `/od x`, `/od cfg`, `/od compress`, `/od db`, `/od sy`, `/od rp`, `/od up`, `/od i` | per SKILL.md C.0 | — |
| `/od n`, `/od next` | current phase + 1 | continue |
| `/od ad`, `/od sk`, `/od bk`, `/od al` | current phase instruction | adjust |
| `/od [需求]` (default) | `phases/00-assessment.md` | **0** |

**Default `/od [需求]` flow**: ALWAYS full bootstrap (Signal A). If `session-log.md` has stale `in_progress`, offer resume vs restart via interactive prompt — do not skip bootstrap.

---

## 4. Workflow Execution Contract

After loading target instruction file:

1. Follow its `context_requires` — load state file **slices** only (B.18)
2. Execute phase steps in order — **no skipping** unless user confirms via interactive prompt
3. **Phase 0 → next phase routing** (after user confirms complexity):
   - **S**: Phase 0 → **Phase 3** (Dev) directly
   - **M**: Phase 0 → **Phase 2** (Plan), skip Phase 1 blueprint
   - **L/XL**: Phase 0 → **Phase 1** (Blueprint), full workflow
4. On phase exit → silent learning → checkpoint (≤12 lines) → interactive prompt (B.8)
5. Persist decisions to state files — never rely on conversation memory alone

---

## 5. Interactive Prompt Guarantee (PRIMARY MODE)

At **every** decision point (Phase 0 sizing, Phase 1 approach, checkpoints, Pre-Dev, Change Impact):

1. Output brief summary only（Phase 0 ≤6 行；checkpoint ≤12 行）— **禁止**把完整评估 / YAML 元数据贴进对话
2. **Same turn**: call [interactive-prompt.md](interactive-prompt.md) native tool:
   - Cursor → `AskQuestion`（§4 模板）— 工具在列表中时 **必调**
   - Claude Code → `AskUserQuestion`（§5 模板）
   - Codex → `request_user_input`（§6 模板）— try in **all modes**
3. If native missing/fails → **pseudo-popup §8** immediately（干净表格 + `/od` 命令；禁止「回复 1/2/3」）
4. **NEVER** end turn with "是否继续?" / 选项散文 without tool call when `interactive_mode=true`
5. User advances via **full `/od` command** in next message (`/od n`, `/od ad`, …) or UI pick — bare numbers/aliases alone do **NOT** activate

**Failure mode fix**: "弹窗不触发" → agent skipped tool call; re-invoke with §4/§5/§6 template. Cursor 无 `AskQuestion` → §8 + 换模型/Plan 提示。Codex Default → enable `default_mode_request_user_input`（§7）。

---

## 6. Activation Acknowledgment (after tools, ≤4 lines)

After first tool batch completes, output briefly:

```
🚀 OmniDev 已激活 · 平台: [cursor|claude_code|codex|cli_other]
📍 路由: [command] → Phase [N] — [phase name]
```

For `/od re [payload]`, include: `Payload: [text] → [route]`

Then proceed with phase work. Do not repeat SKILL.md content.

---

## 7. Anti-Patterns (audit with `/od gv --scope compliance`)

| Anti-pattern | Correct behavior |
|--------------|------------------|
| `/od 做X` → direct code edit | Phase 0 → (recommended phases) → then dev |
| Skill loaded but phase file not read | Read phase file via tool first |
| AskQuestion failed → proceed anyway | Pseudo-popup §8 + WAIT; or re-call native tool |
| Cursor: skip AskQuestion when tool exists | **Must call** §4 template same turn |
| interactive_mode true but no prompt shown | **Must call** AskQuestion / AskUserQuestion / request_user_input (§4/§5/§6) |
| Claude/Codex/Cursor: prose options without tool | **Violation** — invoke tool with template |
| Dump full Phase 0 assessment + YAML meta in chat | ≤6 行摘要 + 弹窗；详情写 session-log |
| Tell user「回复 1/2/3」 | Always show `/od` commands |
| Codex Default mode, no popup | Enable `default_mode_request_user_input`; use pseudo-popup §8 until enabled |
| Full state file pasted in chat | Path pointer only (B.18) |

---

## 8. Cross-Platform Install Reminder

If workflow doesn't trigger, verify skill is installed:

| Platform | Path |
|----------|------|
| Cursor | `.cursor/skills/od/` + `.cursor/rules/01-omnidev-workflow.mdc` (`alwaysApply: true`) + root `AGENTS.md` |
| Claude Code | `.claude/skills/od/` or `~/.claude/skills/od/` + `CLAUDE.md` trigger line |
| Codex | `~/.codex/skills/od/` (full copy, not partial) + optional `rules/03-omnidev-workflow.codex.md` |

### Common root causes

| Symptom | Cause | Fix |
|---------|-------|-----|
| `/od` ignored | Trigger rule `alwaysApply: false` | Set `alwaysApply: true`; run `/od up` |
| OmniDev loads on normal chat | Skill listed but not gated | Follow [trigger-gate.md](trigger-gate.md) — only A/B/C activate |
| Skill attached but no workflow | Agent skipped Read | Signal B requires explicit SKILL + activation read |
| Stale user-level skill | `~/.cursor/skills/od/` incomplete | Prefer project `.cursor/skills/od/` |

Run `/od up` or reinstall from omnidev-kit repo.
