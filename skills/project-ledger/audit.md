# audit

Find stale or misplaced information in a ledger project, report it, and reconcile it with the user.

## 1. Mechanical checks

```bash
python <skill base directory>/ledger_check.py --root <project root>
```

Every ERROR becomes a finding. INFO lines become findings where they point at a problem (old Inbox items, archive size, Current state, references to closed ids, "to confirm"). Note the next free ids and the days since the last audit.

## 2. Core judgement checks

Read the whole of status.md (up to the archive), workplan.md and CLAUDE.md. On a large project, one subagent per file group, each returning findings in the format of § 5. Look for:

- Current state that the newest Log entries or Now contradict.
- Finished work still in the workplan (a Log entry says it is done, a later state supersedes it).
- Decisions edited instead of superseded: `git log -p --follow <status file>` and look for changed `- **D-` lines.
- Log entries that state a decision without a `D-n`.
- Open questions the Log has answered.
- Facts held in two places; the Owns table decides the owner.
- History or progress in CLAUDE.md (dated events, run or PR details, rule histories).

## 3. Extensions

For each Owns row with a Check rule, apply the rule (run a named script). For every extension, check that it holds what its Owns row says, that nothing in it belongs to another owner, and that it duplicates no facts.

## 4. Inbox triage

Propose a target for every Inbox item: a `W-n` in Now, Next or Backlog (with the next free id), a `Q-n`, a Log entry, or drop.

## 5. Report, then stop

Write the report to the session scratch space and show it. Do not report a finding again that the previous audit's Log entry lists as kept, unless its content changed.

```markdown
## Findings
F-1 status.md:6 · Current state says "Waiting on: Alex for the budget (Q-12)"; Log 2026-03-03 closed Q-12.
    Fix: rewrite Current state (nothing waiting on Alex).
F-2 status.md:40 · D-17 defined twice (ledger_check).
    Fix: the second becomes D-25 (assumption, ours); references checked.

## Inbox triage
I-1 2026-02-10 · call with Alex · data retention period → Q-31 (ask Alex)
I-2 2026-03-01 · noticed · slow dashboard load → W-42 Backlog
```

Ask: for each finding fix, keep or Inbox; for each Inbox item the target. Stop.

## 6. Reconcile (after the answers)

Apply everything in one pass and commit `docs: audit of YYYY-MM-DD`. Add one Log entry:

```markdown
### YYYY-MM-DD – Audit: <n> findings
- Fixed <a>, kept <b>, to Inbox <c>; Inbox triaged: <d> items.
- Kept: <one line per kept finding, with file § section>.
- Closed: <ids closed by the audit>.
```

Run `ledger_check.py` again: zero errors.
