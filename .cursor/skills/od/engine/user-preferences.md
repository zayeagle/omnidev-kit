# User Preferences Memory

→ Platform mapping: SKILL.md §F (Platform Abstraction Layer)

## Overview

Automatically and passively capture behavioral patterns and preferences the user shows during `/od` sessions, and persist them as a structured profile. Load lightly on every `/od` activation so the AI "remembers" user habits.

## 1. Preferences Profile File

**Path**: `docs/omnidev-state/user-preferences.md` (global; not per-branch)

**Size limit**: Keep within **30 lines**. This is a high-frequency load file and must stay extremely lean.

## 2. Profile Format

```markdown
---
last_updated: 2026-06-03T08:30:00+08:00
---

## Workflow Preferences
- complexity_skip: [Never generate state files for S tasks]
- phase_skip_pattern: [Usually skip Blueprint; only Plan → Dev → Test]
- checkpoint_style: [Prefer concise; no detailed checkpoint output]

## Code Style
- naming: [Variables camelCase; files kebab-case]
- comments_language: [Code comments in English]
- error_format: [{code, data, message} unified format]
- quotes: [Single quotes]

## Interaction Preferences
- output_verbosity: [concise | detailed]  # default concise
- language: [Reply in Chinese; code comments in English]
- confirm_style: [Fast confirm; do not re-show known info]

## Tech Preferences
- test_framework: [jest + react-testing-library]
- api_style: [RESTful, no GraphQL]
- state_management: [zustand]
- orm: [prisma]
```

## 3. Capture Rules (Passive Learning)

Capture automatically in these scenarios — **no explicit user trigger required**:

| Signal type | Capture condition | Write field |
|-------------|-------------------|-------------|
| **Phase skip pattern** | User skips the same phase twice in a row on similar tasks | `phase_skip_pattern` |
| **Checkpoint preference** | User immediately sends `/od n` after checkpoint without reading | `checkpoint_style: concise` |
| **Code style correction** | User edits AI-generated style (naming, quotes, indent, etc.) | `naming` / `quotes` etc. |
| **Output language preference** | User asks for "reply in Chinese" or "comments in English" | `language` / `comments_language` |
| **Stack preference** | User specifies or corrects framework/library choice | `test_framework` / `orm` etc. |
| **API format preference** | User corrects response format | `error_format` / `api_style` |
| **Output verbosity** | User says "be concise" / "more detail" / "no explanation" | `output_verbosity` |

### Capture Constraints

1. **Confidence threshold**: Write to profile only after the same preference signal appears **2+ times**. A single event may be an outlier.
2. **No duplicates**: Do not re-write existing preferences; update only when the value changes.
3. **Non-blocking**: Capture runs silently in the background; do not show tips like "your preference was recorded".
4. **Overwritable**: New preferences overwrite old ones (habits can change).
5. **Complementary to evolution-log**: evolution-log records error fixes and rule evolution (heavy); user-preferences records daily habits (light). Do not duplicate.

## 4. Load Rules

| Scenario | Behavior |
|----------|----------|
| **Every `/od` activation** | Read `user-preferences.md` alongside `config.json` (if present). File is small (< 30 lines); context cost is negligible. |
| **Phase 3 development** | Use `## Code Style` and `## Tech Preferences` to guide codegen. |
| **Phase Checkpoint** | Use `checkpoint_style` and `output_verbosity` to adjust output detail. |

## 5. User Control

- **View**: `/od cfg` shows both config.json and user-preferences.md.
- **Clear**: User may manually delete `user-preferences.md` to reset all preferences.
- **Edit**: User may edit the file directly; AI reads the latest version on next activation.
