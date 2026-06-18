---
name: project-catchup
description: Use when a developer returns to a git project after time away and wants a brief, impact-aware summary of what changed plus what they must do locally before resuming. Triggers on "catch me up on this project", "what changed since <commit|date|tag>", "what's new on main", "bring me up to speed", "what did I miss", "I've been away from this repo". Optional args: a target branch and/or a past node (commit, tag, or date). Requires a git repo. NOT a code-review/merge-readiness tool — that's feature-review.
---

# project-catchup

## Overview

Catch a returning developer up on a git project: orient on the project's own docs, resolve a base ("from when") and a target branch ("about what"), read the actual diffs, systematically scan for action-required items (migrations, deps, env, config, breaking), flag what collides with the developer's own local work, and render an action-first brief.

## Core principle (load-bearing)

**1. Get the axis right, with fresh data.** A returning-developer catchup is *your local checkout vs the **fetched** integration branch* — almost always `origin/main` (or `staging`/`dev`). Run `git fetch` first and compare against `origin/<target>`. Your own feature branch and your uncommitted edits are **collision context** (Phase 4), never the changeset. (Baseline failure this closes: skipping the fetch, concluding "nothing changed on main," and reporting your own branch work as the news.)

**2. Read the diffs, then synthesise impact and action.** Never summarise commit messages alone — they omit and mislabel (a migration can hide behind "chore: misc tidy-ups"). Never report a catchup without a systematic action-required scan — a missed migration or env var blocks the first `pnpm dev`.

## Procedure

Seven phases (0–6). Phases 0–5 are mandatory; Phase 6 is optional and user-triggered.

### Phase 0 — Orient on project context (before anything else)

Before resolving endpoints, asking, or reading git history, read the project's own docs: root `README`, `CLAUDE.md` (and `AGENTS.md` / `CONTRIBUTING` if present). Enter Phase 1 already knowing the stack, package manager, branch model, and setup/migrate/run commands. This often settles the primary-branch question without asking, and is the **first and authoritative** source for fix-command inference in Phase 3. Absent/thin docs → note it and proceed. This does not replace reading the diff (Phase 2).

### Phase 1 — Resolve the two endpoints

**Target branch** (what the catchup is about):
- Explicit branch arg wins.
- Else infer the primary integration branch:
  `git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null` (yields `origin/<branch>` — strip the `origin/` prefix to get `<target>`) →
  else first existing of: `for b in main master develop staging dev; do git show-ref --verify --quiet "refs/remotes/origin/$b" && echo "$b" && break; done` →
  else, if multiple long-lived candidates and no `origin/HEAD`, **ask the user once**, naming the candidates.
- **Do not default the target to the currently checked-out feature branch.** The catchup is about the integration line, not the branch you happen to be sitting on.
- `git fetch --quiet` (skip with a noted caveat if offline / no remote), then compare against `origin/<target>`.
- Report local-behind: `git rev-list --count <target>..origin/<target>`.

**Base** (what to catch up from):
- Explicit commit / tag wins. A date resolves to a commit: `git rev-list -1 --before="<date>" origin/<target>`. If that is empty (the date predates all commits), don't diff against an empty base — warn and fall back to the merge-base / infer-and-confirm path.
- Else **infer and confirm** — present candidates, let the user pick/override:
  - your last commit: `git log -1 --format='%h %ad %s' --author="$(git config user.email)" origin/<target>` — if empty, fall back to the same command with `--all` (your last commit may be on a feature branch; check the target first, because a commit found via `--all` on a divergent branch will fail the ancestry guard below)
  - merge-base: `git merge-base HEAD origin/<target>`
  - last pull: `git rev-parse --verify ORIG_HEAD 2>/dev/null`
  - last local commit on target: `git rev-parse <target>`
- **History-rewrite / off-axis guard:** `git merge-base --is-ancestor <base> origin/<target>` (exit 0 = ancestor; non-zero = not). If non-zero, the base isn't an ancestor — force-push/rebase on the integration branch, or (if the base came from the `--all` fallback) a commit only reachable from a non-target branch. Warn and fall back (the merge-base, or a date-based base) rather than emitting a wrong `base..target` diff.

### Phase 2 — Gather the change set

- `git log --no-merges <base>..origin/<target> --format='%h %an %ad %s' --date=short` — commits/authors/volume.
- `git diff --stat <base>..origin/<target>` and `git diff --name-status <base>..origin/<target>` — scope and add/modify/delete/rename status.
- `git diff <base>..origin/<target> -- <high-signal paths>` — read the **actual content** of the changes. The diff is the source of truth; commit subjects are corroboration only.
- Optional enrichment **only if the tooling exists** (degrade silently if not): `gh pr list --state merged --search "merged:>=<date>"`; Linear/issue refs parsed from commit/PR text. Context only — never a substitute for the diff.

### Phase 3 — Classify action-required items

Scan `--name-status`. Every category covers **add + remove + rename** — a removed dep or renamed env key breaks local dev as hard as a new one. Infer fix commands **CLAUDE.md first**, then `package.json` scripts / `Makefile` / framework default; if none is reliable, say "unknown" — do **not** fabricate.

- 🗃 **Migrations** — paths under `migrations/`, `prisma/migrations/`, `alembic/`, `db/migrate/`, `**/migrations/` → migrate command.
- 📦 **Dependencies** — `package.json` + lockfiles, `requirements.txt`/`poetry.lock`/`Pipfile`, `go.mod`, `Cargo.toml`, `Gemfile`, `composer.json` → install command; name what was added/removed/bumped.
- 🔑 **Env** — `.env.example`/`.sample`/`.template` or config-schema diffs → list new / renamed / removed keys explicitly.
- ⚙️ **Config / infra** — `docker-compose`, `Dockerfile`, CI config, build config, `tsconfig` that affect local run.
- 💥 **Breaking** — removed/renamed exports, API/schema contract changes → heads-up.

**High-signal shortcut:** also diff `CHANGELOG`, `README`, and setup docs — maintainers often spell out the exact steps there. A boost to recall, not a substitute for the path scan (docs may be partial — e.g. mention the migration but not a new env var).

### Phase 4 — Local-collision analysis

Convert "what changed" into "what changed that affects *you*". This is also where your own divergence belongs — it is collision context, not the changeset:

- **Uncommitted overlaps:** files in `git status --porcelain` that also appear in the `<base>..origin/<target>` name-status → likely conflict on pull/rebase.
- **Branch-dependency hits:** if on a feature branch, files it touched (`git diff --name-only <base>..HEAD`; for a branch that diverged before `<base>`, use `git diff --name-only $(git merge-base HEAD origin/<target>)..HEAD`) that the target also changed/renamed/moved → rebase won't be mechanical.
- Report the local-behind count here as context. Omit the whole section if the tree is clean and sitting on the up-to-date target.

### Phase 5 — Synthesise & render

Group the diff into a few feature/area buckets, each with a **one-line impact** drawn from the diff (how behaviour changes), not a restated commit subject. Render action-first:

```
## Catchup: <target> since <base> (<N> commits, <timespan>)
TL;DR — <one-line theme>

⚠️ BEFORE YOU RESUME            ← Phase 3 items, with inferred commands
 🗃 …  📦 …  🔑 …  ⚙️ …

⚠️ AFFECTS YOUR WORK            ← Phase 4 (omit if empty)
 • …

### What changed                ← grouped by area, one-line impact each
 • <Area> — <impact>

### Heads-up / risky             ← breaking changes, large churn, reverts
 • …
```

Keep it **brief** — summarise by area, don't enumerate every file. The "before you resume" block leads; nothing buries it. Label inferred commands as inferred and sourced (CLAUDE.md / package.json / Makefile); state unknowns as unknown. End with the **apply / expand affordance**: offer to run the action steps and to expand any section on request.

### Phase 6 — Apply / expand (optional, user-triggered)

Only on explicit request. **Expand:** drill into any area/file with the detail held back. **Apply:** run the inferred action commands — mutating actions (migrations, installs, pulls) are **always confirmed first**, run one at a time, with each result reported rather than assumed.

## Rationalizations — these are violations, not exceptions

Ordered by what actually fired in the baseline (no-skill) run. F-codes reference `tests/project-catchup-baseline-observations.md`.

| Rationalization | Reality |
|---|---|
| "The recent work is on my feature branch / these uncommitted edits — I'll report those as what changed." | **(F11)** The catchup axis is *your local checkout vs the fetched integration branch*. Your own branch and uncommitted edits are collision context (Phase 4), never the changeset. The baseline inverted this — it reported the developer's own `feat/reporting` work as "what changed while you were gone." |
| "I'll diff against `origin/main` from local refs — no need to fetch." | **(F4)** Without `git fetch`, `origin/main` is stale and you'll conclude "nothing changed." Fetch first; compare against the freshly-fetched `origin/<target>`. This was the baseline's root failure — it cascaded into missing every real change. |
| "Catch up on the branch I'm sitting on / compare main to my feature branch." | **(F9)** Wrong axis. Resolve target = the primary integration branch (origin/main), not the current feature branch, and diff local↔that. Don't reach for `--since` heuristics in place of the branch comparison. |
| "The commit messages tell me what changed — I'll summarise those." | **(F1 — preventive; not directly exercised on the baseline, which never reached the correct diff range)** Commit messages omit and misstate (a migration hid behind "chore: misc tidy-ups"). Read the diff; it is the source of truth. |
| "I covered the big features — close enough." | **(F2)** A missed migration / env var blocks the first run. The Phase 3 scan is systematic and mandatory, not best-effort. The baseline surfaced 0 of 5 action items. |
| "Only additions matter." | **(F3)** A removed dependency or a renamed/deleted env key breaks local dev too. Add / remove / rename are all first-class. The baseline said "no new dependencies" while `moment` was removed and `stripe` added. |
| "I noticed the uncommitted edits and the feature-branch work — I'll fold those into what changed." | **(F7)** Local divergence is collision context, surfaced in Phase 4's own "Affects your work" section — distinct from "what landed on `origin/<target>`." The baseline produced no genuine collision analysis because it never fetched the incoming changes to compare local state against. |
| "The base is whatever I picked — just diff it." | **(F9 — base-ancestry aspect)** If the base isn't an ancestor of the target (it may live on your divergent branch, or history was rewritten), the diff is wrong. Verify ancestry; warn and fall back. |
| "I don't know the migrate command, so I'll guess `npm run migrate`." | **(F5 — preventive; did not fire on the sonnet baseline, which read CLAUDE.md)** Infer from CLAUDE.md / package.json / Makefile. If unknown, say unknown — never fabricate a command. |
| "I'll skim the git log first and read the docs later if needed." | **(F8 — preventive; the baseline read docs but git-first)** Orient on README + CLAUDE.md *before* git (Phase 0). It settles the branch question and grounds command inference. |
| "Here's everything that changed." (flat dump) | **(F6 — preventive)** Brief, grouped, impact-aware. Summarise by area; the report is not a re-rendered `git log`. |
| "I'll run the migrations to save a step." | **(F10 — preventive)** Mutating actions are Phase 6, confirmation-gated, one at a time. Never auto-apply. |

## Red flags — stop and re-read this skill

- About to report what changed without having run `git fetch`.
- About to treat the current feature branch (or your uncommitted edits) as the catchup changeset instead of as collision context.
- About to resolve endpoints, ask, or read git history without having read README + CLAUDE.md first (Phase 0).
- About to report a catchup without having run `git diff` (commit messages only).
- About to present the summary without a systematic action-required scan.
- About to emit a `base..target` diff without confirming the base is an ancestor of the target.
- About to fabricate a fix command instead of inferring it or marking it unknown.
- About to run a migration or install without explicit user confirmation.

## Reference

REQUIRED BACKGROUND for editing this skill: `superpowers:writing-skills` (TDD-for-skills, rationalization closure).

Pressure scenario: `tests/project-catchup-baseline-pressure-scenario.md` (fixture: `tests/project-catchup-fixture.sh`). Failure modes it must close: `tests/project-catchup-baseline-observations.md`. Design rationale: `docs/specs/2026-06-19-project-catchup-design.md`.
