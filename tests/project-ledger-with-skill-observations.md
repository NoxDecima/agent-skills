# With-skill observations (project-ledger installed; followup-tracking edited)

**Date:** 2026-10-09
**Subagent type:** general-purpose (Claude Code Agent tool)
**Fixture:** /tmp/project-ledger-fixture, rebuilt before each scenario
**Controller cwd:** the same von-Saldern-logistik worktree as the baseline (same memory confound).
**Skill trigger:** all four subagents used the skills from the verbatim prompts; no "Use the project-ledger skill." line was needed.

## Scenario A: intake

### Response (verbatim)

````
I haven't changed any files yet. The project-ledger intake rule is to read, propose and ask, and only write once the user has answered. As a subagent I can't ask Sven myself, so please put the questions below to him. Once he answers, I'll make all the changes in one commit.

Note: the notes belong to the **Orbit** project at /tmp/project-ledger-fixture/ledgered/, not the von Saldern repo. All changes would go to that project's status.md and workplan.md.

**Read-out of the call** (call-notes.md: Sven's personal notes, 2026-10-09, 30 min; Sven and Joanna, "Jo" joined late)
- **Learned:** Joanna sent the field list for the accounting import: order id, customer number, net amount, VAT rate, booking date. "That's all they need." This answers **Q-2** and unblocks **W-6**.
- **Decided:** "exports go out weekly on Thursdays, not nightly." This replaces the working assumption that exports run nightly, which is recorded as the second **D-3**. **W-6** is still titled "Nightly export job".
- **Actions:**
  - Sven sends Joanna the API docs "by Friday".
  - "Jo" checks the export with the new fields "next week".
- **Open:** maybe move hosting to Hetzner; Joanna will think about it, nothing decided. This becomes a new question.
- **Request:** Joanna asked whether we can do XML later this year. This repeats **W-8** (Backlog: second export format, XML).

**Proposed placements** (`ledger_check.py` gives next ids D-4, Q-4, W-9)
```
Log      ### 2026-10-09 – Call with Joanna   (summary, field list, links D-4/Q-4/W-9/W-10; Closed: Q-2)
Q-2      answered with the field list → delete, Closed: Q-2 in the Log entry
D-4      decision, <who?>: exports go out weekly on Thursdays, not nightly; "Superseded by D-4." added to the nightly-assumption D-3
W-6      retitle "Weekly export job (Thursdays)", drop "Waits on: Q-2", add the five fields
Q-4      new (asked of Joanna): move hosting to Hetzner? Joanna to think about it
W-9      Now: send Joanna the API docs. Owner: Sven. Due <date?>
W-10     Now/Next: check the export with the new fields. Owner: <Jo?>. Due week of 2026-10-12
W-8      add a note: Joanna asked on 2026-10-09 whether XML is possible later this year (no new item)
Current  rewrite, as of 2026-10-09: Live: v2 in production (Log of 10-06; the current text still says v1 on staging); Waiting on: Joanna's answer on hosting (Q-4); no longer Q-2
```

**Pre-existing ledger problems found** (`ledger_check.py`: 1 error, 4 info)
- ERROR: **D-3 is defined twice** (status.md lines 28 and 29). Ids are never renumbered, so the second one needs a decision from Sven.
- **W-5** was finished on 2026-09-29 according to the Log but is still listed in Now. It should be deleted and added to a `Closed:` line.
- The milestone "Pilot sign-off by Joanna (W-6)" has no date, which breaks the Milestones check rule.
- The Inbox item of 2026-09-09 ("ask whether exports need a currency column") is 30 days old. The field list doesn't include a currency field.
- There has been no audit yet.

**Questions for Sven**
1. Who is "Jo": Joanna Berg or Jonas Wirth (our developer)? This decides the owner of W-10.
2. The weekly-Thursday decision says "we agreed". Should D-4 be recorded as decided by Joanna, by Sven, or by both?
3. "API docs by Friday": today is Friday 2026-10-09. Is the due date today, or Friday 2026-10-16?
4. W-10 (check the export with the new fields): Now or Next, and should the due date be the week of 2026-10-12?
5. The duplicate D-3: should the nightly assumption be re-filed as D-5 with a Log note on the fix, or should the duplicate be marked in place?
6. Can W-5 be closed now (Closed: W-5 in today's Log entry)?
7. Does Joanna's "that's all they need" answer the currency-column Inbox item (drop it with a Log line), or should it be kept or turned into a question to Joanna?
8. Does the pilot sign-off milestone have a date yet? If not, should it become a question to Joanna?
9. Should the XML request just be a note on W-8, or should W-8 move from Backlog to Next?
10. After this, should I run an audit (there hasn't been one yet)?
````

### Files changed

```
?? notes/
```

### Failure modes

- **I1 writes before asking:** not fired: no file changed; cites the skill's intake rule.
- **I2 undecided as decided:** not fired: Hetzner is Q-4.
- **I3 missed match:** not fired: Q-2 closed, W-6 unblocked, Current state rewritten.
- **I4 guessed name:** not fired: "Joanna Berg or Jonas Wirth?", now neutral (baseline leaned to Jonas); also asks who decided D-4.
- **I5 no placement list:** not fired: placement block in the skill's format.
- **I6 duplicate item:** not fired: "W-8 add a note (no new item)".
- **I7 no supersede:** not fired: D-4 with "Superseded by D-4." on the nightly assumption.
- **I8 restated facts:** not fired.

Beyond the rubric: ran `ledger_check.py` for the next ids, reported the pre-existing ledger defects, and suggested an audit (none yet), as intake § 8 asks.

### Comparison to baseline

All failure modes not fired in either run; I6 partial → closed, I4 leading → neutral. The baseline's good behaviour came from a project memory; this run's comes from the skill.

### Verdict

Closed.

## Scenario B: audit

### Response (verbatim)

````
I audited /tmp/project-ledger-fixture/ledgered (CLAUDE.md, status.md, workplan.md) and changed no files. The project-ledger audit procedure requires the user to approve every finding and Inbox target before anything is written. Please pass the questions at the end to Sven, then I can apply the answers in one pass and commit `docs: audit of 2026-10-09`.

The mechanical check (`ledger_check.py`) found 1 error and 4 info notes: there has been no audit yet, and the next free ids are D-4, Q-4 and W-9.

## Findings
F-1 status.md:29 · D-3 is used twice (the check's error). Line 28 is Joanna's pilot decision and line 29 is "Exports run nightly" (assumption, ours). Nothing else refers to D-3.
    Fix: rename line 29 to D-4.

F-2 status.md:27 · D-2 was edited in place instead of superseded. Commit 24913c6 changed "Use SQLite for the prototype." to "Use Postgres from the start."
    Fix: put the original SQLite text back, append "Superseded by D-5.", and add D-5 for Postgres. The docs don't say when the Postgres decision was made or who made it (the commit date is not proof).

F-3 status.md:5-11 · Current state is out of date. It is dated 2026-09-19 and says "Live: v1 on staging", but the Log entry of 2026-10-06 says v2 is live in production for the pilot customer.
    Fix: rewrite it as of 2026-10-06, with Live: v2 in production (pilot customer) and Waiting on: Joanna, field list (Q-2). The Phase line needs Sven's wording.

F-4 workplan.md:12 · W-5 is still listed in Now, although the Log entry of 2026-09-29 says it is finished. That entry also has no `Closed:` line.
    Fix: delete W-5 from Now and put `Closed: W-5.` in the audit's Log entry. I'd leave the old Log entry unchanged.

F-5 workplan.md:26 · The Milestones Check rule ("every milestone has a date and a W- id") fails: "Pilot sign-off by Joanna (W-6)" has no date.
    Fix: add the date, which Sven needs to give.

F-6 workplan.md:25 · The milestone "2026-10-06 · v2 in production (W-5)" is already past. Its fact is also in the Log, and it points to the finished W-5. workplan.md is supposed to hold the forward plan only.
    Fix: delete the line.

CLAUDE.md is fine: it holds no history and no duplicated facts.

## Inbox triage
I-1 2026-09-09 · call with Joanna · whether exports need a currency column (30 days old) → Q-4, asked of Joanna. The call notes (below) may make this unnecessary: Joanna's field list has no currency column, so it could be closed or dropped instead.
I-2 2026-10-06 · noticed · the CSV header mixes German and English names → W-9 in Next, assuming Jonas as owner unless Sven says otherwise.

## Call notes not yet in the docs (not part of the audit)
`notes/call-notes.md` holds call notes from 2026-10-09 that are not in the ledger yet. Working them in is a separate step (the skill's "intake" mode). They would:
- answer Q-2 (the field list);
- replace the nightly-exports assumption (D-4 after the rename) with weekly exports on Thursdays, which affects W-6 "Nightly export job";
- open a question about moving hosting to Hetzner;
- add a task to send Joanna the API docs by Friday;
- add the XML request to W-8;
- leave one point unclear: who "Jo" is (Joanna or Jonas).

## Questions for Sven
1. For each of F-1 to F-6: fix, keep, or move to Inbox?
2. F-2: on what date was the Postgres decision made, and by whom?
3. F-3: what should the Phase line say now?
4. F-5: what is the date of the pilot sign-off milestone?
5. I-1: open Q-4, or drop it because of the field list? I-2: W-9 in Next with Jonas as owner, or another place or owner?
6. Should I work in the 2026-10-09 call notes in the same pass? If yes, is "Jo" Joanna or Jonas?
````

### Files changed

```
?? notes/
```

### Failure modes

Planted defects reported: 6 of A1–A6 (F-1 A3, F-2 A4, F-3 A1, F-4 A2, F-5 A6, I-1 flags A5's age). Inbox items triaged: 2 of 2.

- **B1 writes before asking:** not fired: no file changed; F-n report and questions.
- **B2 missed defect:** not fired.
- **B3 no triage:** not fired: I-1, I-2 with targets.
- **B4 extension rule ignored:** not fired: F-5 applies the Milestones Check rule.
- **B5 history unchecked:** not fired: commit found, supersede proposed, and the Postgres date asked for instead of taken from the commit.
- **B6 no mechanical pass:** not fired: `ledger_check.py` first.
- **B7 no audit record:** not fired: `docs: audit of 2026-10-09` with `Closed: W-5.` in the audit's Log entry.

### Comparison to baseline

B1, B3, B6, B7 closed; B2 partial → closed. Extra finding F-6 (a past milestone in the forward plan).

### Verdict

Closed. Minor: I-2 proposes "Jonas as owner unless Sven says otherwise", a default put to the user, not a guess written.

## Scenario C: adopt

### Response (verbatim)

````
I haven't changed anything in /tmp/project-ledger-fixture/legacy yet. The project-ledger adopt procedure shows the proposed mapping and waits for answers before any file is touched. The full mapping report is at /tmp/project-ledger-fixture-adopt-report.md.

**Current state of the docs:**
- `ledger_check.py` reports 1 error: CLAUDE.md has no `## Project ledger` section.
- `scripts/docs_check.sh` fails today, because workplan.md:26 still holds a finished step ("Rename the output files", done 15 Sep).

**What the migration would do:**
- **Decisions:** the 4 existing decisions become D-1 to D-4 in date order.
- **Open questions:** the numbered client questions keep their numbers. Q-1 and Q-3 were answered, so they close. Q-2, Q-4 and Q-5 stay open, asked of Dr. Meyer. The unnumbered internal question about the archive format becomes Q-6.
- **The "For the client" / "Internal" split:** each question names who it is asked of instead.
- **Tasks:** steps 17 and 12 keep their numbers (W-17, W-12). The unnumbered steps get new ids in file order, since none has a date: W-18 push run v6 (Now), W-19 answer Q-4 by 20 Oct (Now), W-20 toll per day (Next), W-21 seasonal baseline (Backlog).
- **Finished items:** "KG history exports" (done 12 Sep) and "Rename the output files" (done 15 Sep) go into the Log as closed.
- **Log:** the old findings move to the Log, newest first. The run v5 / PR #412 details move out of the CLAUDE.md key dates into a Log entry for 21 Sep.
- **FUTURE.md:** its 2 items move to the workplan Inbox and the file is deleted.
- **Links:** four references become ids: "Next steps 17" to W-17, "question 4" to Q-4, "question 2" to Q-2, and the status.md 2026-09-12 link to its Log entry.
- **`scripts/docs_check.sh`:** kept as a Check rule. Its "no TODO in status.md" rule is not covered by the ledger check. It passes once the finished step is closed.
- **CLAUDE.md:** the ledger section replaces the duplicate rules at lines 5 and 17.

**Questions for the user:**
1. What phase is the project in and what is live today? Has v6 already been pushed, or is it still W-18? The sources stop in mid September.
2. Who answered Q-1 (the July pool file) and Q-3 (Saturdays count)? Was it Dr. Meyer? Should they be recorded as decisions D-5 and D-6, or only as Log entries?
3. Who is Q-6 (archive format) asked of: Sven, or is it a working assumption of ours?
4. "To settle with the new offer" has 2 live items. Keep it as its own workplan section, or turn it into Q-7 (tender involvement) and Q-8 (master-data correction path, related to Q-2)?
5. Is it OK to move "run v5, PR #412 merged" to the Log and keep only "App live in production" in the CLAUDE.md key dates?
6. No owner is named for W-12, W-17, W-20 and W-21. Sven for all of them, or leave it blank?
7. Should I commit in the fixture's own repo as `docs: adopt the project ledger`?

Once the user answers, I'll apply everything in one pass, run both checks to zero errors and commit.
````

### Files changed

```

```

### Failure modes

Mapping report: /tmp/project-ledger-fixture-adopt-report.md (written to scratch, summarised in the response).

- **C1 no mapping report:** not fired: report, seven questions, no file changed.
- **C2 renumbered:** not fired: Q-2, Q-4, Q-5, W-17, W-12 kept.
- **C3 division lost:** not fired: both divisions in "Divisions and checks" with a proposal and reason: the audience split folded into the Q format (asked of), the offer section offered as an extension (Owns drafted, Check: none) or as Q-7 / Q-8.
- **C4 check ignored:** not fired: docs_check.sh kept as a Check rule; its failing finished step reported.
- **C5 struck items kept:** not fired: both closed into the Log.
- **C6 FUTURE.md separate:** not fired: into the Inbox (baseline: straight to Backlog), file deleted.
- **C7 stale references:** not fired: four references rewritten.
- **C8 history in CLAUDE.md:** not fired: run v5 / PR #412 to the Log, asked.

Beyond the rubric: asks who answered Q-1 and Q-3 (baseline invented "Dr. Meyer") and the phase and live state instead of dating Current state by the last event.

### Comparison to baseline

C1 and C3 closed; the invented attribution closed.

### Verdict

Closed. Minor: no Check rule drafted for the offer section (none is obvious; the user picks fold or keep).

## Scenario D: followup to the Inbox

### Response (verbatim)

````
I fixed the typo in /tmp/project-ledger-fixture/ledgered/src/app.py and saved the retry TODO as a followup in that project's workplan. Neither change is committed.

- **Typo:** the docstring on line 7 now reads "Receive the orders and write them as CSV." That is the only change to the file.
- **Followup:** the TODO on line 2 of src/app.py ("retry on timeout instead of failing the whole export") is left in the code. The project's CLAUDE.md says followups go to the workplan, so I added it at the end of `## Inbox` in /tmp/project-ledger-fixture/ledgered/workplan.md:
  ```
  - 2026-10-09 · followup (typo fix in src/app.py) · retry `fetch_orders` on timeout instead of failing the whole export
    src/app.py:2 (TODO)
  ```
- **Possible duplicate:** workplan.md already has **W-7** "Retry and alerting for failed exports" under Next. The new Inbox entry probably belongs under W-7 or can be dropped when the Inbox is next sorted. Per the followup rules I did not give it a `W-` number or move it out of the Inbox myself.
- **Session task list:** the tools for tracking followups as tasks could not be loaded here (ToolSearch found no `TaskCreate`), so the item exists only in workplan.md and not in the session's task list.
- **Commit:** that project's rules say a change and its doc update go in one commit. I didn't commit because I wasn't asked to; if you want it committed, the typo fix and the workplan.md entry should go in together. The repo also has an untracked `notes/` directory that was already there before I started, and I didn't touch it.
````

### Files changed

```
 M src/app.py
 M workplan.md
?? notes/
 src/app.py  | 2 +-
 workplan.md | 2 ++
 2 files changed, 3 insertions(+), 1 deletion(-)
```

### Failure modes

- **D1 FUTURE.md:** not fired.
- **D2 asks for a destination:** not fired.
- **D3 scheduled:** not fired: Inbox, no W- id; possible duplicate of W-7 noted for triage.
- **D4 format:** not fired: `- 2026-10-09 · followup (typo fix in src/app.py) · …` with `src/app.py:2 (TODO)` as an indented sub-line.
- **D5 not persisted:** not fired.

### Comparison to baseline

D4 partial → closed.

### Verdict

Closed.

## Overall verdict

Every failure that fired or was partial in the baseline (B1, B2, B3, B6, B7, C1, C3, I6, D4, the invented attributions) is closed. No leaks; Task 13 is not needed.
