# OmniDev Activation Bootstrap (MANDATORY)

**Execute this file only when [trigger-gate.md](trigger-gate.md) activates (Signal A or B).**

Load path: resolve from installed skill root (`skills/od/engine/activation.md` or `.cursor/skills/od/engine/activation.md` or `~/.codex/skills/od/engine/activation.md`).

---

## 0. Trigger Gate (HARD — NO EXCEPTIONS)

→ **Authoritative spec**: [trigger-gate.md](trigger-gate.md)

**Quick decision** (current user message):

| Signal | Condition | Action |
|--------|-----------|--------|
| **A** | `/^\s*[\/$]od(\s|$|[\u4e00-\u9fff])/i` | Full bootstrap §1–§6 |
| **B** | Skill explicitly attached/invoked this turn (observable; if unsure → no) | Full bootstrap §1–§6 |
| **None** | No prefix, no explicit skill invoke | **STOP** — zero OmniDev; if looks like a bare command → [trigger-gate §2.1](trigger-gate.md) one-line tip |

**No Signal C.** Bare `1`/`n`/`continue` → normal chat (may show §2.1 tip). Resume → **`/od re` or `$od re` only**.

**Signal B (observable heuristics)**:
- **Cursor**: `@od` / SKILL **body** injected — NOT mere `available_skills`
- **Claude Code**: this turn contains `od/SKILL.md` body
- **Codex**: explicit invoke / SKILL body — NOT manifest-only

**Forbidden when triggered:**
- Jumping straight to code without loading phase instruction file
- Ignoring SKILL.md when Signal B fired
- Skipping Phase 0 (unless `/od -f` / `$od -f` or user confirms skip)

**Forbidden when NOT triggered:**
- Loading any OmniDev file "just in case"
- Touching `docs/omnidev-state/**` during normal chat

---

## 1. First Turn Protocol (ZERO text before tools)

On activation, **first response MUST be tool call(s)** — no assistant prose before tools.

**Minimum first-turn reads** (parallel when possible):

| # | File | Purpose |
|---|------|---------|
| 1 | `docs/omnidev-state/config.json` | interactive_mode, platform_override (§1.1 if missing) |
| 2 | This file (`activation.md`) | bootstrap |
| 3 | Target instruction file per §3 | phase or engine doc |

Optional same turn: `user-preferences.md`, `session-log.md` (`/od re` or in-progress).

### 1.1 Config Fallback (config.json not found)

```
Defaults:
  interactive_mode: true
  design_split: false
  confirmation_level: auto
  context_mode: slim
  sub_agents: auto
  platform_override: null
```

Proceed with defaults. Do NOT fail — Phase 0 may create `docs/omnidev-state/` + copy kit templates when missing.

---

## 2. Platform Detection (store for session)

Check `config.json` → `platform_override` first. If null, detect:

| Priority | Signal | Platform |
|----------|--------|----------|
| 1 | `AskUserQuestion` in tool list | **claude_code** |
| 2 | `AskQuestion` in tool list | **cursor** |
| 3 | `request_user_input` OR `create_thread` | **codex** |
| 4 | `Task` without AskQuestion/AskUserQuestion | **claude_code** (likely) |
| 5 | None of above | **cli_other** |

AskUserQuestion **before** AskQuestion, to avoid misdetecting dual-tool environments. Persist: `platform: cursor|claude_code|codex|cli_other`

→ PAL: SKILL.md §F.1 · Interactive: [interactive-prompt.md](interactive-prompt.md)

---

## 3. Command Router

Parse after stripping `/od` or `$od` (Signal A). Signal B with no prefix → treat full text as requirement payload:

| Pattern | Load file | Start phase |
|---------|-----------|-------------|
| *(Signal B, no prefix)* | `phases/00-assessment.md` | **0** |
| `h` / `help` | `engine/commands.md` | — |
| `re` / `resume` | `engine/session-memory.md` | resume |
| `re [payload]` / `resume [payload]` | `engine/session-memory.md` §6.1 | resume + payload |
| `ob` / `onboard` | `phases/00-assessment.md` | 0 |
| `-f [requirement]` | `phases/03-development.md` | 3 (fast) |
| `-p [requirement]` | `phases/01-blueprint.md` | 1 |
| `qa` | `phases/04-testing.md` | 4 |
| `ps` / `push` | `engine/special-flows.md` §1 | — |
| `ch` / `change` | `engine/special-flows.md` §2 | — |
| `gv` / `ln` / `st` / `po` / `x` / `cfg` / `compress` / `db` / `sy` / `rp` / `up` / `i` | per SKILL.md C.0 | — |
| `n` / `next` | current phase + 1 | continue |
| `ad` / `sk` / `bk` / `al` | current phase instruction | adjust |
| `[requirement]` (default) | `phases/00-assessment.md` | **0** |

**Default flow**: full bootstrap. Stale `in_progress` → interactive resume vs restart — do not skip bootstrap.

---

## 4. Workflow Execution Contract

1. Follow `context_requires` — load state **slices** only (B.18)
2. Execute phase steps in order — skip only via interactive confirm
3. **Phase 0 → next** after complexity confirm: **S→P3** · **M→P2** · **L/XL→P1**
4. Phase exit → silent learning → checkpoint (≤12 lines) → interactive prompt (B.8) → **STOP — WAIT**
5. Persist to state files — never conversation memory alone

---

## 5. Interactive Prompt Guarantee (PRIMARY MODE)

At **every** decision point:

1. Brief summary only (Phase 0 ≤6; checkpoint ≤12) — forbid full assessment / YAML in chat
2. **Same turn** [interactive-prompt.md](interactive-prompt.md):
   - Cursor → `AskQuestion` (§4) — **must call** when tool is in the list
   - Claude → `AskUserQuestion` (§5)
   - Codex → `request_user_input` (§6)
3. Native missing/fails → **§8 pseudo-popup** (`/od` or `$od` commands; forbid "reply 1/2/3") → **always STOP — WAIT** (forbid autoResolution / auto-continue)
4. **NEVER** end with prose-only "continue?" when `interactive_mode=true`
5. Advance via UI pick (same turn) or next full `/od`/`$od` command
6. Cover [interactive-prompt.md](interactive-prompt.md) §3 Decision Matrix (including S-level `phase0_s_fastpath`, Phase 2/4/5 gates)

**Failure fix**: Tool exists but was skipped → violation; re-call §4/§5/§6. Cursor without AskQuestion → §8 + switch model/Plan. Codex → §6.1 flag; **do not add** autoResolutionMs by default.

---

## 6. Activation Acknowledgment (after tools, ≤4 lines)

```
🚀 OmniDev activated · Platform: [cursor|claude_code|codex|cli_other]
📍 Route: [command] → Phase [N] — [phase name]
```

For `re [payload]`: `Payload: [text] → [route]`

Then phase work. Do not repeat SKILL.md.

---

## 7. Anti-Patterns (audit with `/od gv --scope compliance`)

| Anti-pattern | Correct behavior |
|--------------|------------------|
| `/od do X` → direct code | Phase 0 → recommended phases → then dev |
| Skill loaded but phase file unread | Read phase file first |
| AskQuestion failed → proceed | §8 + **WAIT** |
| Skip AskQuestion when tool exists | **Must call** §4 |
| Dump Phase 0 + YAML in chat | ≤6 lines + popup; details → session-log |
| "Reply 1/2/3" | `/od` or `$od` commands |
| Auto-continue after pseudo-popup | **STOP — WAIT** |
| Full state file in chat | Path pointer only (B.18) |

---

## 8. Cross-Platform Install Reminder

| Platform | Path |
|----------|------|
| Cursor | `.cursor/skills/od/` + `.cursor/rules/01-omnidev-workflow.mdc` (`alwaysApply: true`) + `AGENTS.md` |
| Claude Code | `.claude/skills/od/` or `~/.claude/skills/od/` + `CLAUDE.md` |
| Codex | `~/.codex/skills/od/` + optional `rules/03-omnidev-workflow.codex.md` |

| Symptom | Cause | Fix |
|---------|-------|-----|
| `/od` ignored | `alwaysApply: false` / drift | sync-skills; `alwaysApply: true`; `/od up` |
| Normal chat activates | Signal B false positive | trigger-gate — if unsure, do not activate |
| Stale `~/.cursor/skills/od/` | Old user-level copy | Prefer project `.cursor/skills/od/` |

Kit repo: `skills/od/` is SSOT → `powershell -File scripts/sync-skills.ps1` before commit.
