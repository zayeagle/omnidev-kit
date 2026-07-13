# OmniDev Unified Trigger Gate

**Single source of truth for when to load OmniDev.** All platforms consult via [activation.md](activation.md) §0.

---

## 1. Activate — ONLY two entry signals

**No session-context inference. No bare-number checkpoint replies. No same-thread continuation.**

### Signal A — `/od` or `$od` prefix

```
/^\s*[\/$]od(\s|$|[\u4e00-\u9fff])/i
```

| Prefix | Platforms |
|--------|-----------|
| `/od` | Cursor · Claude Code · Codex (universal) |
| `$od` | **Codex compatible** (equivalent to `/od`) |

Matches: `/od`, `$od`, `/od h`, `$od n`, `/od re`, `/od implement login`  
Does NOT match: `please use /od to …` (not line-start), `code/od`, bare `1` / `n` / `continue`

Strip leading `/od` or `$od` the same way before command routing.

### Signal B — Explicit skill invocation (platform-specific)

Skill **listed** is **NOT** enough — must be **actively loaded this turn**:

| Platform | YES (observable) | NO |
|----------|------------------|-----|
| **Cursor** | User message / system shows `@od` attach, or SKILL **body** injected this turn | Only appears in `available_skills` |
| **Claude Code** | This turn context contains `od/SKILL.md` body | Skill on disk, not loaded |
| **Codex** | User explicitly invokes / @od, or system injects SKILL **body** | `<skills_instructions>` is manifest list only |

**Uncertainty rule**: Cannot confirm Signal B → **treat as not triggered** (prefer not activating). Listing alone **must not** activate.

When Signal B fires without prefix → treat as `/od [requirement]` → Phase 0.

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

### 2.1 Explicit non-activation feedback (prevent silent failure)

If **neither** A nor B fired, but the user message looks like advancing the workflow, reply **one line only** (then normal chat; do not load OmniDev):

Match (whole message trimmed, case-insensitive): `^(n|ad|re|ch|x|y|1|2|3|continue|\u7ee7\u7eed|\u4e0b\u4e00\u6b65)$`

```
⚠️ OmniDev not active. Send a full command such as /od n (Codex: $od n). Resume with /od re.
```

Other ordinary chat: **do not** insert this tip.

---

## 3. Interactive iteration

Workflow advances when:

1. **New user message** carries Signal A or B, **or**
2. **Same turn** native interactive tool returned a selection (UI pick) → route by option; no extra `/od` needed

| Intent | User must send | NOT valid |
|--------|----------------|-----------|
| Resume | `/od re` or `$od re` | bare `continue` |
| Next phase | `/od n` / `$od n` | bare `n`, `1` |
| Revise | `/od ad` / `$od ad` | bare `ad`, `2` |
| Change | `/od ch` | bare `ch` |
| Confirm / cancel | `/od y` / `/od x` | bare `y`, `n` |

**Checkpoint UX**: Native popup → STOP → UI pick **or** next full `/od`/`$od` command.  
**Resume UX**: Disk `session-log.md` only — forbid resume from chat memory.

---

## 4. Bootstrap

| Signal | Action |
|--------|--------|
| A or B | Full [activation.md](activation.md) §1–§6 — tool calls first |
| None | Zero OmniDev loading (except §2.1 tip) |

---

## 5. Platform support (PAL)

| Platform | Interactive prompt | Workers | Skill install path | Gate / rules |
|----------|-------------------|---------|-------------------|--------------|
| **Cursor** | `AskQuestion` | Built-in sub-agents | `.cursor/skills/od/` | `.cursor/rules/01-omnidev-workflow.mdc` + `AGENTS.md` |
| **Claude Code** | `AskUserQuestion` | `Task` tool | `.claude/skills/od/` or `~/.claude/skills/od/` | `CLAUDE.md` + `rules/02-omnidev-workflow.claude.md` |
| **Codex** | `request_user_input` | `create_thread` | `~/.codex/skills/od/` | `rules/03-omnidev-workflow.codex.md` + skill `description` |

**Codex**: enable `default_mode_request_user_input = true`; prefixes `/od` and `$od` are equivalent.

**Config**: `platform_override`: `"cursor" | "claude_code" | "codex" | "cli_other"`.

---

## 6. Troubleshooting

| Symptom | Fix |
|---------|-----|
| `/od` / `$od` ignored (Cursor) | Rule `alwaysApply: true`; `scripts/sync-skills`; `/od up` |
| User only sent `n`/`1` | **Expected** — send `/od n` or see §2.1 tip |
| Codex `$od` | Same trigger as `/od`; if still broken check skill install |
| Codex false trigger | manifest-only ≠ Signal B |
| Cursor no AskQuestion | §8 pseudo-popup + switch to Claude/GPT or Plan; tool exists but skipped = violation |
| Phase 0 output messy | ≤6 lines; details → session-log; forbid `od_interactive:` |
| skills vs .cursor drift | From repo root: `powershell -File scripts/sync-skills.ps1` |

---

## 7. Platform install pointers

| Platform | Gate file |
|----------|-----------|
| Cursor | `.cursor/rules/01-omnidev-workflow.mdc` + `AGENTS.md` |
| Claude Code | `CLAUDE.md` + `rules/02-omnidev-workflow.claude.md` |
| Codex | `rules/03-omnidev-workflow.codex.md` + skill `description` |

See [INSTALL.md](../../../INSTALL.md). Kit maintainers: keep `skills/od/` SSOT → sync to `.cursor/skills/od/` via `scripts/sync-skills.ps1`.
