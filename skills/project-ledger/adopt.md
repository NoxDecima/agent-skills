# adopt

For an existing project without a `## Project ledger` section: move its documentation onto the ledger, keeping what it built for itself.

## 1. Inventory

Read CLAUDE.md, the README, status-, progress- and roadmap-type files, `TODO.md`, `FUTURE.md`, `docs/*.md`, and the project memories (`~/.claude*/projects/<project>/memory/`) that describe a documentation process. On a large project, dispatch one subagent per file group and ask each for its facts, sections and references.

Detect besides the facts:

- **Divisions**: sections or files with no core equivalent, e.g. a "Waiting for the board" section, a split of the questions by audience, task chains with their own prefixes, a `meetings.md`.
- **Checks**: check scripts (`scripts/*check*`, `*.py` or `*.sh` that read the docs), project audit skills (`.claude/skills/`), written documentation rules in CLAUDE.md ("every fact lives in one file").
- **History in CLAUDE.md**: dated progress, run or PR details, rule histories. These move to the Log.

## 2. Mapping report, then stop

Write the report to the session scratch space and show it:

```markdown
## Moves
| # | Source | Target | Id | Action |
|---|---|---|---|---|
| 1 | notes.md § Questions, question 12 | status.md § Open questions | Q-12 | move |
| 2 | notes.md § Questions, question 7 (ticked, answered 3 Mar) | Log entry 2026-03-03 | Q-7 | close |
| 3 | ROADMAP.md § Q2, "9. Billing export" | workplan.md § Next | W-9 | move |
| 4 | ROADMAP.md § Q2, "Dark mode" (unnumbered) | workplan.md § Next | W-10 | move |
| 5 | TODO.md, 4 items | workplan.md § Inbox | | move, delete TODO.md |

## Divisions and checks
| # | Found | Proposal | Reason |
|---|---|---|---|
| 6 | ROADMAP.md § Waiting for the board | keep as extension; Owns: items that need a board decision; Check: every item names the board meeting | 3 live items |
| 7 | scripts/lint_docs.py | keep; Check rule on the Log row: run `scripts/lint_docs.py` | checks link targets, which the ledger script does not |
| 8 | CLAUDE.md rule "every fact lives in one file" | fold into the core (ledger section) | duplicates the core rule |

## References to rewrite
| file:line | Old | New |
|---|---|---|
| ROADMAP.md:12 | question 12 | Q-12 |

## Questions
1. …
```

Rules for the report:

- Existing numbers become ids: `question 41` → `Q-41`, `Key Decision 13` → `D-13`, step `17.` → `W-17`. Never renumber.
- Unnumbered items get ids above the highest existing number of their prefix, in date order.
- Struck-through, ticked or "done" items are closed items: they leave the live sections, and a Log entry lists them in `Closed:`.
- Old findings become Log entries, newest first; a findings log above 40 KB gets an archive proposal.
- Every division and check gets a proposal: keep as an extension (with a drafted Owns row and a Check rule converted from the existing check), fold into the core, or drop, each with a one-line reason (in recent use, holds content, not a duplicate of the core). A project script with checks `ledger_check.py` lacks stays and is named in a Check rule.

Ask the numbered questions and stop.

## 3. Apply (after the answers)

1. In one pass: the moves, the new ids, the closures with their `Closed:` lines, the reference rewrites, the kept extensions with their Owns rows and Check rules.
2. Write the ledger section into CLAUDE.md from `templates/claude-section.md` (with `Followups: workplan`, and `Id prefixes:` if the project keeps its own), and remove what it replaces.
3. Write a fresh Current state from the answers.
4. Move `FUTURE.md` into the Inbox and delete it.
5. Run `ledger_check.py` (zero errors) and the kept project checks; commit `docs: adopt the project ledger`.
6. Propose deleting the project memories the ledger now covers; delete only on a yes.
