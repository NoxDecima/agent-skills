---
name: project-ledger
description: Use to set up, adopt, feed or audit a project's management docs - CLAUDE.md context plus status.md (current state, log, decisions, open questions) and workplan.md (inbox, now, next, backlog). Triggers on "set up a project ledger", "set up status and workplan", "adopt the ledger here", "move the docs onto a status / workplan system", "audit the docs", "are status and workplan current", "/project-ledger <setup|adopt|intake|audit>", and, in a project whose CLAUDE.md has a "## Project ledger" section, whenever the user hands over meeting notes, minutes, a call summary, a mail or a document to work into the docs ("here are my notes from the call", "integrate this mail").
---

# project-ledger

## Overview

A project ledger keeps a project's state in three files, one owner per fact:

- `CLAUDE.md` holds stable context and the `## Project ledger` section: the Owns table (which file and section owns which fact, plus an optional Check rule), the trigger table (what to update when), `Followups: workplan`, and optionally `Id prefixes:`.
- `status.md`: `## Current state` (at most 15 lines, read every session), `## Log` (newest first), `## Decisions` (`D-n`), `## Open questions` (`Q-n`), then extensions.
- `workplan.md`: `## Inbox` (unsorted, no ids), `## Now`, `## Next`, `## Backlog` (`W-n`), then extensions. The forward plan only.

Paths can differ per project; the Owns table is the authority.

## Core principle (load-bearing)

**Read the receiving files, propose, ask, stop. Write only after the user has answered, in one pass.** Every mode shows what it would write where and asks numbered questions before touching a file. An item the user did not decide is a `Q-n`, never a `D-n`.

## Modes

| Mode | When | Procedure |
|---|---|---|
| setup | No ledger section, no docs beyond a README | `setup.md` |
| adopt | Existing docs, no ledger section | `adopt.md` |
| intake | Notes, minutes, mails or documents handed over in a ledger project | `intake.md` |
| audit | Asked to audit or clean up the docs; `ledger_check.py` reports an old or missing audit | `audit.md` |

Read the mode's file (in this skill's base directory) before doing anything else. Intake in a project without a ledger section: offer adopt first; if declined, give the read-out and write nothing.

## Entry formats

```markdown
## Current state

As of YYYY-MM-DD.

- Phase: …
- Live: …
- Waiting on: … (W-6, Q-12)

### YYYY-MM-DD – <title>              ← Log entry, newest first; an audit's title is "Audit: <n> findings"
- <bullets>
- Closed: W-17, Q-41.                 ← whenever the entry closes ids

- **D-12** (YYYY-MM-DD, decision, Sven): <text>
- **D-13** (YYYY-MM-DD, assumption, ours): <text> Superseded by D-20.
- **D-60** (YYYY-MM-DD, decision, Alex): <text answering Q-41> Closed: Q-41.

- **Q-41** (YYYY-MM-DD, asked of Alex): <text>
  - YYYY-MM-DD: <update while open>

- YYYY-MM-DD · <source> · <one line>  ← Inbox; optional indented sub-line with file:line

- **W-17** <title>. Owner: Sven. Waits on: Q-45, W-3. <notes>
```

Decision types: `decision`, `assumption`, `recommendation`; the third field names who decided (`ours` for a working assumption).

## Rules

- **Ids** `D-`, `Q-`, `W-` (plus declared `Id prefixes:`) are never reused or renumbered. `ledger_check.py` prints the next free ids. An Inbox item gets its `W-` id when triage moves it to Now, Next or Backlog.
- **Closing**: a finished or dropped `W-` and an answered `Q-` are deleted from the live section; a Log entry (or the `D-` that answers the question) lists them in a `Closed:` line. Never strike through, never mark done in place.
- **Decisions** are never edited. A change is a new `D-` and `Superseded by D-n.` appended to the old one.
- **Current state** is rewritten, not appended, in the same commit as any change to its facts. State only; it links `W-` ids instead of restating tasks.
- **Same commit**: the owning file changes in the same commit as the change it records.
- **One owner per fact**: everything else links (`status.md § Decisions, D-12`).
- **Archive**: above 40 KB, the oldest Log months move to `status-archive.md`; Decisions and Open questions are never archived.

## Shared habits

1. Read the receiving sections before proposing: Current state, Decisions, Open questions, Inbox, Now, and the extensions involved.
2. Numbered questions, then stop and wait. A garbled or positional answer: state your reading in one line and ask for a yes.
3. Write in one pass with exact-string anchors that fail loudly when they do not match.
4. Run `python <skill base directory>/ledger_check.py --root <project root>`: zero errors before committing.
5. One commit per pass, message `docs: <what changed>`.
6. Save a working preference the user states as a memory.

## Red flags - stop and re-read this skill

- About to edit a file before the user answered the numbered questions.
- Judging the docs before `ledger_check.py` has run.
- Resolving a name, owner or date the sources do not state, instead of asking.
- A migration about to drop a split the old docs kept (headings, groups, a tag on items).
- An audit about to end without an Inbox triage and its `Audit:` Log entry.

## Rationalizations - these are violations, not exceptions

| Rationalization | Reality |
|---|---|
| "The user asked me to integrate / clean up, so writing directly is what they want." | They want the result they would have approved. Propose, ask, stop; write after the answers. |
| "I only fixed what was clearly wrong." | Clearly wrong is a finding, not a licence. Report it with the fix; the user may keep it or fix it differently. |
| "The migration is mechanical, no need for a mapping report." | The report is where the user catches the wrong mapping before it is written. |
| "The split is just headings; the ids carry everything." | A division the project kept on purpose is an extension: propose it with an Owns row and, where one fits, a Check rule. |
| "Reading the files carefully is enough." | Run `ledger_check.py` first; it finds what reading misses (old Inbox items, duplicate ids). |
| "The only contact named must be who answered." / "The commit date is close enough." | A name, owner or date the sources do not state is a question, not an inference. |
