# Personal Claude Code Customization — v1 Design

**Date:** 2026-05-14
**Status:** Draft (awaiting user review)
**Scope:** v1 of a personal layer on top of the `superpowers` plugin

## 1. Motivation

Three classes of friction with the current Claude Code + `superpowers` setup:

- **A. Invocation reliability.** Skills that should fire (brainstorming before design, debugging before fixes, verification before claiming done) sometimes don't.
- **B. Behavior mismatch.** The `superpowers:requesting-code-review` skill escalates minor findings into merge blockers.
- **C. Missing workflow.** No reliable way to capture deferrable items ("TODO later", "this also needs X") during work, surface them for triage at the end, and persist the kept ones to a tracker.

v1 addresses **A** (minimum surface) and **C** (full feature). **B is deferred** by user choice — revisited in a later iteration if it remains painful.

## 2. Non-goals (v1)

- No severity rubric in CLAUDE.md.
- No merge-recommendation rule.
- No `merge-review` wrapper skill.
- No hooks (SessionStart, UserPromptSubmit, etc.).
- No `settings.json` fragments.
- No per-skill baseline tests (writing-skills TDD discipline).
- No project-specific followup file locations.
- No home-manager / nix integration.

These are listed in the iteration roadmap (§7), not forgotten.

## 3. Repo and filesystem layout

**Repo location:** `/home/nox/Documents/Projects/Nox/claude-config/` (initialized as a git repo).

**Layout:**

```
claude-config/
  CLAUDE.md
  skills/
    followup-tracking/
      SKILL.md
  docs/
    specs/
      2026-05-14-personal-claude-customization-design.md
  README.md
  .gitignore
```

**Symlinks into `~/.claude/`:**

- `~/.claude/CLAUDE.md` → `/home/nox/Documents/Projects/Nox/claude-config/CLAUDE.md`
- `~/.claude/skills/followup-tracking` → `/home/nox/Documents/Projects/Nox/claude-config/skills/followup-tracking`

The harness reads from `~/.claude/`; the git repo is authoritative; symlinks bridge them. Edits to the repo take effect immediately.

`.gitignore`: at minimum, OS junk and editor swap files. No secrets are expected in the repo.

## 4. `CLAUDE.md` (v1 contents)

Target length: ~20 lines. Two functional pieces plus a placeholder section for future preferences.

**A. Invocation nudge (single line, directive form):**

> ALWAYS invoke `superpowers:using-superpowers` when starting any non-trivial task — including before asking clarifying questions. Let it decide which downstream skills apply.

Rationale: rather than nudge each high-leverage superpowers skill individually, route all decisions through `using-superpowers`, which is the meta-skill designed to dispatch the rest. One nudge, broad coverage.

**B. Followup-tracking pointer:**

> Capture deferrable items via the `followup-tracking` skill. The active list lives in TaskList (filter by `metadata.kind = "followup"`). On task completion, run the triage flow. Persisted items go to Linear (destination prompted unless specified in chat or in the active project's CLAUDE.md) and are mirrored to `~/claude-followups/YYYY-MM-DD.md`.

**C. Reserved section** for future small preferences (commit style, stack defaults, etc.) added incrementally as friction arises.

## 5. Skill: `followup-tracking`

**Core principle (load-bearing):**

> Capture is automatic. **Persistence is explicit.** No followup is written to Linear or any external tracker without per-item user confirmation during triage. The local mirror file is also gated on the same user confirmation — nothing is persisted anywhere until the user has reviewed it.

**Description (directive form, written for invocation reliability):**

> ALWAYS invoke when a deferrable issue, follow-up task, or "TODO later" item surfaces during work. Use to capture, triage, and persist these items so they are not lost between sessions.

### 5.1 Phases

**Capture (automatic, during work):**

When the model identifies a deferrable item — a non-blocking issue noticed while solving the active task, a related improvement, a `TODO`-style observation — it calls `TaskCreate` with:

- `subject`: concise statement of the item
- `description`: origin (what task surfaced it; file/line if relevant; why it was deferred)
- `metadata.kind`: `"followup"`
- `metadata.severity` (optional): `"low" | "medium" | "high"` — organizational only, not a merge gate

Active followups live in TaskList alongside in-progress work and are filterable by metadata.

**Triage (automatic at end of task, or on explicit user request):**

The skill iterates captured followups and presents each as:

```
[high] Auth middleware doesn't validate token expiry
  origin: src/auth/middleware.ts:42, surfaced during login-flow fix
  action: Keep / Drop / Edit?
```

- **Keep:** proceed to persist phase
- **Drop:** delete from TaskList; not persisted anywhere
- **Edit:** prompt for revised subject/description, re-present

**Persist (on Keep only):**

Two destinations; order matters because Linear can fail.

1. **Linear.** Destination resolution:
   - If a Linear team+project was stated in the active chat, reuse it
   - Else if active project's `CLAUDE.md` declares one (format: `Linear: team=X project=Y`), reuse it
   - Else prompt the user for team + project (offer "save for this session?")
   - Create the issue via the Linear MCP (`mcp__linear-server__save_issue`)
   - Capture the returned Linear issue ID

2. **Local mirror.** Append to `~/claude-followups/YYYY-MM-DD.md` (per-day, global, easy to grep). One record per item:
   ```
   - [HH:MM][severity] Subject
     origin: <description>
     linear: <issue id or "FAILED">
   ```

The local mirror is appended **regardless of Linear success** — it is the durable backup.

### 5.2 Failure handling

- **Linear MCP unavailable / errors:** surface the failure to the user with the error, write to local mirror with `linear: FAILED`, do not silently swallow.
- **Local file write fails:** surface to the user, do not silently swallow. Linear write should not be rolled back; user decides whether to retry the local write.
- **No followups captured during a task:** triage phase is skipped silently.

### 5.3 Skill file layout

```
skills/followup-tracking/
  SKILL.md
```

No supporting files in v1. If the skill grows reference material (e.g., Linear payload templates), split into separate files per writing-skills guidance.

## 6. Setup steps (high level — full plan comes from writing-plans skill)

1. Create `~/claude-followups/` directory.
2. Move (or create) `~/.claude/CLAUDE.md` content into the repo's `CLAUDE.md`. If a file already exists at `~/.claude/CLAUDE.md`, back it up before replacing with a symlink.
3. Symlink `~/.claude/CLAUDE.md` → repo `CLAUDE.md`.
4. Symlink `~/.claude/skills/followup-tracking` → repo `skills/followup-tracking/`.
5. Author `CLAUDE.md` and `skills/followup-tracking/SKILL.md` per §4 and §5.
6. Add `README.md` (purpose, layout, how to extend) and `.gitignore`.
7. Initial commit.
8. Smoke test in a fresh Claude Code session: confirm `~/.claude/CLAUDE.md` content loads, confirm `followup-tracking` skill is listed in available skills.

## 7. Iteration roadmap (post-v1, in expected order of pain)

Each item is added only if real friction demands it.

1. **Severity rubric + merge-review wrapper** — revisit pain point B if `superpowers:requesting-code-review` continues to escalate minor findings.
2. **SessionStart hook reinforcing followup capture** — only if drift is observed in long sessions.
3. **Project-specific followup file location** — if the global per-day file proves wrong.
4. **Baseline-failure tests per writing-skills TDD** — once there are ≥2 personal skills worth protecting against regression.
5. **Home-manager / nix integration** — once the repo layout has stabilized and is unlikely to churn.
6. **Per-skill directive nudges in CLAUDE.md** — if the single `using-superpowers` nudge proves insufficient for specific skills.

## 8. Open decisions deferred to implementation

- Exact wording of the SKILL.md description (will be tuned during implementation; directive form is the requirement).
- Whether `metadata.severity` defaults to `medium` or is left absent.
- Whether the "save destination for the session" prompt is in v1 or v1.1 — leaning v1 if it's a few lines, defer otherwise.
- Whether the local mirror file's header includes a per-file YAML frontmatter (date, project) — leaning no for v1.
