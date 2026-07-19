# Security Audit of AI Output (B.22)

**Load when**: Phase 3 exit (mandatory when `security_audit: true`) · `/od sec` · Phase 4 entry if last audit missing/stale · after each security fix iteration.

**Principle**: Audit **AI-produced / AI-modified** code and config before leaving Development. On **FAIL**, open a fix loop. **Manual / non-autopilot**: user must confirm before the next iteration. **Autopilot (`autopilot=true` / `mode=auto`)**: auto-confirm iterate (no STOP) until PASS, max iterations, or escalate.

→ Interactive: [interactive-prompt.md](interactive-prompt.md) §3.15 · Board: [board.md](board.md) §2.5 · Phase 3: [../phases/03-development.md](../phases/03-development.md)

---

## 0. Config

| Key | Default | Meaning |
|-----|---------|---------|
| `security_audit` | `true` | Master switch; if `false`, skip gate (log skip) |
| `security_audit_blocking` | `true` | FAIL blocks Phase 4 / phase-end `checkpoint` advance |
| `security_audit_max_iterations` | `3` | Max fix loops per Phase 3 exit; then escalate |
| `security_audit_tools` | `auto` | `auto` = run repo SAST/secret scanners if present; else checklist-only |

Read from `docs/omnidev-state/config.json`. Missing keys → defaults above.

---

## 1. When to Run

| Trigger | Required |
|---------|----------|
| End of Phase 3 (before Handoff / B.8 / board next to Phase 4) | **Yes** if `security_audit` |
| `/od sec` / `/od security` | Manual full audit |
| Start of Phase 4 | Re-check: last report `status=PASS` or `WAIVED` for current branch tip; else run audit |
| After a confirmed security iteration (fixes applied) | Re-audit immediately |

**Scope**: `git diff` / files touched in this requirement (from `03-progress.md` + plan outputs). Prefer `--stat` then targeted reads (B.17). Do not dump whole repo.

---

## 2. Audit Checklist (minimum)

Score each finding: **CRITICAL** / **HIGH** / **MEDIUM** / **LOW** / **INFO**.

| ID | Category | Fail if |
|----|----------|---------|
| S1 | Secrets | Hardcoded API keys, tokens, passwords, private keys, connection strings with credentials |
| S2 | Injection | Unsanitized SQL / shell / HTML / template injection in new/changed code |
| S3 | AuthN/AuthZ | New endpoints or privileged actions without authz checks matching project norms |
| S4 | Dangerous APIs | `eval`, unsafe deserialization, `shell=True`, unchecked `exec`, path traversal |
| S5 | Crypto / transport | Cleartext secrets in transit config, weak crypto, TLS verify disabled without documented reason |
| S6 | Data exposure | PII/secrets in logs, overly broad CORS, public debug endpoints left on |
| S7 | Dependencies | If tools available: critical/high CVEs in newly added deps (npm/go/pip audit) |
| S8 | SAST | If repo has SAST (semgrep, gosec, eslint-security, etc.): new blocking findings on touched paths |

**Gate result**:

| Result | Condition |
|--------|-----------|
| **PASS** | No CRITICAL/HIGH open; MEDIUM documented as accepted or fixed |
| **FAIL** | Any open CRITICAL or HIGH |
| **WAIVED** | User B.0 waived specific IDs (logged with reason) |

MEDIUM-only: treat as **PASS with warnings** unless `security_audit_blocking` and policy says otherwise (default: warn, do not FAIL).

---

## 3. Output Artifact

Write / overwrite active report:

`docs/omnidev-state/[branch]/07-security-audit.md`

Before overwrite of substantive prior FAIL/PASS, archive to `07-security-audit-history.md` (append-only) per [document-history.md](document-history.md).

```markdown
---
requirement_id: [id]
iteration: [N]
status: PASS|FAIL|WAIVED
blocking_open: [count]
git_tip: [short sha]
audited_at: [ISO8601]
---

# Security Audit

## Summary
- Scope: [files / task groups]
- Tools: [checklist | + semgrep | …]
- Result: **FAIL|PASS|WAIVED**
- Iteration: N / max

## Findings
| ID | Sev | File | Issue | Remediation |
|----|-----|------|-------|-------------|
| S1-01 | CRITICAL | path | … | … |

## Tools
- [commands run + exit codes, or "checklist-only"]

## Decision
- [pending iterate | iterating | passed | waived]
```

Also append one line to `03-progress.md`:
`🔒 Security audit · iter N · FAIL|PASS · blocking=K`

Log metrics event: `security_audit` with `status`, `iteration`, `blocking_open`.

---

## 4. FAIL → Iterate Loop

```
Audit → FAIL
  → print ≤12-line findings summary (no full file dump)
  → if autopilot: auto-pick iterate (soft) → fix → re-audit
  → else: present_options security_iterate_confirm → STOP — WAIT
       → iterate: fix in Phase 3 scope → re-audit
       → waive: b0_confirm per finding / batch → WAIVED → may advance
       → revise_scope / cancel: stop loop, stay in Phase 3
```

### 4.1 Manual / non-autopilot (MUST confirm)

1. Invoke §3.15 `security_iterate_confirm` (hard gate) → **STOP — WAIT**.
2. **Only after** user picks `iterate` (or `/od sec -i` / equivalent) start the next fix iteration.
3. Do **not** silently start coding fixes before confirm.
4. After fixes: re-run §2–§3 (iteration++). Repeat until PASS, WAIVE, cancel, or max iterations.

### 4.2 Autopilot (`autopilot=true` / `mode=auto`) — exception

1. **Do not STOP** on `security_iterate_confirm` — soft-pick `iterate`.
2. Apply remediations for CRITICAL/HIGH in scope; re-audit.
3. If still FAIL after `security_audit_max_iterations` → escalate to hard `b0_confirm` (waive vs stop vs continue manual). Autopilot resumes only on waive/pass per board §2.5.

### 4.3 Max iterations

When `iteration >= security_audit_max_iterations` and still FAIL:

- Present `b0_confirm`: waive remaining / stay in Phase 3 / cancel.
- Never infinite loop.

---

## 5. PASS / WAIVED → Continue

1. Ensure report `status` is PASS or WAIVED on disk.
2. Proceed to Phase 3 Handoff Block → B.8 `checkpoint` / board next → Phase 4.
3. Phase 4 must not start if `security_audit_blocking` and no PASS/WAIVED for this tip.

---

## 6. Command `/od sec`

| Form | Behavior |
|------|----------|
| `/od sec` | Run full audit now; then PASS→summary or FAIL→§4 loop |
| `/od sec -i` | User confirms iterate (same as picking `iterate`) when a FAIL is pending |
| `/od sec --waive` | Start waive flow (`b0_confirm`) for open CRITICAL/HIGH |

Router: [activation.md](activation.md) · commands: [commands.md](commands.md).

---

## 7. Anti-Patterns

| Forbidden | Required |
|-----------|----------|
| Skip audit when `security_audit: true` | Run §2–§3 at Phase 3 exit |
| Auto-fix without confirm (manual) | `security_iterate_confirm` first |
| STOP on iterate confirm under autopilot | Soft-pick `iterate` |
| Advance to Phase 4 on FAIL while blocking | PASS or WAIVED only |
| Infinite iterate | Cap + escalate |
| Paste entire SAST logs into chat | Summary table + path pointers |
