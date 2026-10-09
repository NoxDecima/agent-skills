# project-ledger — Design

Date: 2026-10-09
Status: approved (design agreed section by section with Sven, 9 Oct)

## 1. Purpose

A global skill that sets up and maintains a three-file project-management
system in a repository: stable context in `CLAUDE.md`, state and history in
`status.md`, the forward plan in `workplan.md`. Four modes: **setup** (new
project), **adopt** (existing project), **intake** (notes, minutes, mails,
documents), **audit** (find stale or misplaced information, reconcile with
the user). Covers client engagements and internal projects; the client parts
are optional extensions.

## 2. Background

The system grew twice on its own:

- **von-saldern-logistik**: `CLAUDE.md` (stable context), `status.md`
  (Findings, Decisions and working assumptions, Open questions),
  `workplan.md` (Open, Next steps, Backlog). One owner per fact, links
  instead of copies, done steps deleted once status.md records them.
  The intake flow (read out, propose entries, ask numbered questions, wait,
  write) lives in a project memory.
- **EWS**: the same split, plus an Owns table and a "Keeping Docs Current"
  trigger table in `CLAUDE.md`, a Quick Status block, numbered Key
  Decisions, stable task ids, an Inbox, and three project skills
  (`notes-intake`, `docs-audit` with `docs_check.py`,
  `external-docs-refresh`).

Drift observed in von Saldern after five weeks: `status.md` at 250 KB with
no current-state summary and 26 of 45 client questions struck through but
kept; 11 KB of rule-version history inside the auto-loaded `CLAUDE.md`;
decisions referenced by date although one day holds four; leftover step
numbers in the workplan; no mechanical check.

## 3. Non-goals

- No sync with Linear or another tracker (followup-tracking keeps Linear).
- No hooks; daily upkeep comes from the ledger section in the project's
  `CLAUDE.md`, which is loaded every session.
- No generation of external-facing documents; external docs are an
  extension the audit can flag as stale.
- No harvesting of `TODO` comments in code (followup-tracking's job).
- Rollout to von Saldern and EWS is out of scope (§ 10).

## 4. File model

### 4.1 Roles

| File | Holds | Read |
|---|---|---|
| `CLAUDE.md` | Stable context; the ledger section (§ 4.7) | Every session (auto-loaded) |
| `status.md` | Current state, Log, Decisions, Open questions | Current state every session, the rest on demand |
| `workplan.md` | Inbox, Now, Next, Backlog: the forward plan only | On demand |

Default names and location: `status.md` and `workplan.md` at the repository
root. Other names or paths are recorded in the Owns table, which is the one
place the script and the modes read them from.

Core section headings are fixed (H2): `## Current state`, `## Log`,
`## Decisions`, `## Open questions` in status.md; `## Inbox`, `## Now`,
`## Next`, `## Backlog` in workplan.md, in that order. Extensions follow
the core sections.

### 4.2 Ids

- `D-n` decisions, `Q-n` open questions, `W-n` workplan items.
- Never reused, never renumbered. Numbers keep counting across closures.
- A workplan item gets its `W-` id when it leaves the Inbox; Inbox items
  have no id.
- Log entries are referenced by date and title, not by id.
- A project may add its own prefixes as an extension (EWS: `GT-`, `FC-`),
  declared in an `Id prefixes: GT, FC` line of the ledger section (§ 4.7).
- An id is **defined** where it opens a list item in bold
  (`- **D-12** …`); every other occurrence is a **reference**.

### 4.3 status.md

**Current state** — at most 15 non-blank lines; first line `As of
YYYY-MM-DD.` It holds state only: the phase or milestone, what is live
(versions, environments), what waits on whom. It links `W-` ids rather than
restating tasks. It is rewritten, not appended, in the same commit as any
Log entry that changes one of its facts.

**Log** — newest first. Entry format:

```markdown
### YYYY-MM-DD – <title>
- <bullets>
- Closed: W-17, Q-41.
```

The `Closed:` line is present whenever the entry closes ids (§ 4.5). An
audit's own entry is titled `Audit: <n> findings` (§ 5.6).

**Decisions** — one list item each, in id order:

```markdown
- **D-12** (YYYY-MM-DD, decision, Sven): <text>
- **D-13** (YYYY-MM-DD, assumption, ours): <text> Superseded by D-20.
```

The type is `decision`, `assumption` or `recommendation`; the third field
names who decided (a person, or `ours` for a working assumption). A
decision is never edited; the only change ever made to it is appending
`Superseded by D-n.` when a later decision replaces it.

**Open questions** — one list item each, in id order:

```markdown
- **Q-41** (YYYY-MM-DD, asked of Reinhardt): <text>
  - YYYY-MM-DD: <partial answer or update>
```

Dated update sub-lines are allowed while the question is open.

### 4.4 workplan.md

**Inbox** — unsorted items, no id:

```markdown
- YYYY-MM-DD · <source> · <one line>
```

Source examples: `call with Reinhardt`, `followup (rule_version 9 build)`,
`noticed`. An optional indented sub-line may carry a location (`file:line`).

**Now / Next / Backlog** — one list item each:

```markdown
- **W-17** <title>. Owner: Sven. Waits on: Q-45, W-3, Reinhardt. <notes>
```

`Owner` and `Waits on` are optional. Now = being worked on; Next = decided
and ordered; Backlog = looked at, kept, not scheduled.

### 4.5 Lifecycle of closed items

- A finished or dropped `W-` is deleted from the workplan; a Log entry
  records it (dropped: with the reason) and lists it in `Closed:`.
- An answered `Q-` is deleted from Open questions; the answer becomes a new
  `D-` or a Log entry, which cites the `Q-` and lists it in `Closed:`. A
  `Closed:` line may end a Log entry or a decision item
  (`- **D-60** (…): <text> Closed: Q-41.`); the script reads both.
- A superseded `D-` stays, marked (§ 4.3). Decisions are never closed.
- Archive: when status.md exceeds 40 KB, audit proposes moving the oldest
  Log months to `status-archive.md` (same entry format, newest first,
  registered in the Owns table on creation). The archive is read on demand
  only. Decisions and Open questions are never archived.

### 4.6 Extensions

Any section after the core sections of status.md or workplan.md, any
project-specific section in `CLAUDE.md` that the audit should check, or a
separate file. Every extension has an Owns-table row. An extension never
takes over a core role: no second decision list, no done-log in the
workplan.

Extensions setup offers: Risks (status.md); Milestones (workplan.md, for
projects with dated horizons); `meetings.md` (one section per meeting, for
projects with many meetings); external docs (may restate internal facts,
Check rule flags them when a source changed after them); the split of Open
questions into `### For the client` and `### Internal`; a contract brief
(`CLAUDE.md`).

### 4.7 The ledger section in CLAUDE.md

Written by setup and adopt from `templates/claude-section.md`:

```markdown
## Project ledger

Read status.md § Current state at the start of every session.
Update the owning file in the same commit as the change. One owner per fact; everything else links.
Followups: workplan

| Section / file | Owns | Check |
|---|---|---|
| status.md § Current state | Phase, what is live, waiting on whom (≤15 lines) | |
| status.md § Log | Dated entries, newest first | |
| status.md § Decisions | D-n, typed, who decided | |
| status.md § Open questions | Q-n | |
| workplan.md § Inbox | Unsorted items: date · source · line | |
| workplan.md § Now | W-n being worked on | |
| workplan.md § Next | W-n decided and ordered | |
| workplan.md § Backlog | W-n kept, not scheduled | |

| When this happens | Update |
|---|---|
| Something is learned, shipped or happens | Log entry; Current state if its facts change |
| A decision is made | New D-n; mark any decision it supersedes |
| A question opens / is answered | New Q-n / delete it, answer as D-n or Log entry citing it, `Closed:` line |
| Something is noticed for later | Inbox |
| A W-n is finished or dropped | Delete it; Log entry with `Closed:` line (dropped: with the reason) |
| A stable fact changes (scope, people, rules, layout) | CLAUDE.md |
```

Extensions add rows to both tables, and an `Id prefixes:` line below
`Followups:` when they bring their own ids. The **Check** column is optional: a
one-line rule the audit applies to that row (examples: "Past dates have a
Log entry; no run or PR details" for a Key dates section; "Empty once the
offer has arrived" for a "To settle with the new offer" section; "run
`scripts/x.py`" for a project check script that adopt kept).

## 5. Modes

### 5.1 Shared habits

- Read the receiving files before proposing anything.
- Ask numbered questions, then wait. A garbled or positional answer: state
  the reading in one line and ask for a yes.
- Write in one pass (exact-string anchors that fail loudly when they do not
  match), one commit, then run `ledger_check.py`.
- Treat the user's answers as decisions only where the user says so;
  anything undecided becomes a `Q-`.

### 5.2 Triggering

The skill fires when the user names a mode or the skill ("set up a
project ledger", "adopt the ledger here", "audit the docs", "are status
and workplan current", "/project-ledger <mode>"), and for intake when the
user hands over notes, minutes, mails or documents in a project whose
`CLAUDE.md` has a `## Project ledger` section ("here are my notes from the
call", "integrate this mail"). Without a ledger section, intake offers
adopt first; if declined, it gives the read-out and writes nothing.

### 5.3 setup

1. Detect what exists. Docs beyond a README (status-, progress-,
   roadmap-type files, `TODO.md`, `FUTURE.md`, `docs/*.md`) → suggest adopt
   instead.
2. One numbered round of questions: client or internal project; which
   extensions (§ 4.6); paths other than the defaults; the first Current
   state (phase, what is live, waiting on whom).
3. Write `status.md` and `workplan.md` from the templates and the ledger
   section into `CLAUDE.md` (create `CLAUDE.md` with only that section if
   it is missing). First Log entry: `Project ledger set up`.
4. Run `ledger_check.py` (zero errors), commit.

### 5.4 adopt

1. **Inventory**: `CLAUDE.md`, README, status-, progress- and roadmap-type
   files, `TODO.md` / `FUTURE.md`, `docs/*.md`, and project memories that
   describe a documentation process. One subagent per file group on large
   projects. The inventory also detects what the project built for itself:
   - **divisions**: sections or files with no core equivalent (a "To settle
     with the new offer" section, the client/internal question split, task
     chains, `meetings.md`);
   - **checks**: check scripts, project audit skills, written documentation
     rules in `CLAUDE.md` ("keep the three files free of duplication").
2. **Mapping report**: every section or fact with its target, its id and
   the action (move, merge, close, archive); the references to rewrite.
   Existing numbers become ids (`question 41` → `Q-41`, `Key Decision 13`
   → `D-13`); unnumbered items are numbered in date order. Each detected
   division or check gets a proposal with a one-line reason (in recent use,
   holds content, not a duplicate of the core): keep as an extension with
   a drafted Owns row and a Check rule converted from the existing check,
   fold into the core, or drop. A project script with checks
   `ledger_check.py` lacks stays and is named in a Check rule. Closed items
   follow § 4.5; struck-through items are closed items.
3. The user answers per item.
4. Apply in one pass, rewrite the references, write the ledger section and
   `Followups: workplan`, move an existing `FUTURE.md` into the Inbox and
   delete it, run `ledger_check.py`, commit. Propose deleting the memories
   the ledger now covers.

### 5.5 intake

1. **Ingest**: pasted text as is; files through Read or the docx, xlsx and
   pdf skills.
2. **Read the receiving sections**: Current state, Decisions, Open
   questions, Inbox, Now, and the extensions the source touches.
3. **Read-out per topic**: who took part or wrote it; what was learned;
   actions with owner and date; decisions; new names with roles. Official
   minutes and personal notes stay apart, and disagreements between them
   are named. Contradictions with an existing `D-` are flagged.
4. **Proposed placements**, one line per target: Log entry, new `D-`,
   `Q-` opened or answered, Inbox items, Current state change, extension
   updates.
5. **Numbered questions, then wait.**
6. **Verify what is cheap to check** (code, data, git history) before
   writing.
7. **Write** in one pass, one commit.
8. **Close**: run `ledger_check.py`; report where each fact went, what was
   left out and why, what remains open; save any preference the user
   stated as a memory.

### 5.6 audit

Runs on request. `ledger_check.py` reports the days since the last audit
(the newest Log entry titled `Audit: …`), so intake and setup can suggest
one.

1. **Mechanical checks**: run `ledger_check.py` (§ 6).
2. **Core judgement checks** (agent; one subagent per file group on large
   projects): Current state stale against the Log and Now; finished work
   still in the workplan; decisions edited instead of superseded; Log
   entries holding a decision without a `D-`; questions answered in the
   Log but still open; facts duplicated across owners; history or progress
   in `CLAUDE.md`.
3. **Extensions**: each Check rule; the generic checks for every
   extension: it holds what its Owns row says, nothing in it belongs to
   another owner, no duplicated facts.
4. **Inbox triage**: a proposed target per item: a `W-` in Now, Next or
   Backlog, a `Q-`, a Log entry, or drop.
5. **Report**: numbered findings `F-n`, each with file and line, what is
   wrong and the proposed fix; the Inbox items with their proposed targets.
   The report is a working file in the session's scratch space, not
   committed. Findings kept in the previous audit (its Log entry) are not
   reported again unless the content changed.
6. **Reconcile**: the user answers each finding with fix, keep or Inbox,
   and each Inbox item with its target. Everything is applied in one pass
   and committed. One Log entry `### YYYY-MM-DD – Audit: <n> findings`
   records the counts (fixed, kept, to Inbox), lists the kept findings in
   one line each, and carries the `Closed:` line for anything closed.

## 6. ledger_check.py

Stdlib Python, in the skill folder. `python ledger_check.py [--root PATH]
[--self-test]`; root defaults to the git top level of the working
directory. It reads the ledger section of `<root>/CLAUDE.md`: the Owns
table gives the files and sections (the status file is the one with the
`§ Current state` row, the workplan the one with `§ Inbox`), `Id
prefixes:` the extension prefixes, `Followups:` its presence. Log headings
accept an en dash or a hyphen after the date. Ids are checked in all files
of the Owns table, `CLAUDE.md` and the archive.

**Errors** (exit 1):
- no `## Project ledger` section, or no Owns table;
- a core section missing or out of order;
- an Owns row whose file or `§ section` heading does not exist;
- an H2 in status.md or workplan.md without an Owns row;
- an id defined twice;
- a reused id: defined live and listed in a `Closed:` line;
- a dangling reference: an id neither defined live nor listed in a
  `Closed:` line;
- done markers in the workplan (`~~`, `✓`, `[x]`, `(done)`);
- no `Followups:` line.

**Info** (exit 0):
- Inbox items older than 14 days;
- status.md above 40 KB (archive proposal);
- Current state above 15 non-blank lines, no `As of` line, or dated
  before the newest Log entry;
- leftover `to confirm` text;
- references to closed ids in the live parts (Current state, Open
  questions, the workplan);
- days since the last audit;
- the next free id per prefix (highest defined or closed + 1), for
  writing new entries.

Thresholds are module constants. `--self-test` builds a fixture in a
temporary directory, plants one instance of every error and info case,
and asserts each is reported.

## 7. Packaging

```
claude-config/skills/project-ledger/
  SKILL.md                  triggers, shared habits, mode routing, red flags
  setup.md  adopt.md  intake.md  audit.md     one per mode, read on demand
  templates/status.md  templates/workplan.md  templates/claude-section.md
  ledger_check.py
```

SKILL.md stays short: the description carries the trigger phrases of all
four modes; the body routes to the mode file and holds the shared habits
and red flags (writing before the answers are in; proposing without
reading the receiving files; recording an undecided item as a `D-`;
editing a decision instead of superseding it; keeping a done item in the
workplan).

## 8. Integration

- **followup-tracking**: new destination `workplan`. A kept item is
  appended to the workplan Inbox as
  `- YYYY-MM-DD · followup (<task context>) · <title>`, with the location
  as an indented sub-line when there is one. Resolution: rung 1 accepts
  `Followups: workplan`; rung 3 suggests `workplan` when `workplan.md` (or
  the path in the Owns table) has an `## Inbox` section, before checking
  for `FUTURE.md`. `workplan` does not combine with `linear`.
- **GLOBAL.md**: the followup destination lines (lines 11–18 today) name
  `workplan` the same way.
- **README.md** of claude-config: the skill in the list and its `ln -s`
  line; the link `~/.claude/skills/project-ledger` is created
  (`~/.claude-uhrwerk/skills` points at `~/.claude/skills`).
- The implementation plan goes to `docs/plans/2026-10-09-project-ledger-plan.md`.

## 9. Testing

TDD for skills, as for the other skills in `tests/`: each scenario is run
without the skill (baseline) and with it, observations recorded.

- **Fixture**: `tests/project-ledger-fixture.sh` builds (a) a ledger
  project with planted defects: stale Current state, a finished `W-` still
  in Now, a duplicate id, an edited decision, an Inbox item 30 days old, a
  broken extension Check rule; (b) a von-Saldern-shaped project without a
  ledger: struck-through numbered questions, dated decisions, leftover
  step numbers, a "To settle with the new offer" section, a check script.
- **Scenarios**: intake (meeting notes handed over: does the agent write
  before asking?); audit on fixture (a) (are all planted defects found and
  reported before anything is changed?); adopt on fixture (b) (mapping
  report complete, existing numbers kept, the division and the check
  proposed as extensions).
- `ledger_check.py --self-test` passes.

## 10. Rollout (out of scope)

Each a separate session with Sven, after the skill is built:

1. adopt on von-saldern-logistik; retires the project memory
   `meeting-notes-interpret-then-confirm`.
2. adopt on EWS; retires `notes-intake`, `docs-audit` with
   `docs_check.py`, and `external-docs-refresh` as far as the ledger
   covers them.

## 11. Design decisions (brainstorm of 9 Oct)

| Question | Chosen | Not chosen |
|---|---|---|
| Project kinds | Client and internal; client parts optional | Client only |
| Structure | Fixed core, extensions in the Owns table | Roles only; full template |
| Names | `status.md`, `workplan.md` | `progress.md`/`plan.md`; status split into three files |
| Borrowed | ADR (numbered, superseded not edited), Cline (current state apart from history), RAID (typed decisions; Risks only as an extension) | RAID Risks in the core |
| Inbox | Core section; audit triages it | Capture straight into Now/Next/Backlog |
| Extension checks | Check column in the Owns table, own audit step | Agent judgement only |
| Ids | `D-`/`Q-`/`W-`, never reused | Plain numbers per section; ids for D and Q only |
| Closed items | Leave the live files; Log archive above 40 KB | No archive; struck through in place |
| Current state | ≤15 lines, rewritten on change, state only | Written by audit only; none |
| Audit checks | Generic script plus agent pass | Agent only |
| Adopt | Full migration through the audit flow, keeping existing numbers; detects divisions and checks | Fresh start; new rules for new entries only |
| EWS features | Same-commit rule and the intake procedure in the core; meetings, external docs, milestones as extensions | Owed-to list, "to confirm" markers, "Last updated" lines, committed audit reports |
| Followups | New `workplan` destination | Unchanged; FUTURE.md retired globally |
