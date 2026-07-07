# OmniDev Unified Trigger Gate

**Single source of truth for when to load OmniDev.** All platforms consult via [activation.md](activation.md) §0.

---

## 1. Activate — ONLY two entry signals

**No session-context inference. No bare-number checkpoint replies. No same-thread continuation.**

### Signal A — `/od` prefix

```
/^\s*\/od(\s|$|[\u4e00-\u9fff])/i
```

Matches: `/od`, `/od h`, `/od n`, `/od re`, `/od implement login` (CJK after `/od` also matches)  
Does NOT match: `please use /od to …` (not at start), `code/od`, bare `1` / `n` / `continue`

### Signal B — Explicit skill invocation (platform-specific)

Skill **listed** is **NOT** enough — must be **actively loaded this turn**:

| Platform | YES | NO (normal chat) |
|----------|-----|------------------|
| **Cursor** | `@od` attached / `manually_attached_skills` / SKILL body inlined | od only in `available_skills` |
| **Claude Code** | `od/SKILL.md` loaded into active context this turn | on disk, not loaded |
| **Codex** | od skill invoked for this message | manifest-only |

When Signal B fires without `/od` prefix → treat as `/od [requirement]` → Phase 0 (full bootstrap).

---

## 2. Do NOT activate (strict)

When **neither** Signal A nor B:

| Forbidden |
|-----------|
| Read `SKILL.md`, `activation.md`, phase/engine files |
| Read/write `docs/omnidev-state/**` |
| OmniDev checkpoints / interactive prompts |
| Infer OmniDev from prior chat turns, disk `in_progress`, or checkpoint context |
| Treat bare `1`, `n`, `y`, `continue` as workflow input |

**Normal chat** — even if previous turn was OmniDev, even if `session-log` is `in_progress`.

---

## 3. Interactive iteration (strict `/od` commands)

Workflow advances **only** when user sends a **new message** with Signal A or B.

| Intent | User must send | NOT valid |
|--------|----------------|-----------|
| Resume / crash recovery | `/od re` or `/od re [payload]` | bare `continue`, chat-context guessing |
| Next phase | `/od n` | bare `n`, `1`, plain prose |
| Revise output | `/od ad` | bare `ad`, `2` |
| Requirement change | `/od ch` | bare `ch` |
| Confirm / cancel | `/od y` / `/od x` | bare `y`, `n` |
| End and save session | `/od x` | closing chat without command |

**Checkpoint UX**: Present native interactive prompt (platform-specific). Labels show `/od` command. User picks in UI **or** types full `/od` command in **next message**. Agent MUST STOP and WAIT.

**Resume UX**: Always disk-based via `session-log.md` — never conversation-memory resume.

---

## 4. Bootstrap

| Signal | Action |
|--------|--------|
| A or B | Full [activation.md](activation.md) §1–§6 — tool calls first |
| None | Zero OmniDev loading |

---

## 5. Platform support (PAL)

OmniDev supports **Cursor**, **Claude Code**, and **Codex** via Platform Abstraction Layer (SKILL.md §F).

| Platform | Interactive prompt | Workers | Skill install path | Gate / rules |
|----------|-------------------|---------|-------------------|--------------|
| **Cursor** | `AskQuestion` | Built-in sub-agents | `.cursor/skills/od/` | `.cursor/rules/01-omnidev-workflow.mdc` + `AGENTS.md` |
| **Claude Code** | `AskUserQuestion` | `Task` tool | `.claude/skills/od/` or `~/.claude/skills/od/` | `CLAUDE.md` + `rules/02-omnidev-workflow.claude.md` |
| **Codex** | `request_user_input` | `create_thread` | `~/.codex/skills/od/` | `rules/03-omnidev-workflow.codex.md` + skill `description` |

**Codex recommendation**: enable `default_mode_request_user_input = true` in `~/.codex/config.toml`.

**Config override**: `docs/omnidev-state/config.json` → `"platform_override": "cursor" | "claude_code" | "codex" | "cli_other"`.

---

## 6. Troubleshooting

| Symptom | Fix |
|---------|-----|
| `/od` ignored (Cursor) | Rule `alwaysApply: true`; run `/od up` |
| Replied `1` / `n`, nothing happens | **Expected** — send `/od n` or `/od re` |
| New chat, want to continue | `/od re` (reads `session-log.md` from disk) |
| Stale `in_progress` | `/od re` to resume or `/od x` then `/od [new requirement]` |
| Codex no popup | Enable `default_mode_request_user_input`; fallback pseudo-popup still works |

---

## 7. Platform install pointers

| Platform | Gate file |
|----------|-----------|
| Cursor | `.cursor/rules/01-omnidev-workflow.mdc` + `AGENTS.md` |
| Claude Code | `CLAUDE.md` + `rules/02-omnidev-workflow.claude.md` |
| Codex | `rules/03-omnidev-workflow.codex.md` + skill `description` |

See [INSTALL.md](../../../INSTALL.md) for full install steps.
