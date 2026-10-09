# intake

For meeting notes, official minutes, a call summary, a mail or a document handed over in a project with a `## Project ledger` section.

## 1. Ingest

Pasted text as is. Files through Read; `.docx`, `.xlsx`, `.pptx` and `.pdf` through their skills. Note the source type: personal notes, official minutes, mail, other.

## 2. Read the receiving sections

Current state, Decisions, Open questions, Inbox, Now, Next, and every extension the source touches (meetings, milestones, contacts in CLAUDE.md). Run `ledger_check.py` for the next free ids. Do not propose anything before this step.

## 3. Read-out, per topic

- Who took part or wrote it, and the date.
- What was learned.
- Actions, each with owner and due date.
- What was decided, quoted from the source.
- New names, with roles.
- Matches with the ledger: an open `Q-n` the source answers, a `W-n` it unblocks or finishes, a `D-n` it contradicts or supersedes, an Inbox or Backlog item it repeats.

Official minutes and personal notes stay apart; name where they disagree.

## 4. Proposed placements, one line per target

```text
Log        ### YYYY-MM-DD – Steering call with Alex          (summary, links)
D-21       decision, Alex: reports go out monthly            supersedes D-14 (assumption: quarterly)
Q-12       answered by Alex's budget figure → delete, Closed: Q-12 in D-22
Q-30       new: switch the hosting provider? (Alex to think about it)
W-41       Now: send Alex the data dictionary. Owner: Sven. Due Friday
Current    Waiting on: no longer Q-12
Not taken  dashboard export later this year: already W-35 in Backlog
```

## 5. Numbered questions, then stop

Ask about everything the source leaves open: a name with two candidates, whether a statement was a commitment or a mention, dates, owners, garbled phrases. Stop and wait for the answers.

## 6. Verify what is cheap to check

Code, data, git history, the project's own files: before writing, not after.

## 7. Write

In one pass, one commit (`docs: <source> of YYYY-MM-DD`). Undecided items are `Q-n`. Closed ids go into a `Closed:` line. Current state is rewritten if any of its facts changed.

## 8. Close

Run `ledger_check.py` (zero errors). Report where each fact went, what was left out and why, what remains open. If it reports no audit yet or the last audit more than 30 days ago, suggest one (`audit.md`). Save any working preference the user stated as a memory.
