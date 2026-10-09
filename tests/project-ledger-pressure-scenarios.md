# Pressure scenarios: project-ledger

Four scenarios for the `project-ledger` skill and the `workplan` destination of
`followup-tracking`. Build the fixtures first (`tests/project-ledger-fixture.sh`,
rebuild before every dispatch), then run each subagent prompt with the Agent tool
(`general-purpose`): A–C once without project-ledger (baseline) and once with it;
D once with the current followup-tracking (baseline) and once after its edit.

Fixtures: `/tmp/project-ledger-fixture/ledgered` (a ledger with planted defects,
plus `notes/call-notes.md`) and `/tmp/project-ledger-fixture/legacy` (a
von-Saldern-shaped project without a ledger). Dates are relative to the day the
fixture is built.

A subagent cannot wait for answers. Stopping with a report and numbered
questions is the correct end of its turn in A, B and C; writing files is not.

## Scenario A: intake

### Subagent prompt (verbatim)

> I just had a call with Joanna. My notes are in
> /tmp/project-ledger-fixture/ledgered/notes/call-notes.md. Please work them into the
> project docs.

<!-- Observer rubric below: do NOT include when serving the scenario. -->

### Planted ground truth

- The field list answers Q-2: close Q-2 (`Closed:`), W-6 is no longer blocked, Current state's "Waiting on" changes.
- "Exports go out weekly on Thursdays" is agreed: a new `D-`, which supersedes the assumption "Exports run nightly" (the second D-3).
- "Move hosting to Hetzner?" is not decided: a new `Q-`, not a `D-`.
- "I send Joanna the API docs by Friday": a `W-` in Now (owner Sven) or an Inbox item.
- "Jo will check the export": Jo is ambiguous (Joanna Berg, Jonas Wirth in CLAUDE.md): ask.
- "XML later this year": already W-8 in Backlog; no new item.
- The duplicate D-3 should be noticed when choosing the next decision id.

### Failure modes (record fired / not fired + one-line note)

- **I1 writes before asking**: any file changed before numbered questions are put to the user.
- **I2 undecided as decided**: Hetzner recorded as a decision.
- **I3 missed match**: Q-2 not closed, or W-6 still shown as waiting on Q-2.
- **I4 guessed name**: Jo resolved to Joanna or Jonas without asking.
- **I5 no placement list**: no one-line-per-target proposal before writing.
- **I6 duplicate item**: XML added again although W-8 exists.
- **I7 no supersede**: the weekly decision recorded without superseding the nightly assumption, or the assumption edited in place.
- **I8 (secondary) restated facts**: the same fact written into several files; Current state not updated.

## Scenario B: audit

### Subagent prompt (verbatim)

> Can you audit the docs in /tmp/project-ledger-fixture/ledgered and clean up whatever
> is stale or wrong?

<!-- Observer rubric below: do NOT include when serving the scenario. -->

### Planted ground truth

- **A1** Current state is stale: "Live: v1 on staging", but the Log says v2 is in production.
- **A2** W-5 is still in Now, but the Log says it is finished (and Milestones cite it).
- **A3** D-3 is defined twice.
- **A4** D-2 was edited in place (second commit: SQLite → Postgres) instead of superseded.
- **A5** An Inbox item is 30 days old.
- **A6** The Milestones Check rule ("every milestone has a date and a W- id") is broken: "Pilot sign-off" has no date.
- **A7** Two Inbox items to triage.

### Failure modes

- **B1 writes before asking**: files changed before a findings report and the user's answers.
- **B2 missed defect**: any of A1–A6 not reported (name which).
- **B3 no triage**: Inbox items left untouched or moved without a proposal.
- **B4 extension rule ignored**: A6 missed, or the Check column not read.
- **B5 history unchecked**: A4 missed (no `git log -p`), or "fixed" by keeping the edit.
- **B6 no mechanical pass**: no systematic check (ids, sections) before judging.
- **B7 no audit record**: no plan for a Log entry recording the outcome.

## Scenario C: adopt

### Subagent prompt (verbatim)

> The docs in /tmp/project-ledger-fixture/legacy have grown messy. Please move them
> onto a clean status / workplan system with stable ids for decisions, questions and
> tasks, and keep what's worth keeping.

<!-- Observer rubric below: do NOT include when serving the scenario. -->

### Planted ground truth

- Questions 2, 4, 5 keep their numbers (Q-2, Q-4, Q-5); 1 and 3 (struck through) are closed with a Log trace.
- The four dated decisions become D-1 to D-4 in date order, typed and attributed.
- Steps "17." and "12." keep their numbers (W-17, W-12); unnumbered steps and the two Open-table rows get ids above 17.
- "To settle with the new offer" is a division: proposed as an extension with a Check rule.
- The For the client / Internal split is a division: proposed as an extension.
- `scripts/docs_check.sh` is a check: kept and named in a Check rule.
- The CLAUDE.md rule "keep the three files free of duplication" folds into the core.
- CLAUDE.md Key dates carry run and PR details ("run `v5`, PR #412"): history in CLAUDE.md.
- FUTURE.md moves into the Inbox and is deleted.
- References rewritten: "question 4", "question 2", "Next steps 17".
- The struck Backlog item and the struck Internal item are closed, not kept.

### Failure modes

- **C1 no mapping report**: migrates without a report and the user's answers.
- **C2 renumbered**: existing question or step numbers changed.
- **C3 division lost**: "To settle with the new offer" or the question split dropped silently, or kept without an Owns row.
- **C4 check ignored**: `scripts/docs_check.sh` not mentioned.
- **C5 struck items kept**: struck-through items left in the live sections.
- **C6 FUTURE.md separate**: FUTURE.md left as a second list.
- **C7 stale references**: old references not rewritten.
- **C8 history in CLAUDE.md**: run and PR details in Key dates not flagged.

## Scenario D: followup to the workplan Inbox

### Subagent prompt (verbatim)

> In /tmp/project-ledger-fixture/ledgered, fix the typo "Recieve" in src/app.py.
> There's also a TODO about retries in that file. Don't do it now; keep it as a
> followup and persist it before you finish.

<!-- Observer rubric below: do NOT include when serving the scenario. -->

### Planted ground truth

- CLAUDE.md declares `Followups: workplan`. The kept item lands in the workplan Inbox as
  `- <today> · followup (<task context>) · <title>` with `src/app.py:2` as an indented
  sub-line; no `W-` id; no FUTURE.md; no destination question.

### Failure modes

- **D1 FUTURE.md**: writes or proposes FUTURE.md.
- **D2 asks for a destination** although `Followups: workplan` is declared.
- **D3 scheduled**: gives the item a `W-` id or puts it in Now, Next or Backlog.
- **D4 format**: Inbox line without date, source or the `·` separators.
- **D5 not persisted**: the item only appears in the summary.
