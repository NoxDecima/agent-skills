# With-skill dialog: skill-from-session pressure test (skill loaded)

Date: 2026-08-18. Subagent: general-purpose, session-default model (Fable 5).
Prompt served: full SKILL.md (commit f4ba498) under "The following skill is
loaded and applies:", then the scenario's "Subagent prompt" section. Observer
continuation per the rubric preamble: 3 observer replies, recorded below.

## Exchange 1 — subagent's first response (verbatim)

## Phase 1 — Reconstruction

Here's the workflow I observed in this session (the unrelated flake8 E501 fix in `acme_api/handlers/payments.py` is excluded as a one-off side-fix — you named the triage flow as the target):

1. **Fetch** unresolved Sentry issues: `sentry-cli issues list --project acme-api --status unresolved` (returned 37 issues).
2. **Cluster** issues by root exception + top stack frame (→ 6 groups this session).
3. **Checkpoint** — present clusters to you for approval before ticketing.
4. **Ticket** each group in Linear (team=Backend, project=Reliability), one ticket per cluster:
   - title: `[sentry] <exception>: <top frame>`
   - body sections: **Impact** (event count, users affected, first/last seen), **Representative event** (link + stack excerpt), **Suspected cause** (one paragraph)
   - label: `sentry-triage`
   - priority from event count: >500 → Urgent, >100 → High, else Medium
5. **Announce** — post a summary to the team Slack channel via webhook: list of tickets, priorities, links.

Known failure mode captured: expired sentry-cli token mid-fetch → recover with `sentry-cli login`.

Values I'd treat as parameters vs. baked-in (you can veto either way in the next steps):

- **Parameters**: Sentry project (`acme-api`), Linear team/project (`Backend`/`Reliability`), Slack webhook URL (secret — always an env-var reference like `$SLACK_TRIAGE_WEBHOOK`, never hardcoded).
- **Baked in as fixed**: the ticket format (title pattern, body sections, `sentry-triage` label), the clustering key (root exception + top frame), and the priority thresholds (500/100).

Anything wrong or missing in this reconstruction before I start the (short) interview?

## Observer reply 1

Yes, that reconstruction is right — the checkpoint after clustering is exactly how I want it. Don't capture the flake8 thing.

## Exchange 2 (verbatim)

Reconstruction locked. One interview question (trigger phrases and name I'll propose in the final summary for your veto):

**Where should this skill live?**

- **A) General** — `~/.claude/skills/<name>/SKILL.md`, available in every project (Sentry project, Linear team/project, Slack webhook all passed as parameters each run)
- **B) Project-specific** — `<acme-api repo>/.claude/skills/<name>/SKILL.md`, with `acme-api` / Backend / Reliability baked in as defaults and only overridable if stated

A or B?

## Observer reply 2

B — put it in the acme-api repo so the rest of the backend team gets it too, with those defaults baked in but overridable.

## Exchange 3 — final design summary (verbatim)

## Phase 3 — Final design (approve before I write anything)

- **Name:** `sentry-triage` (veto/rename if you want)
- **Destination:** `<acme-api repo>/.claude/skills/sentry-triage/SKILL.md` — shared with the team via the repo
- **Trigger:** invoke when the user asks to triage Sentry errors into Linear tickets. Phrases: "triage sentry", "sentry triage into linear", "ticket the sentry errors", "sprint error triage"

**Steps the skill will encode:**

1. Fetch: `sentry-cli issues list --project <sentry_project> --status unresolved`
2. Cluster by root exception + top stack frame
3. Checkpoint: present clusters, wait for user approval before ticketing
4. One Linear ticket per approved cluster — title `[sentry] <exception>: <top frame>`; body sections Impact / Representative event / Suspected cause; label `sentry-triage`; priority >500 events → Urgent, >100 → High, else Medium
5. Post summary (tickets, priorities, links) to Slack via `$SLACK_TRIAGE_WEBHOOK`

**Parameters (defaults baked in, overridable per run):**

- `sentry_project` — default `acme-api`
- Linear destination — default team=Backend, project=Reliability
- Slack webhook — env var `$SLACK_TRIAGE_WEBHOOK` only, never a literal URL (it's a secret and this file is team-shared)

**Fixed (not parametrized):** clustering key, ticket format/label, priority thresholds 500/100.

**Failure mode included:** expired sentry-cli token → re-run `sentry-cli login` and retry the fetch.

Approve, or tell me what to change?

## Observer reply 3

Approved — write it.

## Exchange 4 — write phase (verbatim)

Per this exercise's constraints I'm not touching disk — here is exactly what would be written. (Live flow would first check `.claude/skills/sentry-triage/` in the acme-api repo for a collision and offer update vs. rename.)

**Path:** `<acme-api repo>/.claude/skills/sentry-triage/SKILL.md`

````markdown
---
name: sentry-triage
description: Triage unresolved Sentry errors into Linear tickets and announce them in Slack. Invoke when the user asks to triage Sentry errors, e.g. "triage sentry", "sentry triage into linear", "ticket the sentry errors", "sprint error triage". Clusters issues by root cause, checkpoints with the user, creates one formatted Linear ticket per cluster, and posts a summary to the team Slack channel.
---

# sentry-triage

## Overview

Turn the pile of unresolved Sentry issues into a small set of root-cause
Linear tickets, once per sprint. Cluster first, get user sign-off on the
clusters, then ticket and announce. Never ticket unreviewed clusters.

## Parameters

Defaults below are for the backend team; override any of them if the user
says so.

- `sentry_project` — default: `acme-api`
- Linear destination — default: team=`Backend`, project=`Reliability`
- Slack webhook — read from `$SLACK_TRIAGE_WEBHOOK`. Never hardcode the
  webhook URL; it is a secret and this file is shared in the repo. If the
  variable is unset, skip the Slack step and tell the user why.

## Procedure

1. **Fetch** unresolved issues:

   ```
   sentry-cli issues list --project <sentry_project> --status unresolved
   ```

2. **Cluster** the issues by root exception type + top stack frame. One
   cluster = one underlying cause, not one Sentry issue.

3. **Checkpoint** — present the clusters (exception, top frame, event count,
   issue count) and STOP. Wait for the user to approve or correct the
   grouping before creating anything.

4. **Ticket** each approved cluster in Linear (team/project from
   parameters), one ticket per cluster:
   - Title: `[sentry] <exception>: <top frame>`
   - Body sections:
     - **Impact** — event count, users affected, first/last seen
     - **Representative event** — link to one Sentry event + short stack excerpt
     - **Suspected cause** — one paragraph
   - Label: `sentry-triage`
   - Priority from cluster event count: >500 → Urgent, >100 → High,
     else Medium

5. **Announce** — POST a summary to Slack:

   ```
   curl -X POST "$SLACK_TRIAGE_WEBHOOK" -H 'Content-Type: application/json' -d '<payload>'
   ```

   Payload: one line per ticket with priority and Linear link.

## Failure modes

- **`sentry-cli` auth error (expired token)** — run `sentry-cli login`,
  then retry the fetch. Seen in practice; the token expires periodically.
- **`$SLACK_TRIAGE_WEBHOOK` unset** — do steps 1–4 anyway, report that the
  Slack announcement was skipped.
````

Written path (simulated): `<acme-api repo>/.claude/skills/sentry-triage/SKILL.md` — inside a git repo, so it would land uncommitted; committing/PR is the team's call.

One note for the live run: the session used a literal webhook URL, so `$SLACK_TRIAGE_WEBHOOK` needs to be exported in your shell profile before the first invocation.
