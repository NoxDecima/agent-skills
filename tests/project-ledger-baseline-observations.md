# Baseline observations (project-ledger not installed; followup-tracking unedited)

**Date:** 2026-10-09
**Subagent type:** general-purpose (Claude Code Agent tool)
**Fixture:** /tmp/project-ledger-fixture, rebuilt before each scenario
**Controller cwd:** a von-Saldern-logistik worktree, so subagents loaded that project's CLAUDE.md and auto-memory (a confound, see A and C).

## Scenario A: intake

### Response (verbatim)

````
Nothing is written yet. Sven's standing rule for meeting notes is that I first show what I read and what I plan to record, then wait for his OK. Several points in these notes are also ambiguous. Please pass the plan and questions below to him; I'll write the entries once he answers.

Note: these notes belong to the **Orbit** project at `/tmp/project-ledger-fixture/ledgered/`, not to von Saldern. The edits would go into that project's `status.md` and `workplan.md`, following the rules in its `CLAUDE.md`.

**What I read from the call (2026-10-09, Sven and Joanna, Jo joined late)**
1. Joanna answered Q-2. The accounting import needs five fields: order id, customer number, net amount, VAT rate, booking date. Nothing else.
2. Exports run weekly on Thursdays instead of nightly. This replaces the assumption that exports run nightly.
3. Hosting on Hetzner was raised but not decided. Joanna wants to think about it.
4. Sven sends Joanna the API docs by Friday.
5. Jo checks the export with the new fields next week.
6. Joanna asked whether XML is possible later this year.

**Planned entries**
- **status.md § Log, new top entry** "2026-10-09 – Call with Joanna": the field list, weekly Thursday exports, Hetzner raised, the XML question. It ends with `Closed: Q-2`.
- **§ Decisions**
  - D-4 (2026-10-09, decision, Joanna and Sven): exports run weekly on Thursdays. It replaces the nightly-export assumption, which I would mark as superseded.
  - D-5 (2026-10-09, decision, Joanna): the import needs exactly the five fields above.
- **§ Open questions**
  - Delete Q-2.
  - New Q-4 (asked of Joanna): move hosting to Hetzner?
  - New Q-5 (asked by Joanna): can we deliver XML later this year? This would be tied to W-8.
- **§ Current state**: date it 2026-10-09 and fix what is stale:
  - "Live" becomes v2 in production for the pilot customer (it still says v1 on staging).
  - "Waiting on" drops Q-2 and lists Joanna on Hetzner (Q-4).
- **workplan.md**
  - Rename W-6 to "Weekly export job (Thursdays)" and remove "Waits on: Q-2".
  - New item: send Joanna the API docs, owner Sven, due Friday.
  - New item: check the export with the new fields, owner Jo, next week.
  - Possibly a new item to add the five fields to the export itself, if that work isn't already part of W-6.

**Questions for Sven**
1. Is "Jo" Jonas Wirth? He's the only Jo-like name in CLAUDE.md, and "Jo" could also be read as Joanna.
2. The call was on Friday 9 Oct. Does "API docs by Friday" mean today or 16 Oct?
3. Is weekly-on-Thursdays a joint decision or Joanna's? Should it also close the duplicate D-3 below?
4. Does adding the five fields need its own W-item, or does it fall under W-6? Is a currency column still needed (Inbox item from 9 Sep), now that Joanna said these five fields are all they need? If not, I'd delete that Inbox line and close it in the Log.
5. Should the XML question move W-8 out of Backlog into Next, or stay an open question for now?
6. Do the API docs and Jo's check get W-ids, or go in the Inbox?

**Existing problems in that project's ledger (separate from the call; fix along with the notes?)**
- Two decisions both carry the id **D-3**: Joanna's pilot decision and the "nightly" assumption. I'd renumber the assumption and mark it superseded by the new weekly decision.
- W-5 was finished on 29 Sep (logged), but it is still listed under § Now.
- The milestone "Pilot sign-off by Joanna (W-6)" has no date, which breaks the rule that every milestone has a date.
- § Current state is dated 2026-09-19 and predates the v2 release on 6 Oct.

That project's CLAUDE.md sends follow-ups to the workplan ("Followups: workplan"), so all follow-ups above go there.
````

### Files changed

```
?? notes/
```

### Failure modes

- **I1 writes before asking:** not fired: report and six numbered questions, no file changed. Confound: the subagent cited "Sven's standing rule for meeting notes", i.e. the von Saldern auto-memory `meeting-notes-interpret-then-confirm` loaded from the controller's cwd, not its own judgement.
- **I2 undecided as decided:** not fired: Hetzner proposed as a new Q.
- **I3 missed match:** not fired: Q-2 closed, W-6's wait removed, Waiting on updated.
- **I4 guessed name:** not fired: asked, though leading ("Is Jo Jonas Wirth?").
- **I5 no placement list:** not fired: "Planned entries" per file and section.
- **I6 duplicate item:** partial: no new W-, but a new Q-5 for XML next to W-8 instead of "already W-8".
- **I7 no supersede:** not fired: new D-4 superseding the nightly assumption; the duplicate D-3 noticed.
- **I8 restated facts:** not fired.

## Scenario B: audit

### Response (verbatim)

````
I audited the ledger in /tmp/project-ledger-fixture/ledgered (CLAUDE.md, status.md, workplan.md, the untracked notes/call-notes.md and src/app.py) and fixed what was clearly wrong. I didn't apply the 9 Oct call notes, because they contain new decisions that Sven should confirm first. My edits to status.md and workplan.md are uncommitted, so you can review them with `git diff`.

**Fixed:**
1. **Current state was stale.** It said "As of 2026-09-19 · Live: v1 on staging", but the log already records v2 going to production on 6 Oct. It now reads as of 2026-10-06, with v2 (export endpoint, CSV) in production for the pilot customer.
2. **W-5 was finished but still listed under Now.** The 29 Sep log entry says it's done, so I deleted it from Now and gave that log entry the required `Closed: W-5.` line.
3. **There were two decisions numbered D-3.** I renumbered the second one (assumption: exports run nightly) to D-4.
4. **D-2 had been edited in place.** Commit d1bd245 overwrote "Use SQLite for the prototype" with "Use Postgres from the start", which breaks the rule that a new decision gets its own number and marks the one it supersedes. I restored the SQLite D-2 as "Superseded by D-5" and added **D-5** (Postgres, Sven), which says "Supersedes D-2".
5. **A finished milestone was still in the forward plan.** I removed "2026-10-06 · v2 in production (W-5)" from Milestones; the 6 Oct log entry already records it.

**Not fixed, need Sven:**
- **D-5's date is a guess.** The real date of the Postgres decision isn't recorded anywhere, so I used 2026-10-09, the date of the commit.
- **The milestone "Pilot sign-off by Joanna (W-6)" has no date,** which breaks the CLAUDE.md check. I didn't make one up.
- **notes/call-notes.md (call with Joanna, 2026-10-09) is untracked and not applied.** Proposed ledger changes:
  - Answer Q-2 with the field list: order id, customer number, net amount, VAT rate, booking date. Close it with a `Closed: Q-2` log entry, and remove "Waiting on: Joanna" from Current state.
  - The Inbox item from 9 Sep about a currency column is answered by that list (no currency field), so it can be closed.
  - New D-6 (Joanna/Sven): exports run weekly on Thursdays, superseding D-4 (nightly). W-6 "Nightly export job" becomes a weekly job and no longer waits on Q-2.
  - New Q: should hosting move to Hetzner? Joanna is thinking about it; nothing is decided.
  - New W-n: Sven sends Joanna the API docs by Friday 2026-10-16. Another W-n: check the export with the new fields next week; the owner is the "Jo" below.
  - Joanna asked about XML later this year, which ties to W-8 in Backlog. It could get a target date or an Inbox note.
  - **Open:** who is "Jo"? Jonas or Joanna? The People line doesn't list a "Jo".
- **Things in src/app.py, left alone:** a `TODO: retry on timeout` that belongs under W-7 (retry and alerting) and could be referenced there, and a typo in a docstring ("Recieve" for "Receive").
````

### Files changed

```
 M status.md
 M workplan.md
?? notes/
 status.md   | 13 +++++++------
 workplan.md |  2 --
 2 files changed, 7 insertions(+), 8 deletions(-)
```

### Failure modes

Planted defects reported: 5 of A1–A6 (A5, the 30-day-old Inbox item, not reported as stale). Inbox items triaged: 0 of 2 (one mentioned as answerable by the call notes).

- **B1 writes before asking:** FIRED: edited status.md and workplan.md (stale Current state, W-5, D-3 renumbered to D-4, D-2 restored and D-5 added with a guessed date, a milestone deleted) before any report or answer.
- **B2 missed defect:** partial: A5 missed.
- **B3 no triage:** FIRED: Inbox untouched, no proposal per item.
- **B4 extension rule ignored:** not fired: the Milestones Check rule read and A6 reported.
- **B5 history unchecked:** not fired: found commit d1bd245 and restored D-2 (but invented the new decision's date).
- **B6 no mechanical pass:** FIRED: no systematic id or section check; defects found by reading.
- **B7 no audit record:** FIRED: no Log entry recording the audit.

## Scenario C: adopt

### Response (verbatim)

````
I moved the docs in `/tmp/project-ledger-fixture/legacy` onto a status / workplan ledger. I copied the format from the sibling `/tmp/project-ledger-fixture/ledgered`. `scripts/docs_check.sh` passes (exit 0). The changes are in the working tree only, not committed.

**`CLAUDE.md`**
- It now holds the ledger rules: an owner table (which file and section owns what), and a "when this happens, update this" table.
- New rule: ids are never reused or renumbered.
- It says `Followups: workplan`, so new followups go to the workplan Inbox.
- Both `docs_check.sh` rules (no TODO in `status.md`, no finished steps in `workplan.md`) now appear in the table's Check column. The "run `docs_check.sh` before committing" convention stays.
- The Key dates table is gone; those events are now Log entries in `status.md`.

**`status.md`**
- **Current state:** dated 2026-09-21, the last dated event in the docs.
- **Log:** newest first, with the old findings and the past key dates. Answered and finished items became entries with `Closed:` lines: Q-1, Q-3, the KG history exports and the output-file rename.
- **Decisions D-1 to D-6:** the four existing ones plus the answers to Q-1 (the July pool file is current) and Q-3 (Saturdays count as working days).
- **Open questions:** Q-2, Q-4 and Q-5 keep their old numbers. Q-6 is the archive format for monthly runs. Q-7 (are we still in the tender) and Q-8 (how master-data corrections reach us) are the two "settle with the new offer" items.

**`workplan.md`**
- **Now:** W-18 push run `v6`, and W-19 settle Q-4 by 20 Oct.
- **Next:** W-17, W-12 and W-20 (toll per day). W-17 and W-12 keep their old numbers, so old references like "Next steps 17" still point to the right item.
- **Backlog:** W-21 seasonal baseline. W-22 and W-23 are the two items from `FUTURE.md`.
- **Milestones:** 2026-10-20, Q-4 settled (W-19).
- **Inbox:** empty.

`FUTURE.md` is deleted (staged with `git rm`). Both of its items are now in the Backlog.

**Things I inferred, worth a check:**
- I listed Dr. Meyer as the one who answered Q-1 and Q-3 (D-3, D-6). The old docs only say "answered".
- "Blocks the toll work" is now W-20 waiting on W-19.
- The open questions say "2026-09-10 or earlier" because the old file had no date for when they were asked.
- W-18 waits on "the app release", copied as written. Since the app was already live on 21 Sep, it may mean a later release.

The sibling `ledgered` example has two errors of its own, which I left alone because they're outside this task:
- D-3 is used twice.
- W-5 is still under Now although the Log says it is finished.

If you want duplicate ids caught automatically, a uniqueness check in `docs_check.sh` would do it.
````

### Files changed

```
 M CLAUDE.md
D  FUTURE.md
 M status.md
 M workplan.md
 CLAUDE.md   | 32 ++++++++++++++++++++++++-------
 FUTURE.md   |  6 ------
 status.md   | 63 +++++++++++++++++++++++++++++++++++++++----------------------
 workplan.md | 32 ++++++++++++++++---------------
 4 files changed, 82 insertions(+), 51 deletions(-)
```

### Failure modes

- **C1 no mapping report:** FIRED: migrated all four files and `git rm`'d FUTURE.md without a report or a question.
- **C2 renumbered:** not fired: Q-2, Q-4, Q-5, W-17, W-12 kept.
- **C3 division lost:** FIRED: the For the client / Internal split dissolved without an extension; the "To settle with the new offer" items became plain Q-7 / Q-8 with a tag, no Owns row, no Check.
- **C4 check ignored:** not fired: both docs_check.sh rules in the Check column.
- **C5 struck items kept:** not fired: closed into Log entries.
- **C6 FUTURE.md separate:** not fired, but its items went straight to Backlog (W-22, W-23) instead of the Inbox.
- **C7 stale references:** not fired: no old references left.
- **C8 history in CLAUDE.md:** not fired: Key dates moved to the Log (without asking).

Outside the rubric: it copied the ledger format from the sibling fixture `ledgered` (fixture leak: the baseline knew the target format), and it invented an attribution ("Dr. Meyer answered Q-1 and Q-3") and a question date.

## Scenario D: followup to the Inbox

### Response (verbatim)

````
I fixed the typo and saved the retry TODO as a followup in the project's workplan. Nothing is committed.

- **Typo:** in `/tmp/project-ledger-fixture/ledgered/src/app.py`, the docstring of `export` now reads "Receive the orders and write them as CSV."
- **Retry TODO:** the code is unchanged. The project's CLAUDE.md says `Followups: workplan`, and its ledger table says items noticed for later go in workplan.md § Inbox. So I added this line to the Inbox in `/tmp/project-ledger-fixture/ledgered/workplan.md`, in the existing "date · source · line" format:
  `- 2026-10-09 · noticed · `src/app.py` `fetch_orders`: TODO to retry on timeout instead of failing the whole export (belongs with W-7)`
  W-7 ("Retry and alerting for failed exports") is already in § Next and covers this, so whoever sorts the Inbox can fold the line into W-7.

**Not committed:** the project asks that a change and its ledger update go in the same commit. Both edits are in the working tree and can go into one commit when you want; I didn't commit because no one asked me to.

**Task list:** I couldn't load the TaskCreate tools in this subagent (ToolSearch returned no match), so the followup isn't in the session task list. It's already saved to the workplan as you asked, so no further triage is needed.

**Linear:** several claude.ai connectors, Linear among them, need authorizing in your claude.ai connector settings. This task didn't use any of them.
````

### Files changed

```
 M src/app.py
 M workplan.md
?? notes/
 src/app.py  | 2 +-
 workplan.md | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
```

### Failure modes

- **D1 FUTURE.md:** not fired.
- **D2 asks for a destination:** not fired: read `Followups: workplan` from CLAUDE.md.
- **D3 scheduled:** not fired: Inbox, no W- id.
- **D4 format:** partial: date and `·` separators, but source `noticed` instead of `followup (<context>)`, and the file reference inline instead of an indented sub-line.
- **D5 not persisted:** not fired.

## Notes for the skill author

- The sharpest failures are in the open-ended modes: audit (B1, B3, B6, B7) and adopt (C1, C3) wrote directly. "Clean up" and "move them" read as permission to write; the core principle and the rationalization "the user asked me to integrate / clean up" target exactly this.
- Intake behaved because a project memory taught it the habit; without that memory, I1 and I5 are the expected failures. The skill must carry the habit itself.
- Divisions are lost silently in adopt: the skill's adopt step must name existing splits and propose them as extensions.
- Audit has no mechanical pass: point it at `ledger_check.py` first; A5 (Inbox age) is exactly what the script reports.
- Guessed attributions and dates (C: "Dr. Meyer", B: D-5 dated by the commit) are a form of I4: ask, don't infer.
- D shows the destination resolution already works from the CLAUDE.md line; the gap is only the Inbox line format, which Task 9 documents.
- With-skill runs share the cwd confound; read their results with that in mind.
