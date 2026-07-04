# OmniDev Activation Bootstrap (MANDATORY)

**Every `/od` message MUST execute this file before any other OmniDev action.**

Load path: resolve from installed skill root (`skills/od/engine/activation.md` or `.cursor/skills/od/engine/activation.md` or `~/.codex/skills/od/engine/activation.md`).

---

## 0. Prefix Gate (HARD — NO EXCEPTIONS)

**Activate OmniDev** when the user's **current message** matches:

```
/^\s*\/od(\s|$|[\u4e00-\u9fff])/i
```

Matches: `/od`, `/od `, `/od h`, `/od 实现登录`, `/OD re`, `/od\t需求`  
Does NOT match: `请用 /od 实现` (not at start), `code/od`, normal chat without `/od` prefix.

| Match | Action |
|-------|--------|
| ✅ Prefix match | **MANDATORY** OmniDev workflow — proceed §1–§6 |
| ❌ No match | Do NOT apply OmniDev; normal conversation |

**Forbidden when prefix matches:**
- Jumping straight to code without loading phase instruction file
- Ignoring SKILL.md because "skill wasn't suggested"
- Treating `/od [需求]` as a casual coding request
- Skipping Phase 0 assessment for new requirements (unless `/od -f` or explicit `/od sk`)

---

## 1. First Turn Protocol (ZERO text before tools)

On `/od` activation, **first response MUST be tool call(s)** — no assistant prose before tools.

**Minimum first-turn reads** (parallel when possible):

| # | File | Purpose |
|---|------|---------|
| 1 | `docs/omnidev-state/config.json` | interactive_mode, platform_override |
| 2 | This file (`activation.md`) | bootstrap (may already be in context from SKILL) |
| 3 | Target instruction file per §3 | phase or engine doc |

Optional same turn: `user-preferences.md`, `session-log.md` (if `/od re` or in-progress branch).

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

Parse message after `/od`:

| Pattern | Load file | Start phase |
|---------|-----------|-------------|
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

**Default `/od [需求]` flow**: ALWAYS start Phase 0 unless `session-log.md` has `status: in_progress` → offer resume via interactive prompt.

---

## 4. Workflow Execution Contract

After loading target instruction file:

1. Follow its `context_requires` — load state file **slices** only (B.18)
2. Execute phase steps in order — **no skipping** unless user confirms via interactive prompt
3. At every checkpoint → [interactive-prompt.md](interactive-prompt.md) — **STOP & WAIT**
4. On phase exit → silent learning → checkpoint (≤12 lines) → interactive prompt (B.8)
5. Persist decisions to state files — never rely on conversation memory alone

---

## 5. Interactive Prompt Guarantee (PRIMARY MODE)

At **every** decision point (Phase 0 sizing, Phase 1 approach, checkpoints, Pre-Dev, Change Impact):

1. Output brief summary (≤12 lines if checkpoint)
2. **Same turn**: call [interactive-prompt.md](interactive-prompt.md) native tool:
   - Claude Code → `AskUserQuestion` (§4 template)
   - Codex → `request_user_input` (§5 template) — try in **all modes**
   - Cursor → `AskQuestion`
3. If native fails → **pseudo-popup §E** immediately (structured table, not plain prose)
4. **NEVER** end turn with "是否继续?" without tool call when `interactive_mode=true`
5. User may always reply with `/od` command or number instead of clicking UI

**Failure mode fix**: "弹窗不触发" → agent skipped tool call; re-invoke with §4/§5 template. Codex Default mode → enable `default_mode_request_user_input` (interactive-prompt §7).

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
| AskQuestion failed → proceed anyway | Pseudo-popup §E + WAIT; or re-call AskUserQuestion |
| interactive_mode true but no prompt shown | **Must call** AskUserQuestion/request_user_input same turn (§4/§5) |
| Claude/Codex: prose options without tool | **Violation** — invoke tool with template |
| Codex Default mode, no popup | Enable `default_mode_request_user_input`; use pseudo-popup §E until enabled |
| Full state file pasted in chat | Path pointer only (B.18) |

---

## 8. Cross-Platform Install Reminder

If workflow doesn't trigger, verify skill is installed:

| Platform | Path |
|----------|------|
| Cursor | `.cursor/skills/od/` + `rules/01-omnidev-workflow.mdc` |
| Claude Code | `.claude/skills/od/` or `~/.claude/skills/od/` |
| Codex | `~/.codex/skills/od/` + optional `rules/03-omnidev-workflow.codex.md` |

Run `/od up` or reinstall from omnidev-kit repo.
