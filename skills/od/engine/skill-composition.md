# Dynamic Skill Composition

→ Platform mapping: SKILL.md §F.2 (Interactive Prompt), §F.5 (Skill Discovery Paths)

When the user raises a **troubleshooting, debugging, error investigation, or problem diagnosis** request within an `/od` session, OmniDev acts as an **orchestrator** that dynamically discovers and loads specialized external skills rather than handling everything itself (flow: §1-§7).

The same discovery idea applies to **code review**: on `/od rv` / `/od review`, scan local review skills first and let the user choose between a specialized review skill and the built-in review flow (flow: §8). **Never self-review silently while a matching local review skill exists.**

## 1. Trigger Detection

During Phase 0 (Complexity Assessment) or when processing any `/od` message, detect if the user's request matches a **troubleshooting/diagnosis intent** by checking for these signals:

| Signal Category | Keywords / Patterns |
|-----------------|---------------------|
| **Error investigation** | error, 500, 4xx, 5xx, 502, 503, 504, exception, failed, failure, crash, panic |
| **Problem diagnosis** | troubleshoot, debug, diagnose, root cause, investigate, locate issue, problem analysis |
| **Log analysis** | log, logging, error log, trace, check logs, view logs, log query |
| **Behavior anomaly** | unexpected, incorrect, should be, but actually, wrong behavior, incorrect return |
| **Ops / infra** | Pod, K8s, container, instance, deploy failed, service down, timeout, OOM, out of memory |
| **Fix request** | fix, hotfix, patch, vulnerability, correct, repair, bugfix |

**If none of these signals are detected**, proceed with the normal OmniDev workflow (Phase 0 → sizing → phases). **If signals are detected**, enter the Skill Discovery flow (§2).

## 2. Skill Discovery (Local Skill Scan)

Scan the following directories for `SKILL.md` files (using `Glob` tool with pattern `**/SKILL.md`):

| Scan Path | Priority | Description |
|-----------|----------|-------------|
| `.cursor/skills/` | 1 (highest) | Project-level skills |
| `<repo>/.dsh/skills/` | 2 | Project-level DSH skills |
| `.claude/skills/` | 3 | Project-level Claude skills |
| `~/.cursor/skills/` | 4 | User-level Cursor skills |
| `~/.claude/skills/` | 5 | User-level Claude skills |
| `~/.codex/skills/` | 6 | User-level Codex skills |
| `~/.dsh/skills/` | 7 | User-level DSH skills (source of the DSH session catalog) |
| `~/.agents/skills/` | 8 | User-level agent skills |

**DSH shortcut (preferred)**: when the harness already injects an `available_skills` catalog (DSH does), treat that list as the scan result - it is the harness's own view of the DSH skill directory. Do not walk the filesystem again in that case.

**For each discovered `SKILL.md`**, read only the **YAML frontmatter** (`name` and `description` fields) — do NOT read the full file body. This keeps the scan lightweight.

## 3. Skill Matching & Ranking

Match the user's request against each discovered skill using a two-step process:

1. **Keyword Match**: Compare the user's request keywords against the skill's `description` field. Look for overlap in:
   - Domain terms (e.g. "troubleshoot", "log", "Pod", "K8s")
   - Service/product names mentioned by the user that appear in the skill description
   - Action verbs (e.g. "check", "analyze", "investigate", "fix")

2. **Category Classification**: Classify each matching skill into a relevance tier:

   | Tier | Condition | Example |
   |------|-----------|---------|
   | **Direct match** | Skill's `name` or `description` explicitly mentions troubleshooting/diagnosis AND matches the user's domain | `kdb-troubleshoot` for a KDB service error |
   | **Supporting** | Skill provides a capability needed during troubleshooting (e.g. log query, pod status) but is not a full troubleshooting workflow | `cloud-logging` for log queries, `sre-aiops-assistant` for pod/K8s checks |
   | **Irrelevant** | No meaningful overlap | `weekly-requirement-capture`, `sreweb-component-table` |

   Discard **Irrelevant** skills. Keep **Direct match** and **Supporting** skills.

## 4. User Confirmation (Mandatory)

**NEVER auto-load an external skill without interactive confirmation.**

**MUST** invoke [interactive-prompt.md](interactive-prompt.md) §3.5 `skill_select` via §4/§5/§6/§7 (`allow_multiple: true`) → **STOP — WAIT**.

Prompt: `"🔍 Troubleshooting/fix request detected. Found these specialized skills:"`

| id | label |
|----|-------|
| `skill_N` (per match) | 🎯 [name] — [desc] (direct match) |
| `skill_N` (supporting) | 🔧 [name] — [desc] (supporting) |
| `od_only` | Skip external skills, use OmniDev built-in flow |
| `cancel` | Cancel, let me rephrase my request |

**Rules**:
- **Direct match** skills are listed first with 🎯 prefix.
- **Supporting** skills are listed after with 🔧 prefix.
- Always include the `od_only` and `cancel` escape options.
- `allow_multiple: true` — the user may select a primary troubleshooting skill plus supporting skills.

| Platform | Invoke |
|----------|--------|
| **Cursor** | §4 `AskQuestion` + `allow_multiple: true` |
| **Claude Code** | §5 `AskUserQuestion` + `allow_multiple: true` |
| **Codex** | §6 sequential single-select or §8 multi-select instructions (no native multi; no autoResolutionMs) |
| **DeepSeek Harness (DSH)** | §7 `ask_user_question` + `multi_select: true` |
| **CLI / Other** | §8 / §9 |

Workers must not show prompts; when confirmation is needed, return to the Orchestrator.

## 5. Skill Loading & Execution

After the user confirms which skills to load:

1. **Read the full `SKILL.md`** of each selected skill (now reading the body, not just frontmatter).
2. **Set execution context**: The loaded skill's rules and workflow take priority for the current troubleshooting task. OmniDev's core rules (B.0–B.2) remain active as baseline guardrails.
3. **Execute the loaded skill's workflow**: Follow its steps, checkpoints, and sub-document loading rules exactly as defined in that skill.
4. **Combine supporting skills on-demand**: If the user selected supporting skills (e.g. `cloud-logging`), invoke them as needed during the primary skill's execution — for example, when `kdb-troubleshoot` reaches its "check logs" step, use the `cloud-logging` skill's rules for the log query.

## 6. Return to OmniDev Workflow

When the external skill's workflow completes (user selects "end" or the skill reaches its final checkpoint):

1. **Summarize findings**: Output a brief summary of the troubleshooting results.
2. **Bridge back to OmniDev**: **MUST** `present_options` via §4/§5/§6/§7 → **STOP — WAIT**:

   Prompt: `"🔧 Troubleshooting complete. Continue with a fix in OmniDev?"`

   | id | label |
   |----|-------|
   | `fix_od` | Enter OmniDev dev flow to fix (`/od -f`) |
   | `fix_plan` | Plan the fix first (`/od [fix requirement]`) |
   | `done` | Done, no fix needed |

3. If the user chooses to fix, seamlessly transition into the OmniDev development workflow with the troubleshooting findings as input context.

## 7. Skill Composition Constraints

- **Token budget**: Loading an external skill adds to context. If multiple skills are selected, load them lazily — only read a skill's full body when its workflow step is about to execute.
- **Conflict resolution**: If the external skill's rules conflict with OmniDev's core rules (B.0–B.2), OmniDev's core rules take precedence (they are safety guardrails).
- **No recursive composition**: An external skill loaded by OmniDev cannot itself trigger §1 to load another skill. Only OmniDev acts as the orchestrator.
- **Session isolation**: External skill execution does not produce OmniDev state files (`02-plan.md`, `03-progress.md`, etc.). It only produces its own artifacts (if any). OmniDev state files are only written when the user returns to the OmniDev workflow.

---

## 8. Review Skill Discovery (`/od rv` / `/od review`)

Review is the one place where the kit must **not** default to self-review. If a local skill already encodes review rules (scoring baseline, security checklist, layer conventions), the user picks it explicitly.

### 8.1 Trigger

Runs **only** on an explicit Signal A command: `/od rv` or `/od review`.

- Bare natural language ("review this code", "check this MR") does **not** enter this flow. It stays normal chat; the model may add at most one line: `Tip: /od rv runs the review-skill discovery flow.` - no workflow loading, per [trigger-gate.md](trigger-gate.md) §2.1.
- Review is **read-only**. No edits, commits, or phase artifacts. Fixes start only after §8.6.

### 8.2 Discovery

1. **Prefer the harness catalog** if the platform injects one (DSH `available_skills`): use it as the scan result, skip the filesystem.
2. **Otherwise scan** the paths in §2 and read **YAML frontmatter only** (`name`, `description`). Never read full bodies during discovery.

### 8.3 Matching and applicability (two gates)

**Gate 1 - capability match.** Keep skills whose `name` / `description` covers review work: `review`, `code review`, `CR`, `audit`, `checklist`, `lint rules`, `code quality`.

**Gate 2 - applicability.** Read the description's scope clauses ("Use when" / "Not for", applicable / not-applicable sections) and compare against the target repo: language, layer or path, frontend-only, docs-only.

| Verdict | Handling |
|---------|----------|
| **Exact** - description names the repo, layer, or stack under review | List first, prefix `[exact]` |
| **Generic** - language- or framework-level review rules | List after, prefix `[generic]` |
| **Not applicable** - description excludes this code (e.g. V2 `internal/`, frontend-only repos) | **Exclude from options**; state the reason in one line |

A skill is a *procedure*, not evidence: its checklist still requires `file:line` proof before any finding is graded.

### 8.4 Mandatory confirmation (STOP - WAIT)

**NEVER auto-load a review skill.** List matches, then invoke [interactive-prompt.md](interactive-prompt.md) §3.5 `review_skill_select` and **STOP - WAIT**.

Prompt: `Review request. Local review skills found for this code:`

| id | label |
|----|-------|
| `skill_N` | `[exact]` or `[generic]` - skill name plus a one-line scope |
| `builtin` | Built-in review flow (no scoring baseline) |
| `cancel` | Cancel, let me rephrase |

Rules:
- **Single-select** (`allow_multiple: false`): two scoring baselines in one report are not comparable.
- **No match found**: do not pop up. Say one line `No local review skill matched; using the built-in review flow.` and continue with §8.5 `builtin`.
- **Autopilot** (`/od auto`): soft gate - auto-pick the top-ranked skill, print the one-line choice, record it in Key Decisions.
- Platform invoke: §4 / §5 / §6 / §7 mapping (DSH: `ask_user_question`).

### 8.5 Execution

| Choice | Behavior |
|--------|----------|
| **Skill** | Read the full `SKILL.md` body, then follow that skill's steps, scoring, and report path. OmniDev core rules (B.0-B.2) stay active as guardrails; the skill's own write-scope rules win over any od default. |
| **`builtin`** | Built-in checklist: correctness, security (injection, authz, secrets), error handling (swallowed errors, wrong codes), concurrency and state, testability. Every finding carries `file:line` evidence. Chat summary <=20 lines; full report to a file only when asked. |

### 8.6 Record and hand-off

Record two lines in `session-log.md` `## Key Decisions`:

```
review_skill: <skill-name> | builtin
review_scope: baseline | diff <base>..<head>
```

No phase files are created. Then offer the hand-off (`present_options`, **STOP - WAIT**):

| id | label |
|----|-------|
| `fix_fast` | Fix findings now (`/od -f`) |
| `fix_plan` | Plan the fixes first (`/od [fix requirement]`) |
| `done` | Done, no fixes |

### 8.7 Constraints

- **Read-only**: no edits, no commits, no state writes beyond the §8.6 lines.
- **One skill only**; no recursive composition (a loaded skill cannot re-enter §8.2 or §1).
- **Token budget**: frontmatter scan first, then read exactly one skill body.
