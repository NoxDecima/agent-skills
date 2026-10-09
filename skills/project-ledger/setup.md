# setup

For a project with no `## Project ledger` section in CLAUDE.md and no documentation beyond a README.

## 1. Detect

```bash
git ls-files '*.md' | head -50
```

If the project has status-, progress- or roadmap-type files, `TODO.md`, `FUTURE.md`, or `docs/*.md` with plans, decisions or open questions, stop and suggest adopt (`adopt.md`) instead. A release `CHANGELOG.md` does not count.

## 2. Ask one numbered round, then stop

1. Client engagement or internal project?
2. Which extensions (none is a fine answer for a small internal project)? Offer the table in § 4.
3. `status.md` and `workplan.md` at the root, or other paths?
4. Current state: the phase, what is live, what waits on whom.

## 3. Write (after the answers)

- `status.md` and `workplan.md` from `templates/` in this skill's base directory: `{{DATE}}` is today; `{{PHASE}}`, `{{LIVE}}`, `{{WAITING}}` come from answer 4, and a line without an answer is deleted.
- The ledger section from `templates/claude-section.md`, appended to CLAUDE.md. Without a CLAUDE.md, create one holding only a `# <project name>` line and that section. If answer 3 moved a file, change its Owns rows and the "Read status.md" line to the new path.
- Each chosen extension (§ 4): its heading after the core sections (or its file), its Owns row, its Check rule, its trigger row.

## 4. Extensions offered

| Extension | Heading / file | Owns row | Check | Trigger row |
|---|---|---|---|---|
| Risks | status.md `## Risks` | Risks: likelihood, impact, mitigation | Every risk names a mitigation or an owner | A risk appears or changes → Risks |
| Milestones | workplan.md `## Milestones` | Dated milestones | Every milestone has a date and a W- id | |
| Meetings | `meetings.md` | One `## YYYY-MM-DD – <meeting>` section per meeting | Every meeting section has a Log entry that links it | A meeting happens → meetings.md section; Log entry links it |
| External docs | `docs/external/` | Client-facing documents; may restate internal facts | Flag a document whose sources changed after it (`git log -1` dates) | A fact they restate changes → flag for refresh |
| Question split | `### For the client` and `### Internal` under Open questions | One row each: Q-n asked of the client / internal Q-n | | |
| Contract brief | CLAUDE.md `## Contract in brief` | Scope, price, acceptance criteria | Changes only with a signed offer or amendment | A contract fact changes → Contract in brief |

## 5. Check and commit

```bash
python <skill base directory>/ledger_check.py --root <project root>
```

Zero errors, then commit: `docs: project ledger set up`. Report the files written and the Current state.
