# Phase 3 Instructions (Development & DevSecOps)

```yaml
context_requires:
  read:
    - 00-project-context.md          # conventions, pitfall guide, stability_level
    - 02-plan.md                     # task groups, dependencies
    - 03-progress.md                 # resume point
    - 04-design.md                   # architectural constraints
  scan:
    - files listed in current group's task `outputs` and `depends`
  reload: 02-plan.md                 # re-read after each group
  skip:
    - 01-blueprint.md, 05-test-report.md, 06-release-notes.md
```

## 1. Execution Protocol

1. Auto-checkpoint: `git commit -m "chore: auto-checkpoint before omnidev task"`.
2. **Execute by group order** from `02-plan.md`. Dispatch independent tasks in parallel via `Task` tool if possible.
3. **Frontend sync**: Follow existing conventions (API client wrapper, state management, naming style).
4. **Aggressive Pruning**: Keep ONLY the last 3 active tasks in `03-progress.md` `## State Snapshot`. When a task completes, mark `[x]` in `02-plan.md` and immediately remove its details from `03-progress.md` to save tokens.
5. **Change Impact Summary**: After completing each task group, output a structured impact summary (see §2 below).
6. Checkpoint → WAIT.

## 2. Change Impact Summary

**Trigger**: Automatically after each task group completes AND before the Phase 3 checkpoint.

**Steps**:
1. Run `git diff --stat HEAD` to collect all changed files since the last checkpoint.
2. Categorize each file by operation type and functional module.
3. Analyze which features, APIs, pages, or services are affected by the changes.
4. Check for dependency changes (`package.json`, `requirements.txt`, `go.mod`, etc.).
5. Check for configuration or environment changes (`.env`, config files, migration scripts).

**Output format** (display to user):

```
📋 **Change Impact Summary**

### File Changes
| Operation | File Path | Description |
|-----------|----------|-------------|
| 🆕 Added | src/services/auth.ts | Authentication service module |
| 📝 Modified | src/routes/user.ts | Added login endpoint |
| 📝 Modified | src/models/user.ts | Added token field |
| 🗑️ Deleted | src/utils/old-auth.ts | Removed legacy auth logic |

### Feature Impact
- **[Module]**: [specific impact description]
- **[Module]**: [specific impact description]
- **Frontend Impact**: [needs sync update / no impact]

### Dependency & Config Changes
- **New Dependencies**: [list added packages and versions, or "None"]
- **Environment Variables**: [list new/modified .env variables, or "None"]
- **Database Migrations**: [list migration scripts, or "None"]
```

**Rules**:
- Keep the summary concise — no more than 20 file entries. If more, group by directory with counts.
- Functional impact analysis must map files to business features, not just list paths.
- If no dependency/config changes exist, still show the section with "None" to confirm nothing was missed.
- This summary is for **user awareness only** — it does not block the workflow and requires no confirmation.

## 3. DevSecOps & Resilience Requirements

Every interface must handle system-level failures and prevent vulnerabilities. Depth depends on `Stability Level` (`standard` or `high`).

**Security by Design (Mandatory for ALL levels):**
- Prevent IDOR/BOLA: `resource.owner_id == current_user.id`.
- Prevent Injection: Parameterized queries/ORM.
- Prevent SSRF/CSRF: Whitelist URLs, anti-CSRF tokens.
- Protect Sensitive Data: Hash passwords, mask PII in logs.

**Standard Level (Default):**
1. **Structured Errors**: Consistent JSON `{code, message, details}`. No raw stack traces.
2. **Timeout Control**: Explicit timeouts on ALL outbound calls (DB 5s, HTTP 10s).
3. **Graceful Failure**: Return 502/503/504 on dependency failure. Do not crash.
4. **Input Validation**: Validate/sanitize at the API boundary.

**High Level (User-requested additions):**
5. **Circuit Breaker**: Trip on high failure rate (e.g., `gobreaker`, `opossum`).
6. **Retry with Backoff**: Max 3 retries with exponential backoff + jitter for idempotent ops.
7. **Bulkhead Isolation**: Isolate connection/thread pools.
8. **Graceful Degradation**: Return degraded response for non-critical dependency failures.
9. **Rate Limiting**: Prevent resource exhaustion.

**Implementation Checklist (Verify before task completion):**
- [ ] Resource ownership verified (IDOR)
- [ ] SQL/NoSQL injection prevented
- [ ] Sensitive data masked
- [ ] Explicit timeouts on outbound calls
- [ ] Structured JSON errors
- [ ] (High only) Circuit breaker & Retry implemented
