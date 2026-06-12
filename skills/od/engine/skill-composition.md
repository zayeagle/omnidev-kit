# Dynamic Skill Composition (动态 Skill 组合)

When the user raises a **troubleshooting, debugging, error investigation, or problem diagnosis** request within an `/od` session, OmniDev acts as an **orchestrator** that dynamically discovers and loads specialized external skills rather than handling everything itself.

## 1. Trigger Detection

During Phase 0 (Complexity Assessment) or when processing any `/od` message, detect if the user's request matches a **troubleshooting/diagnosis intent** by checking for these signals:

| Signal Category | Keywords / Patterns |
|-----------------|---------------------|
| **Error investigation** | 报错, 500, 4xx, 5xx, 502, 503, 504, 异常, exception, error, failed, failure, crash, panic, 崩溃 |
| **Problem diagnosis** | 排查, 排障, troubleshoot, debug, diagnose, 定位问题, 查问题, 问题分析, root cause |
| **Log analysis** | 查日志, 看日志, 日志查询, log, logging, 错误日志, trace |
| **Behavior anomaly** | 不符预期, 不对, 应该是, 但实际, unexpected, 行为异常, 返回不正确 |
| **Ops / infra** | Pod, K8s, 容器, 实例, 部署失败, 服务挂了, 超时, timeout, OOM, 内存溢出 |
| **Fix request** | 修复, 修bug, fix, hotfix, patch, 漏洞, 修正, 纠错 |

**If none of these signals are detected**, proceed with the normal OmniDev workflow (Phase 0 → sizing → phases). **If signals are detected**, enter the Skill Discovery flow (§2).

## 2. Skill Discovery (本地 Skill 扫描)

Scan the following directories for `SKILL.md` files (using `Glob` tool with pattern `**/SKILL.md`):

| Scan Path | Priority | Description |
|-----------|----------|-------------|
| `.cursor/skills/` | 1 (highest) | Project-level skills |
| `~/.cursor/skills/` | 2 | User-level Cursor skills |
| `~/.claude/skills/` | 3 | User-level Claude skills |
| `~/.agents/skills/` | 4 | User-level agent skills |

**For each discovered `SKILL.md`**, read only the **YAML frontmatter** (`name` and `description` fields) — do NOT read the full file body. This keeps the scan lightweight.

## 3. Skill Matching & Ranking

Match the user's request against each discovered skill using a two-step process:

1. **Keyword Match**: Compare the user's request keywords against the skill's `description` field. Look for overlap in:
   - Domain terms (e.g. "troubleshoot", "排查", "日志", "log", "Pod", "K8s")
   - Service/product names mentioned by the user that appear in the skill description
   - Action verbs (e.g. "查", "分析", "排查", "fix")

2. **Category Classification**: Classify each matching skill into a relevance tier:

   | Tier | Condition | Example |
   |------|-----------|---------|
   | **Direct match** | Skill's `name` or `description` explicitly mentions troubleshooting/diagnosis AND matches the user's domain | `kdb-troubleshoot` for a KDB service error |
   | **Supporting** | Skill provides a capability needed during troubleshooting (e.g. log query, pod status) but is not a full troubleshooting workflow | `cloud-logging` for log queries, `sre-aiops-assistant` for pod/K8s checks |
   | **Irrelevant** | No meaningful overlap | `weekly-requirement-capture`, `sreweb-component-table` |

   Discard **Irrelevant** skills. Keep **Direct match** and **Supporting** skills.

## 4. User Confirmation (Mandatory)

**NEVER auto-load an external skill without explicit user confirmation.**

Present the discovered skills to the user using `AskQuestion` (if `interactive_mode` is `true`, `allow_multiple: true`) or numbered prompt (if `false`).

Prompt: zh → `"🔍 检测到问题排查/修复类需求，发现以下可用的专业 Skill："` / en → `"🔍 Troubleshooting/fix request detected. Found these specialized skills:"`

| id | zh label | en label |
|----|----------|----------|
| `skill_N` (per match) | 🎯 [name] — [desc] (直接匹配) | 🎯 [name] — [desc] (direct match) |
| `skill_N` (supporting) | 🔧 [name] — [desc] (辅助能力) | 🔧 [name] — [desc] (supporting) |
| `od_only` | 不加载外部 Skill，使用 OmniDev 内置流程处理 | Skip external skills, use OmniDev built-in flow |
| `cancel` | 取消，重新描述需求 | Cancel, let me rephrase my request |

**Rules**:
- **Direct match** skills are listed first with 🎯 prefix.
- **Supporting** skills are listed after with 🔧 prefix.
- Always include the `od_only` and `cancel` escape options.
- `allow_multiple: true` — the user may select a primary troubleshooting skill plus supporting skills (e.g. `kdb-troubleshoot` + `cloud-logging` + `sre-aiops-assistant`).
- **STOP — WAIT for user selection.** Do NOT proceed until the user confirms.

## 5. Skill Loading & Execution

After the user confirms which skills to load:

1. **Read the full `SKILL.md`** of each selected skill (now reading the body, not just frontmatter).
2. **Set execution context**: The loaded skill's rules and workflow take priority for the current troubleshooting task. OmniDev's core rules (B.0–B.2) remain active as baseline guardrails.
3. **Execute the loaded skill's workflow**: Follow its steps, checkpoints, and sub-document loading rules exactly as defined in that skill.
4. **Combine supporting skills on-demand**: If the user selected supporting skills (e.g. `cloud-logging`), invoke them as needed during the primary skill's execution — for example, when `kdb-troubleshoot` reaches its "查日志" step, use the `cloud-logging` skill's rules for the log query.

## 6. Return to OmniDev Workflow

When the external skill's workflow completes (user selects "end" or the skill reaches its final checkpoint):

1. **Summarize findings**: Output a brief summary of the troubleshooting results.
2. **Bridge back to OmniDev**: If the troubleshooting identified a code fix needed, present options via `AskQuestion`:

   Prompt: zh → `"🔧 排查完成。是否需要在 OmniDev 工作流中继续修复？"` / en → `"🔧 Troubleshooting complete. Continue with a fix in OmniDev?"`

   | id | zh label | en label |
   |----|----------|----------|
   | `fix_od` | 进入 OmniDev 开发流程修复问题 (`/od -f`) | Enter OmniDev dev flow to fix (`/od -f`) |
   | `fix_plan` | 先制定修复计划再动手 (`/od [修复需求]`) | Plan the fix first (`/od [fix requirement]`) |
   | `done` | 排查结束，无需修复 | Done, no fix needed |

3. If the user chooses to fix, seamlessly transition into the OmniDev development workflow with the troubleshooting findings as input context.

## 7. Skill Composition Constraints

- **Token budget**: Loading an external skill adds to context. If multiple skills are selected, load them lazily — only read a skill's full body when its workflow step is about to execute.
- **Conflict resolution**: If the external skill's rules conflict with OmniDev's core rules (B.0–B.2), OmniDev's core rules take precedence (they are safety guardrails).
- **No recursive composition**: An external skill loaded by OmniDev cannot itself trigger §1 to load another skill. Only OmniDev acts as the orchestrator.
- **Session isolation**: External skill execution does not produce OmniDev state files (`02-plan.md`, `03-progress.md`, etc.). It only produces its own artifacts (if any). OmniDev state files are only written when the user returns to the OmniDev workflow.
