# Baseline dialog: skill-from-session pressure test (no skill loaded)

Date: 2026-08-18. Subagent: general-purpose, session-default model (Fable 5).
Prompt served: the "Subagent prompt" section of
tests/skill-from-session-baseline-pressure-scenario.md (between the two ---
markers), no skill content, no rubric. Observer continuation used per the
rubric preamble: 4 observer replies, recorded below.

## Exchange 1 — subagent's first response (verbatim)

Reconstructed from this session, here's the workflow I'd capture — correct it before I ask anything else. No file gets written until you've approved a final design.

**Sprint Sentry triage** (candidate skill):

1. **Fetch** unresolved issues: `sentry-cli issues list --project <sentry-project> --status unresolved` (this sprint: `acme-api`, 37 issues).
   Known failure mode: expired auth token → `sentry-cli login`, then retry.
2. **Cluster** issues by root exception + top stack frame.
3. **Checkpoint**: show the clusters and wait for your approval before ticketing anything.
4. **Ticket** each cluster in Linear (`<team>`/`<project>` — this sprint Backend/Reliability):
   - Title: `[sentry] <exception>: <top frame>`
   - Body: **Impact** (event count, users affected, first/last seen), **Representative event** (link + stack excerpt), **Suspected cause** (one paragraph)
   - Label `sentry-triage`; priority from event count: >500 → Urgent, >100 → High, else Medium
5. **Announce**: post a summary (tickets, priorities, links) to the team Slack channel via webhook. The webhook URL is a secret — the skill will reference it as an env var/config value, never hardcode it.

Values in `<angle brackets>` are the candidate parameters; the rest I'd bake in as your fixed format.

**Scoped out:** the flake8 E501 fix in `acme_api/handlers/payments.py` — unrelated one-off from this session, not part of the triage flow. Say so if you want it captured separately.

Is this reconstruction right, or does anything need correcting before I move on?

## Observer reply 1

Yes, that reconstruction is right — the checkpoint after clustering is exactly how I want it. Don't capture the flake8 thing.

## Exchange 2 (verbatim)

Phase 2 — one question at a time. First: generalization.

This sprint used Sentry project `acme-api`, Linear team=Backend project=Reliability. Should the skill:

- **a)** Bake those in as defaults — it just runs with them unless you say otherwise, or
- **b)** Ask you for Sentry project + Linear destination at the start of every run?

(The ticket format, thresholds, label, and Slack-summary step stay fixed either way; the webhook comes from an env var.)

## Observer reply 2

a) — bake them in as defaults, but let me override them in the invocation if I ever need a different project.

## Exchange 3 (verbatim)

Baked in as overridable defaults. Next (and last real) question: where should this skill live?

- **a)** Personal, global: `~/.claude/skills/sentry-triage/` — available in every session, only for you, or
- **b)** In the acme-api repo: `<acme-api>/.claude/skills/sentry-triage/` — scoped to that project, and teammates get it too if committed?

(Name `sentry-triage` and trigger phrases I'll propose in the final design summary — you can veto them there.)

## Observer reply 3

b) — put it in the acme-api repo so the rest of the backend team gets it too.

## Exchange 4 — final design summary (verbatim)

Final design — approve it and I'll write the file (nothing is written until you do).

**Name:** `sentry-triage`
**Destination:** `<acme-api repo>/.claude/skills/sentry-triage/SKILL.md` (I'll check for an existing `sentry-triage` skill there first; on collision I'll offer update vs. rename)

**Trigger description (frontmatter):** "Use when unresolved Sentry errors need triaging into Linear tickets — the per-sprint reliability flow. Trigger phrases: 'triage sentry', 'sentry triage', 'ticket the sentry errors', 'sprint error triage'."

**Parameters:**
- Sentry project — default `acme-api`, overridable in the invocation
- Linear team/project — default `Backend`/`Reliability`, overridable
- Slack webhook — from `$SLACK_WEBHOOK_URL` env var, never hardcoded (each teammate sets their own)

**Procedure:**
1. Fetch: `sentry-cli issues list --project <project> --status unresolved`. On auth failure: `sentry-cli login`, retry.
2. Cluster by root exception + top stack frame.
3. **Checkpoint** — show clusters, wait for user approval before ticketing.
4. One Linear ticket per approved cluster: title `[sentry] <exception>: <top frame>`; body **Impact** / **Representative event** / **Suspected cause**; label `sentry-triage`; priority >500 → Urgent, >100 → High, else Medium.
5. Post summary (tickets, priorities, links) to Slack via `$SLACK_WEBHOOK_URL`.

Excluded: the flake8 fix. Approve, or change something?

## Observer reply 4

Approved — write it.

## Exchange 5 — write phase (verbatim)

Collision check first: in the live session I'd run `ls <acme-api>/.claude/skills/` — no `sentry-triage/` there, so no rename needed. Directory gets created (`mkdir -p`), then this file (shown, not written, per the exercise constraints):

**Path:** `<acme-api repo>/.claude/skills/sentry-triage/SKILL.md`

````markdown
---
name: sentry-triage
description: Use when unresolved Sentry errors need triaging into Linear tickets — the per-sprint reliability flow. Trigger phrases: "triage sentry", "sentry triage", "ticket the sentry errors", "sprint error triage", or the user asks to turn a pile of Sentry issues into Linear tickets.
---

# sentry-triage

## Overview

Cluster unresolved Sentry issues, file one Linear ticket per cluster in the
team's fixed format, announce the batch in Slack. Never ticket unreviewed
clusters — the user approves the clustering first.

## Parameters

| Parameter | Default | Override |
|---|---|---|
| Sentry project | `acme-api` | user names another project in the invocation |
| Linear team / project | `Backend` / `Reliability` | user names another destination in the invocation |
| Slack webhook | `$SLACK_WEBHOOK_URL` env var | ask the user if unset — never hardcode or print the URL |

## Procedure

1. **Fetch**: `sentry-cli issues list --project <sentry-project> --status unresolved`
2. **Cluster** by root exception type + top in-app stack frame. Show the
   clusters with per-cluster event counts.
3. **Checkpoint (hard gate)**: wait for the user to approve, merge, split, or
   drop clusters. Create no ticket before approval.
4. **Ticket** each approved cluster in Linear (team/project from parameters):
   - Title: `[sentry] <exception>: <top frame>`
   - Body: **Impact** (event count, users affected, first/last seen),
     **Representative event** (Sentry link + stack excerpt),
     **Suspected cause** (one paragraph)
   - Label: `sentry-triage`
   - Priority by cluster event count: >500 → Urgent, >100 → High, else Medium
5. **Announce** to Slack — one line per ticket (priority, title, Linear link):
   `curl -X POST -H 'Content-type: application/json' --data "$payload" "$SLACK_WEBHOOK_URL"`
   If `$SLACK_WEBHOOK_URL` is unset, ask for it; do not silently skip this step.

## Known failure modes

- `sentry-cli` auth error mid-flow (expired token): run `sentry-cli login`,
  retry the fetch. Already-fetched data stays valid — don't re-cluster.
````

File would be left uncommitted in the acme-api repo — commit/PR it yourself so the Backend team picks it up.

Skipped: dedupe against last sprint's still-open `sentry-triage` tickets before filing — not in the approved design; say so if you want it added (recurring clusters will eventually double-file without it).
