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
