# followup-tracking v2 — Design

Date: 2026-08-18
Status: approved

## Purpose

Two refinements to the `followup-tracking` skill: (1) triage offers **Do now**
as the suggested default action alongside Keep/Drop/Edit; (2) persistence
becomes destination-resolved — **FUTURE.md, Linear, or both** — replacing the
`~/claude-followups/` local mirror entirely.

Capture (TaskCreate, `metadata.kind = "followup"`), the pre-summary audit,
severity rules, and the Linear issue template are unchanged.

## 1. Triage: Do now / Keep / Drop / Edit

Each item is presented as `action: Do now / Keep / Drop / Edit?` with **Do
now always listed first as the suggested default**.

- Decisions are collected per item first; then Do-now items are executed
  immediately, one at a time in list order; then Keeps are persisted.
- If a Do-now item balloons mid-fix (more than a contained change), pause it
  and re-offer Keep/Drop for that item instead of silently sinking time.
- Completed Do-now items are marked completed in TaskList and are never
  persisted.
- Keep → persist (section 2). Drop → delete from TaskList. Edit → revise and
  re-present, as today.

## 2. Persistence destinations

Destinations: `linear`, `future`, or `both`. The `~/claude-followups/` mirror
is removed from the flow entirely.

**Linear** — unchanged: `mcp__linear-server__save_issue` with the existing
markdown body template.

**FUTURE.md** — adopts the established TODO.md convention
(github.com/todo-md/todo-md): GFM checkbox one-liners with indented
description sub-lines.

- Default path: `FUTURE.md` at the project root. Overridable via the
  CLAUDE.md declaration (`Followups: future=docs/FUTURE.md`).
- File starts with a `# FUTURE` header (created with the first persisted
  item if the file does not exist).
- Entry format — subject as a checkbox one-liner; indented sub-lines carry
  as much context as the item needs (origin `file:line`, why deferred,
  suggested next step, date); a `Linear: <issue-id>` sub-line is added when
  dual-persisted:

  ```markdown
  - [ ] <subject>
    <context: surfaced-during, origin file:line, why deferred, next step,
    (YYYY-MM-DD)>
    Linear: <issue-id>          ← only when destination is `both`
  ```

- New items append to the end of the open list. Ticking `- [x]` is the
  user's business; the skill does not manage entry lifecycle.

## 3. Destination resolution

In this exact order:

1. **Project CLAUDE.md declaration** — a line `Followups: linear | future |
   both`, with optional path override `future=<path>`. Use without
   prompting. Backward compatible: a CLAUDE.md with only a `Linear:
   team=X project=Y` line resolves to `linear`.
2. **Conversation context** — a destination used earlier in this chat is
   suggested as a default in a confirmation prompt (never silently reused).
3. **Discovery** — no declaration, no chat precedent, but a `FUTURE.md`
   exists at the project root → suggest it as the default in the
   clarification question (never silently use it).
4. **Ask** — prompt with no defaults.

**Record-the-choice offer:** whenever the destination was resolved by asking
the user (rungs 3–4 — i.e., no CLAUDE.md declaration existed), offer once to
record the chosen destination as a `Followups:` line in the project
CLAUDE.md so future sessions resolve at rung 1. Only on explicit acceptance;
declining never re-offers in the same session. If the user also supplied
Linear team/project at ask-time, an accepted offer records the
`Linear: team=X project=Y` line alongside the `Followups:` line, so neither
is re-asked.

## 4. Failure handling

- **Linear call fails** — surface the error verbatim and offer to write the
  item to FUTURE.md instead, so the item is not lost.
- **FUTURE.md write fails** — surface the error verbatim.
- In every failure case the item stays in TaskList until successfully
  persisted or explicitly dropped. TaskList is the only in-flight safety
  net; swallowing a persistence failure is a violation.

## 5. Collateral updates

Mirror references exist in three places and must all change:

- `GLOBAL.md` (symlinked to `~/.claude/CLAUDE.md`): remove the "Persisted
  items also append to `~/claude-followups/YYYY-MM-DD.md`" sentence; update
  the Linear-destination-resolution paragraph to the new chain including
  `Followups:` and the record-the-choice offer.
- `README.md`: remove the `mkdir -p ~/claude-followups` setup step and the
  mirror mention in Layout.
- `skills/followup-tracking/SKILL.md`: triage prompt, Persist phase, failure
  handling, and every rationalization-table row or red-flag line that
  references the mirror.

## 6. Build process

Per repo discipline (TDD-for-skills): author a triage-phase pressure
scenario exercising the new behaviors — Do-now-first presentation and
execution, FUTURE.md persistence at each resolution rung (declaration,
chat precedent, discovery suggestion, ask + record-the-choice offer), and
the Linear-failure fallback. Run it against the current (v1) skill to record
baseline failures, apply the minimal edit that closes them, and verify with
the edited skill. Existing v1 test files stay untouched as historical
record; new evidence lands in new `tests/followup-tracking-v2-*` files.
