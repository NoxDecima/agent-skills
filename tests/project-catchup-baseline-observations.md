# Baseline observations (no skill loaded)

**Date:** 2026-06-19
**Subagent type:** general-purpose (Claude Code Agent tool), model: sonnet
**Fixture:** /tmp/project-catchup-fixture/acme-api (built by tests/project-catchup-fixture.sh)

## Subagent's response (verbatim)

```
## What changed on main while you were gone

Nothing changed on `main` itself — the only commit there is the original baseline
(`init: acme-api baseline`). The work that happened in your absence is on the
`feat/reporting` branch, which has one commit on top of `main`:

**`feat(reporting): touch auth for reporting hook`** (2026-06-09)
- `src/auth.js` — added a `// reporting hook` comment on the `verifyToken` function.
  Cosmetic/marker change only; no logic altered.

Additionally, `.env.example` has an **unstaged local change** (not committed anywhere)
adding a new required variable:

    REPORT_BUCKET=local-dev

## What you need to do before running it again

1. **Install dependencies** — the lockfile may have drifted: `pnpm install`
2. **Copy `.env.example` to `.env`** and set `REPORT_BUCKET` …
3. **Run migrations**: `make db-migrate`

That's it. The codebase itself is minimal — one migration (`0001_init.sql`, creates a
`users` table) and a small Express app. No new dependencies were added.

### Commands run
git log --oneline --since="10 days ago" main
ls …
git log --oneline -20
git remote -v && git status
git log --oneline --all
git branch -a
git log --oneline origin/main
git log --oneline main
git show --stat f0932a0
git diff main...feat/reporting --stat
git diff main...feat/reporting
git diff HEAD .env.example
ls migrations/ && cat migrations/*.sql
# Read: package.json, CLAUDE.md, README.md, Makefile
```

## Tool-call summary

- Ran `git fetch`? **NO** — operated entirely on stale local refs. `git log origin/main`
  was run, but `origin/main` was still pinned at the base commit (6 behind), so it showed
  only the baseline.
- Ran `git diff` (not just `git log`)? **Yes, but on the wrong range** — `git diff
  main...feat/reporting` only. The 6 incoming commits were never in any diff because they
  were never fetched.
- Read CLAUDE.md / README before git? **Read them, but git-first** — doc reads appear after
  the git exploration, not as a leading orientation step.
- Inspected `git status` / local branch state? Yes (`git status`, `git branch -a`).

## Failure modes observed (F1–F10 from the scenario rubric, + emergent F11)

- **F1 (commit messages over diffs):** *not exercised* — it did diff, but only the
  `feat/reporting` branch; the real changes (incl. the migration behind "chore: misc
  tidy-ups") were never fetched, so the message-vs-diff trap never came into play. The
  skill must still mandate diff-reading once the range is correct.
- **F2 (missed an action-required item):** **FIRED — hard.** 0 of 5 surfaced. Missed the
  `0002_add_orders` migration, the stripe/moment dep change, the env add+rename, the
  breaking export rename, and the redis service — all of them.
- **F3 (additions only / missed removal+rename):** **FIRED.** Explicitly stated "No new
  dependencies were added" (stripe was added, moment removed) and never saw the
  `DB_URL`→`DATABASE_URL` rename.
- **F4 (no fetch):** **FIRED — root cause.** Never fetched; concluded "Nothing changed on
  `main`." This single omission cascaded into F2/F3/F7/F9/F11. Highest-value rule for the
  skill to close.
- **F5 (fabricated fix command):** *not fired.* It read CLAUDE.md and correctly used
  `make db-migrate` and `pnpm install`. (Preventive row in the skill — would fire on a run
  that skips orientation.)
- **F6 (flat git-log dump):** *not fired.* Output was brief, grouped, action-oriented.
- **F7 (no local-collision analysis):** **FIRED (as a consequence).** It noticed the
  uncommitted `.env.example` edit and the `feat/reporting` auth change, but framed them as
  "the changes" rather than as collisions with incoming `origin/main` work — because it
  never saw the incoming work. No genuine collision analysis.
- **F8 (skipped orientation):** *partial.* Did read README/CLAUDE.md/Makefile, but git-first
  rather than as a leading step. Command inference still landed correctly.
- **F9 (base/target mishandling):** **FIRED.** Treated the catchup as
  `main`↔`feat/reporting` with a `--since="10 days ago"` filter, instead of "local is behind
  `origin/main` — fetch and diff that." Wrong axis entirely.
- **F10 (ungated mutation):** *not fired.* Proposed commands; did not run them.
- **F11 (EMERGENT — direction confusion):** **FIRED.** Reported the developer's *own*
  branch work and uncommitted edit as "what changed while you were gone," fully inverting
  the catchup. This is the sharpest single symptom and is not on the original F1–F10 list.
  Closed by Phase 1 (target = `origin/<primary>`, fetched) + Phase 4 (separate the
  developer's local divergence from the incoming changes).

## Coverage

- Action-required items surfaced: **0 of 5** (and the 2 it listed — install/migrate — were
  inferred from CLAUDE.md/README, not from observing the actual changes).
- Local collisions surfaced **as collisions**: **0 of 2**.

## Notes for skill author

The dominant, cascading failure is **F4 (no fetch)** feeding **F9/F11 (wrong axis +
direction confusion)**: a returning-dev catchup is fundamentally "local vs the fetched
integration branch," and the baseline got the axis wrong, then reported the developer's own
work as the news. The skill's load-bearing rules, in priority order:

1. **Mandatory `git fetch`, then compare local↔`origin/<target>`** (closes F4, and the
   cascade F2/F3/F7).
2. **Resolve target = the primary integration branch (origin/main), not the current feature
   branch; the developer's own branch/uncommitted work is *collision context*, never the
   changeset** (closes F9 + the emergent F11).
3. **Systematic action-required scan over the correct diff, add+remove+rename** (closes F2/F3
   once the range is right).
4. **Local-collision analysis as a distinct section** (closes F7).

F5 (fabricated command) and F8 (skip orientation) did **not** fire on this sonnet baseline —
the model naturally read CLAUDE.md and used its commands. Keep their rationalization rows as
**preventive** (labelled as such), per the spec: a run that skips orientation, or a weaker
model, would regress on them, and the cost of the row is low.

≥3 failure modes fired (F2, F3, F4, F7, F9, F11) — the scenario exerts sufficient pressure;
no re-pressuring needed.
