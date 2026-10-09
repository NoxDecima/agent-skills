#!/usr/bin/env bash
# Deterministic fixtures for the project-ledger pressure scenarios.
# Re-runnable: wipes $ROOT first. Usage: tests/project-ledger-fixture.sh [ROOT]
#
# Result:
#   $ROOT/ledgered  a project WITH a ledger and planted defects (audit, intake,
#                   followup scenarios); notes/call-notes.md is the intake input
#   $ROOT/legacy    a von-Saldern-shaped project WITHOUT a ledger (adopt scenario)
set -euo pipefail

ROOT="${1:-/tmp/project-ledger-fixture}"
TODAY=$(date +%F)
D3=$(date -d '-3 days' +%F)
D10=$(date -d '-10 days' +%F)
D20=$(date -d '-20 days' +%F)
D30=$(date -d '-30 days' +%F)
D40=$(date -d '-40 days' +%F)

rm -rf "$ROOT"
mkdir -p "$ROOT/ledgered/src" "$ROOT/ledgered/notes" "$ROOT/legacy/scripts"

gitinit() {
  git -C "$1" init -q -b main
  git -C "$1" config user.name "Fixture"
  git -C "$1" config user.email "fixture@example.com"
}

# ---------------------------------------------------------------- ledgered ---
L="$ROOT/ledgered"
gitinit "$L"

cat > "$L/CLAUDE.md" <<'EOF'
# Orbit – order export service

Internal tool that exports customer orders to the accounting system.

People: Joanna Berg (client PM, accounting side), Jonas Wirth (our developer), Sven (lead).

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
| workplan.md § Milestones | Dated milestones | Every milestone has a date and a W- id |

| When this happens | Update |
|---|---|
| Something is learned, shipped or happens | Log entry; Current state if its facts change |
| A decision is made | New D-n; mark any decision it supersedes |
| A question opens / is answered | New Q-n / delete it, answer as D-n or Log entry citing it, `Closed:` line |
| Something is noticed for later | Inbox |
| A W-n is finished or dropped | Delete it; Log entry with `Closed:` line (dropped: with the reason) |
| A stable fact changes (scope, people, rules, layout) | CLAUDE.md |
EOF

cat > "$L/status.md" <<EOF
# Status

Where the project stands and what happened. Context in [CLAUDE.md](CLAUDE.md), the forward plan in [workplan.md](workplan.md).

## Current state

As of $D20.

- Phase: building the export, first customer pilot
- Live: v1 on staging
- Waiting on: Joanna for the accounting field list (Q-2)

## Log

### $D3 – v2 released to production
- Export endpoint and CSV format live in production for the pilot customer.

### $D10 – Export endpoint finished
- W-5 finished: the export endpoint passes the accounting import test.

### $D20 – Pilot scope agreed
- Pilot with one customer, CSV only. Closed: Q-1.

## Decisions

- **D-1** ($D40, decision, Sven): CSV is the first export format.
- **D-2** ($D30, decision, Sven): Use SQLite for the prototype.
- **D-3** ($D20, decision, Joanna): The pilot runs with one customer.
- **D-3** ($D20, assumption, ours): Exports run nightly.

## Open questions

- **Q-2** ($D30, asked of Joanna): Which fields does the accounting import require?
- **Q-3** ($D20, internal): Do we need an audit trail per export?
EOF

cat > "$L/workplan.md" <<EOF
# Workplan

The forward plan only. A finished or dropped item is deleted; status.md § Log records it. Context in [CLAUDE.md](CLAUDE.md), state and history in [status.md](status.md).

## Inbox

- $D30 · call with Joanna · ask whether exports need a currency column
- $D3 · noticed · the CSV header uses German and English names mixed

## Now

- **W-5** Export endpoint. Owner: Jonas.
- **W-6** Nightly export job. Owner: Jonas. Waits on: Q-2.

## Next

- **W-7** Retry and alerting for failed exports.

## Backlog

- **W-8** Second export format (XML).

## Milestones

- $D3 · v2 in production (W-5)
- Pilot sign-off by Joanna (W-6)
EOF

cat > "$L/src/app.py" <<'EOF'
def fetch_orders(client):
    # TODO: retry on timeout instead of failing the whole export
    return client.get("/orders")


def export(client, writer):
    """Recieve the orders and write them as CSV."""
    for order in fetch_orders(client):
        writer.writerow(order)
EOF

git -C "$L" add -A
git -C "$L" commit -q -m "Initial ledger and export service"

# Edited decision (planted): D-2 is changed in place instead of superseded.
sed -i 's/Use SQLite for the prototype\./Use Postgres from the start./' "$L/status.md"
git -C "$L" commit -q -am "docs: storage decision"

cat > "$L/notes/call-notes.md" <<EOF
Call with Joanna, $TODAY, 30 min (Sven, Joanna; Jo joined late)

- Joanna sent the field list for the accounting import: order id, customer number, net amount, VAT rate, booking date. That's all they need.
- We agreed: exports go out weekly on Thursdays, not nightly.
- Maybe move hosting to Hetzner? Joanna wants to think about it, nothing decided.
- I send Joanna the API docs by Friday.
- Jo will check the export with the new fields next week.
- Joanna asked whether we can do XML later this year.
EOF

# ------------------------------------------------------------------ legacy ---
G="$ROOT/legacy"
gitinit "$G"

cat > "$G/CLAUDE.md" <<'EOF'
# Harbour – fleet KPI analysis

Analysis of fleet and pool KPIs for a logistics client. Client contact: Dr. Meyer.

Progress, findings and open questions live in status.md; next steps live in workplan.md. Keep the three files free of duplication: link instead of copying.

## Key dates

| Date | Event |
|---|---|
| 2 Sep | Offer signed |
| 10 Sep | Kickoff held |
| 21 Sep | App live in production, run `v5`, PR #412 merged |

## Working conventions

- When something is learned or decided, append a dated entry to status.md. When a step is planned, done or rescheduled, update workplan.md.
- Run `scripts/docs_check.sh` before committing documentation.
EOF

cat > "$G/status.md" <<'EOF'
# Status log

Dated log of findings and decisions plus the current list of open questions. Next steps in [workplan.md](workplan.md).

## Findings

### 2026-09-05 – document review
- The client's rule book defines eleven business rules; two contradict the export.

### 2026-09-10 – kickoff with Dr. Meyer
- Pools are fixed per vehicle; the pool file is the source of truth.

### 2026-09-12 – first pipeline run
- 97 % of revenue assigned to a pool. See Next steps 17 for the per-vehicle follow-up.

## Decisions and working assumptions

- 2026-09-05 (assumption, ours): work snapshot-based, one snapshot per monthly run.
- 2026-09-10 (decision, Sven): output is a hosted web app, not a report.
- 2026-09-12 (decision, Dr. Meyer): plates without a pool are subcontractors.
- 2026-09-12 (decision, Sven): rates are net of toll.

## Open questions

### For the client

1. ~~Which pool file is current?~~ answered 10 Sep: the July file.
2. Is a dated vehicle master available?
3. ~~Do Saturdays count as working days?~~ answered 12 Sep: yes.
4. Are the toll statements available for January to April?
5. Which target rate applies per company?

### Internal

- ~~Ask Dr. Meyer for the KG history exports~~ done 12 Sep.
- Decide the archive format for monthly runs.
EOF

cat > "$G/workplan.md" <<'EOF'
# Workplan

Live document with the open steps. Context in [CLAUDE.md](CLAUDE.md), findings and open questions in [status.md](status.md).

## Open

| When | Step | Owner | Notes |
|---|---|---|---|
| now | Push run `v6` to production | Sven | after the app release |
| by 20 Oct | Answer question 4 with Dr. Meyer | Sven | blocks the toll work |

## To settle with the new offer

- Whether we are still involved in the tender.
- The path by which master-data corrections reach us (question 2).

## Next steps

- **17. Per-vehicle data acquisition** (status.md 2026-09-12): classify every vehicle by data quality.
- **12. Chat skill**: revise the text, keep both copies in step.
- Toll per day instead of per month.

## Backlog

- Seasonal baseline for the trend KPI.
- ~~Rename the output files~~ done 15 Sep.
EOF

cat > "$G/FUTURE.md" <<'EOF'
# FUTURE

- [ ] Error messages name the file and row
  Surfaced during the pipeline build; deferred as polish. (2026-09-05)
- [ ] Owner-rule tie resolves to the invoicing company
  Spec says invoicing company, code takes the first in config. (2026-09-13)
EOF

cat > "$G/scripts/docs_check.sh" <<'EOF'
#!/usr/bin/env bash
# Project doc rules: no TODO in status.md, no finished steps in workplan.md.
set -u
fail=0
grep -n "TODO" status.md && { echo "status.md holds a TODO"; fail=1; }
grep -n "done [0-9]" workplan.md && { echo "workplan.md holds a finished step"; fail=1; }
exit $fail
EOF
chmod +x "$G/scripts/docs_check.sh"

git -C "$G" add -A
git -C "$G" commit -q -m "Project docs as of mid September"

echo "Fixture ready at $ROOT (ledgered, legacy)"
