# OmniDev Unified Trigger Gate

**Single source of truth for when to load OmniDev.** All platforms consult via [activation.md](activation.md) §0.

---

## 1. Activate — Signal A only (workflow)

**No session-context inference. No bare-number checkpoint replies. No same-thread continuation.**

### Signal A — `/od` or `$od` prefix (**only workflow activator**)

```
/^\s*[\/$]od(\s|$|[\u4e00-\u9fff])/i
```

| Prefix | Platforms |
|--------|-----------|
| `/od` | Cursor · Claude Code · Codex (universal) |
| `$od` | **Codex compatible** (equivalent to `/od`) |

Matches: `/od`, `$od`, `/od h`, `$od n`, `/od re`, `/od implement login`  
Does NOT match: `please use /od to …` (not line-start), mid-sentence `/od up`, `code/od`, bare `1` / `n` / `continue`

Strip leading `/od` or `$od` the same way before command routing.

### Skill attach / invoke — **NOT** a workflow trigger

Attaching `@od`, invoking the `od` skill, or having SKILL body injected **does not** start OmniDev bootstrap / Phase 0 / `docs/omnidev-state` workflow.

| Situation | Behavior |
|-----------|----------|
| `@od` attached, message has **no** `/od`/`$od` prefix | **Normal chat** — skill text may be used as reference; forbid activation.md Phase 0 |
| Message starts with `/od` / `$od` | **Activate** (Signal A) — full bootstrap |
| Skill only in `available_skills` / manifest list | Never activate |

**Rationale**: Discussing or implementing OmniDev itself (e.g. "add install scope to `/od up`") while `@od` is attached must not enter the guided workflow.

**Uncertainty**: If unsure whether Signal A matched → **do not activate**.

---

## 2. Do NOT activate (strict)

When **Signal A is absent**:

| Forbidden |
|-----------|
| Read `activation.md` / phase files for workflow bootstrap |
| Read/write `docs/omnidev-state/**` as OmniDev session |
| OmniDev checkpoints / interactive prompts |
| Infer OmniDev from prior chat turns, disk `in_progress`, skill attach, or checkpoint context |
| Treat bare `1`, `n`, `y`, `continue` as workflow input |

**Normal chat** — even if `@od` is attached, even if previous turn was OmniDev, even if `session-log` is `in_progress`.

### 2.1 Explicit non-activation feedback (prevent silent failure)

If Signal A did **not** fire, but the user message looks like advancing the workflow, reply **one line only** (then normal chat; do not load OmniDev):

Match (whole message trimmed, case-insensitive): `^(n|ad|re|ch|x|y|1|2|3|continue|\u7ee7\u7eed|\u4e0b\u4e00\u6b65)$`

```
⚠️ OmniDev not active. Send a full command such as /od n (Codex: $od n). Resume with /od re.
```

Other ordinary chat: **do not** insert this tip.

---

## 3. Interactive iteration

Workflow advances when:

1. **New user message** carries Signal A (`/od` / `$od`), **or**
2. **Same turn** native interactive tool returned a selection (UI pick) → route by option; no extra `/od` needed

| Intent | User must send | NOT valid |
|--------|----------------|-----------|
| Resume | `/od re` or `$od re` | bare `continue`, `@od` alone |
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
| **A** (`/od` / `$od` prefix) | Full [activation.md](activation.md) §1–§6 — tool calls first |
| Skill attach only / none | Zero OmniDev workflow loading (except §2.1 tip) |

---

## 5. Platform support (PAL)

| Platform | Interactive prompt | Workers | Skill install path | Gate / rules |
|----------|-------------------|---------|-------------------|--------------|
| **Cursor** | `AskQuestion` | Built-in sub-agents | `.cursor/skills/od/` (project) / `~/.cursor/skills/od/` (user) | `.cursor/rules/01-omnidev-workflow.mdc` + `AGENTS.md` |
| **Claude Code** | `AskUserQuestion` | `Task` tool | `.claude/skills/od/` or `~/.claude/skills/od/` | `CLAUDE.md` + `rules/02-omnidev-workflow.claude.md` |
| **Codex** | `request_user_input` | `create_thread` | `~/.codex/skills/od/` | `rules/03-omnidev-workflow.codex.md` + skill `description` |

**Codex**: enable `default_mode_request_user_input = true`; prefixes `/od` and `$od` are equivalent.

**Config**: `platform_override`: `"cursor" | "claude_code" | "codex" | "cli_other"`.

---

## 6. Troubleshooting

| Symptom | Fix |
|---------|-----|
| `/od` / `$od` ignored (Cursor) | Rule `alwaysApply: true`; `scripts/sync-skills`; `/od up` |
| `@od` attached but no Phase 0 | **Expected** — attach ≠ activate; send `/od …` to start workflow |
| Mid-sentence `/od up` talk | **Expected** — only line-start `/od`/`$od` activates |
| User only sent `n`/`1` | **Expected** — send `/od n` or see §2.1 tip |
| Codex `$od` | Same trigger as `/od`; if still broken check skill install |
| Cursor no AskQuestion | §8 pseudo-popup + switch to Claude/GPT or Plan; tool exists but skipped = violation |
| Phase 0 output messy | ≤6 lines; details → session-log; forbid `od_interactive:` |
| skills vs .cursor drift | From repo root: `bash scripts/sync-skills.sh` |

---

## 7. Platform install pointers

| Platform | Gate file |
|----------|-----------|
| Cursor | `.cursor/rules/01-omnidev-workflow.mdc` + `AGENTS.md` |
| Claude Code | `CLAUDE.md` + `rules/02-omnidev-workflow.claude.md` |
| Codex | `rules/03-omnidev-workflow.codex.md` + skill `description` |

See [INSTALL.md](../../../INSTALL.md). Kit maintainers: keep `skills/od/` SSOT → sync to `.cursor/skills/od/` via `scripts/sync-skills.sh`.
