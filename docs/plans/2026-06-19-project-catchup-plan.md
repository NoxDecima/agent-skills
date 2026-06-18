# project-catchup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `project-catchup` personal skill per `docs/specs/2026-06-19-project-catchup-design.md` — a returning-developer catchup skill that orients on project docs, resolves a base+target, reads the actual diffs, systematically scans for action-required items, flags local collisions, and renders an action-first brief.

**Architecture:** A single new skill directory `skills/project-catchup/SKILL.md` in this repo, symlinked into `~/.claude/skills/`. Built test-first per `superpowers:writing-skills`: a deterministic git **fixture repo** is scripted (planted migration behind a misleading commit message, a removed + a renamed dependency/env key, an un-fetched remote that is ahead, and a local collision on a feature branch). A no-skill subagent runs the catchup against the fixture to record baseline failure modes; the SKILL.md is then written so each rationalization row in §8 of the spec maps to an observed failure; a with-skill rerun verifies closure; iteration loops if any leak.

**Tech Stack:** Markdown, bash/POSIX, `git` (and optionally `gh`), the Claude Code Agent tool (for subagent pressure tests). Instruction-only skill — no bundled code ships in the skill itself.

**Reference docs (the engineer must read before Task 5):**

- `superpowers:writing-skills` SKILL.md (TDD-for-skills, rationalization closure)
- `skills/followup-tracking/SKILL.md` and `skills/vault-brainstorming/SKILL.md` (the two in-repo precedents for skill shape — match them)
- `docs/specs/2026-06-19-project-catchup-design.md` (the design this plan implements)

---

## File map (created/modified in this plan)

Created:

- `skills/project-catchup/SKILL.md` — the skill
- `tests/project-catchup-fixture.sh` — deterministic fixture-repo builder
- `tests/project-catchup-baseline-pressure-scenario.md` — scenario (subagent prompt + observer rubric)
- `tests/project-catchup-baseline-observations.md` — no-skill run results
- `tests/project-catchup-with-skill-observations.md` — with-skill run results
- `~/.claude/skills/project-catchup` (symlink) — filesystem only, not in repo
- `/tmp/project-catchup-fixture/…` (throwaway fixture repo) — filesystem only, removed in Task 11

Modified:

- `README.md` — add `project-catchup` to the symlink-install block

---

### Task 1: Author the fixture-builder script

**Files:**
- Create: `tests/project-catchup-fixture.sh`

The fixture is a bare "origin" plus a user clone that is deliberately **behind** origin/main and sitting on a feature branch with an uncommitted change. It plants one of every action-required category, a removal, a rename, a misleading commit message, and two local collisions.

- [ ] **Step 1: Write the fixture script**

Path: `/home/nox/Documents/Projects/Nox/claude-config/tests/project-catchup-fixture.sh`

```bash
#!/usr/bin/env bash
# Deterministic fixture for the project-catchup pressure scenario.
# Re-runnable: wipes $ROOT first. Usage: tests/project-catchup-fixture.sh [ROOT]
#
# Result:
#   $ROOT/remote.git   bare "origin", main is 6 commits AHEAD of the user clone
#   $ROOT/acme-api     the USER's clone: on branch feat/reporting,
#                      local main behind origin/main (fetch required),
#                      with an UNCOMMITTED edit to .env.example
set -euo pipefail

ROOT="${1:-/tmp/project-catchup-fixture}"
USER_EMAIL="$(git config --global user.email 2>/dev/null || echo nox@local.test)"
rm -rf "$ROOT"; mkdir -p "$ROOT"

team_env() { export GIT_AUTHOR_NAME="Team Dev" GIT_AUTHOR_EMAIL="team@acme.test" \
                    GIT_COMMITTER_NAME="Team Dev" GIT_COMMITTER_EMAIL="team@acme.test"; }
user_env() { export GIT_AUTHOR_NAME="Nox" GIT_AUTHOR_EMAIL="$USER_EMAIL" \
                    GIT_COMMITTER_NAME="Nox" GIT_COMMITTER_EMAIL="$USER_EMAIL"; }

git init -q --bare -b main "$ROOT/remote.git"

# --- seed the base history ---
team_env
git clone -q "$ROOT/remote.git" "$ROOT/seed"; cd "$ROOT/seed"
mkdir -p migrations src
cat > package.json <<'JSON'
{
  "name": "acme-api",
  "version": "1.0.0",
  "scripts": { "dev": "node src/server.js", "test": "node --test" },
  "dependencies": { "express": "4.18.2", "moment": "2.29.4" }
}
JSON
cat > pnpm-lock.yaml <<'YAML'
lockfileVersion: '6.0'
dependencies:
  express: 4.18.2
  moment: 2.29.4
YAML
cat > migrations/0001_init.sql <<'SQL'
CREATE TABLE users (id SERIAL PRIMARY KEY, email TEXT NOT NULL);
SQL
cat > .env.example <<'ENV'
NODE_ENV=development
PORT=3000
DB_URL=postgres://localhost:5432/acme
ENV
cat > src/auth.js <<'JS'
function verifyToken(token) { return token && token.length > 0; }
module.exports = { verifyToken };
JS
cat > src/server.js <<'JS'
const { verifyToken } = require('./auth');
console.log('acme-api up', verifyToken('x'));
JS
cat > README.md <<'MD'
# acme-api

## Setup
1. `pnpm install`
2. Copy `.env.example` to `.env`
3. Start with `pnpm dev`
MD
cat > CLAUDE.md <<'MD'
# acme-api — project memory

Primary integration branch: `main`.
Package manager: pnpm — install with `pnpm install`.
Database migrations: run with `make db-migrate` (there is NO npm migrate script).
MD
cat > Makefile <<'MK'
db-migrate:
	@echo "running migrations"
MK
git add -A && git commit -q -m "init: acme-api baseline"
git push -q origin main
cd "$ROOT"; rm -rf "$ROOT/seed"

# --- USER clone: behind, on a feature branch, with an uncommitted overlap ---
git clone -q "$ROOT/remote.git" "$ROOT/acme-api"; cd "$ROOT/acme-api"
git config user.name "Nox"; git config user.email "$USER_EMAIL"
user_env
git checkout -q -b feat/reporting
printf 'function verifyToken(token) { return token && token.length > 0; } // reporting hook\nmodule.exports = { verifyToken };\n' > src/auth.js
git commit -q -am "feat(reporting): touch auth for reporting hook"
printf 'REPORT_BUCKET=local-dev\n' >> .env.example   # left UNCOMMITTED on purpose

# --- TEAM advances origin/main 6 commits ahead ---
team_env
git clone -q "$ROOT/remote.git" "$ROOT/team"; cd "$ROOT/team"
# 1. migration hidden behind a misleading message
cat > migrations/0002_add_orders.sql <<'SQL'
CREATE TABLE orders (id SERIAL PRIMARY KEY, user_id INT, amount_cents INT);
SQL
git add -A && git commit -q -m "chore: misc tidy-ups"
# 2. dependency ADD (stripe) + REMOVE (moment)
cat > package.json <<'JSON'
{
  "name": "acme-api",
  "version": "1.1.0",
  "scripts": { "dev": "node src/server.js", "test": "node --test" },
  "dependencies": { "express": "4.18.2", "stripe": "14.0.0" }
}
JSON
cat > pnpm-lock.yaml <<'YAML'
lockfileVersion: '6.0'
dependencies:
  express: 4.18.2
  stripe: 14.0.0
YAML
git add -A && git commit -q -m "feat: payments groundwork"
# 3. env: ADD STRIPE_WEBHOOK_SECRET + RENAME DB_URL -> DATABASE_URL
cat > .env.example <<'ENV'
NODE_ENV=development
PORT=3000
DATABASE_URL=postgres://localhost:5432/acme
STRIPE_WEBHOOK_SECRET=
ENV
git add -A && git commit -q -m "config: env updates for payments"
# 4. breaking: rename exported verifyToken -> verifyAccessToken
cat > src/auth.js <<'JS'
function verifyAccessToken(token) { return token && token.length > 0; }
module.exports = { verifyAccessToken };
JS
git add -A && git commit -q -m "refactor: auth naming"
# 5. docs: changelog + partial readme (mentions migrate, NOT the new env var)
cat > CHANGELOG.md <<'MD'
# Changelog
## Unreleased
- Payments groundwork (Stripe)
- Orders table migration
MD
cat > README.md <<'MD'
# acme-api

## Setup
1. `pnpm install`
2. Copy `.env.example` to `.env`
3. Run migrations: `make db-migrate`
4. Start with `pnpm dev`
MD
git add -A && git commit -q -m "docs: changelog + readme"
# 6. infra: add redis
cat > docker-compose.yml <<'YML'
services:
  redis:
    image: redis:7
    ports: ["6379:6379"]
YML
git add -A && git commit -q -m "infra: add redis service"
git push -q origin main
cd "$ROOT"; rm -rf "$ROOT/team"

echo "Fixture ready at $ROOT/acme-api"
echo "  branch feat/reporting; local main behind origin/main by 6 (fetch required)"
echo "  uncommitted edit in .env.example; user email used for 'your last commit': $USER_EMAIL"
```

- [ ] **Step 2: Make it executable and build the fixture once to verify**

```bash
chmod +x /home/nox/Documents/Projects/Nox/claude-config/tests/project-catchup-fixture.sh
/home/nox/Documents/Projects/Nox/claude-config/tests/project-catchup-fixture.sh
```

Expected: ends with `Fixture ready at /tmp/project-catchup-fixture/acme-api`.

- [ ] **Step 3: Verify the planted state**

```bash
cd /tmp/project-catchup-fixture/acme-api
git fetch -q
echo "behind by: $(git rev-list --count main..origin/main)"          # expect 6
git log --oneline -1 --author="$(git config user.email)"             # the feat/reporting commit
git diff --name-status "$(git merge-base HEAD origin/main)"..origin/main
git status --porcelain                                                # expect ' M .env.example'
```

Expected: behind by 6; name-status shows `A migrations/0002_add_orders.sql`, `M package.json`, `M .env.example`, `M src/auth.js`, `A CHANGELOG.md`, `A docker-compose.yml`, `M README.md`, `M pnpm-lock.yaml`; status shows the uncommitted `.env.example`.

- [ ] **Step 4: Commit the fixture script**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config
git add tests/project-catchup-fixture.sh
git commit -m "Add fixture builder for project-catchup pressure scenario"
```

---

### Task 2: Author the pressure scenario

**Files:**
- Create: `tests/project-catchup-baseline-pressure-scenario.md`

- [ ] **Step 1: Create the scenario file**

Path: `/home/nox/Documents/Projects/Nox/claude-config/tests/project-catchup-baseline-pressure-scenario.md`

````markdown
# Pressure scenario: project-catchup

Canonical scenario for the `project-catchup` skill. Build the fixture first
(`tests/project-catchup-fixture.sh`), then run the subagent prompt below with the
Agent tool (`general-purpose`) — once without the skill (baseline) and once with it.

The fixture lives at `/tmp/project-catchup-fixture/acme-api`. The subagent operates
there (it must `cd` in). The fixture's local `main` is 6 commits behind `origin/main`
(a `git fetch` is required to see the changes), the subagent is on branch
`feat/reporting` with an uncommitted edit to `.env.example`, and the catchup base is
left implicit (to exercise inference + confirm).

## Subagent prompt (verbatim)

> I've been away from my project for about ten days and I'm picking it back up. The
> repo is at `/tmp/project-catchup-fixture/acme-api` (cd into it). Catch me up on what
> changed on the main line while I was gone — keep it brief but make sure I understand
> the impact — and tell me exactly what I need to do locally before I can run it again.

<!-- Observer rubric below — do NOT include when serving the scenario to a subagent. -->

## Planted ground truth (what a correct catchup must surface)

Action-required:
- 🗃 migration `migrations/0002_add_orders.sql` — hidden behind commit "chore: misc tidy-ups" → run `make db-migrate` (per the fixture's CLAUDE.md, NOT `npm run migrate`)
- 📦 deps: `stripe` ADDED, `moment` REMOVED → `pnpm install`
- 🔑 env: `STRIPE_WEBHOOK_SECRET` ADDED, `DB_URL` RENAMED → `DATABASE_URL`
- ⚙️ infra: `docker-compose.yml` adds redis
- 💥 breaking: exported `verifyToken` → `verifyAccessToken` (src/auth.js)

Local collisions (Phase 4):
- uncommitted `.env.example` edit overlaps origin/main's rewrite of the same file
- `feat/reporting` modified `src/auth.js`, which origin/main renamed the export in

Context: local main is 6 behind origin/main; fetch required.

## Failure modes to observe (record fired / not fired + one-line note)

- **F1 — commit messages over diffs.** Reports from `git log` subjects; misses or mislabels the migration hidden behind "chore: misc tidy-ups".
- **F2 — missed an action-required item.** Any of migration / dep / env / infra / breaking absent from the report.
- **F3 — additions only.** Misses the `moment` removal or the `DB_URL`→`DATABASE_URL` rename.
- **F4 — no fetch.** Works from stale local refs; misses the 6 un-pulled commits entirely or reports "no changes".
- **F5 — fabricated fix command.** Says `npm run migrate` / guesses an install command instead of the CLAUDE.md-declared `make db-migrate` / `pnpm install`.
- **F6 — flat git-log dump.** Verbose, ungrouped, no per-area impact; re-renders the log instead of a brief action-first summary.
- **F7 — no local-collision analysis.** Doesn't flag the uncommitted `.env.example` overlap or the `feat/reporting`↔auth.js rename clash.
- **F8 — skipped orientation.** Dives into git without reading README/CLAUDE.md first (knowable from whether it uses the CLAUDE.md commands and primary-branch declaration).
- **F9 (secondary) — base mishandling.** Picks a nonsensical base, or emits a `base..target` diff without confirming/inferring the base sensibly.
- **F10 (secondary) — ungated mutation.** Runs migrate/install (or proposes to, as if it already had) without asking.

Also record: did it run `git fetch`? `git diff` (not just `git log`)? Did it read CLAUDE.md/README? How many of the 5 action-required items and 2 collisions did it surface?
````

- [ ] **Step 2: Commit**

```bash
git add tests/project-catchup-baseline-pressure-scenario.md
git commit -m "Add pressure scenario for project-catchup skill"
```

---

### Task 3: Run the baseline (no-skill) scenario

**Files:** none modified yet (output captured in Task 4)

**Pre-conditions:** `~/.claude/skills/project-catchup` must **not** exist and `skills/project-catchup/SKILL.md` must **not** exist. Both hold at this point.

- [ ] **Step 1: Verify pre-conditions and (re)build a clean fixture**

```bash
test ! -e ~/.claude/skills/project-catchup && echo "OK: no symlink"
test ! -f /home/nox/Documents/Projects/Nox/claude-config/skills/project-catchup/SKILL.md && echo "OK: no SKILL.md"
/home/nox/Documents/Projects/Nox/claude-config/tests/project-catchup-fixture.sh
```

Expected: both `OK:` lines, then `Fixture ready …`. (Rebuild ensures no leftover fetch/edits from Task 1's verification.)

- [ ] **Step 2: Dispatch the baseline subagent**

Use the `Agent` tool, `subagent_type: "general-purpose"`. The `prompt` is the **Subagent prompt (verbatim)** block from the scenario file — word-for-word, no observer rubric. Run in foreground (the result feeds Task 4).

- [ ] **Step 3: Save the subagent's verbatim response and its tool-call trace**

Stash the full response plus which git commands the subagent ran (fetch? diff? read CLAUDE.md?) for Task 4.

(No commit — observations file is created in Task 4.)

---

### Task 4: Document baseline observations

**Files:**
- Create: `tests/project-catchup-baseline-observations.md`

- [ ] **Step 1: Write the observations file**

Path: `/home/nox/Documents/Projects/Nox/claude-config/tests/project-catchup-baseline-observations.md`

````markdown
# Baseline observations (no skill loaded)

**Date:** <TODAY>
**Subagent type:** general-purpose (Claude Code Agent tool)
**Fixture:** /tmp/project-catchup-fixture/acme-api (built by tests/project-catchup-fixture.sh)

## Subagent's response (verbatim)

```
<paste full response>
```

## Tool-call summary

- Ran `git fetch`? <yes/no>
- Ran `git diff` (not just `git log`)? <yes/no>
- Read CLAUDE.md / README before git? <yes/no>
- Inspected `git status` / local branch state? <yes/no>

## Failure modes observed (F1–F10 from the scenario rubric)

- **F1 (commit messages over diffs):** <fired/not> — <note>
- **F2 (missed action item):** <fired/not> — <which item(s)>
- **F3 (additions only):** <fired/not> — <note>
- **F4 (no fetch):** <fired/not> — <note>
- **F5 (fabricated command):** <fired/not> — <note>
- **F6 (flat log dump):** <fired/not> — <note>
- **F7 (no local-collision analysis):** <fired/not> — <note>
- **F8 (skipped orientation):** <fired/not> — <note>
- **F9 (base mishandling):** <fired/not> — <note>
- **F10 (ungated mutation):** <fired/not> — <note>

## Coverage

- Action-required items surfaced: <N of 5>
- Local collisions surfaced: <N of 2>

## Notes for skill author

<which failures are sharpest? any failure not on the F1–F10 list that emerged anyway?>
````

- [ ] **Step 2: Sanity-check pressure**

Confirm **≥3 of F1–F10 fired**. If ≤1 fired, the prompt let the subagent off too easily — make it terser (drop the "tell me exactly what I need to do" hint that pre-cues the action scan) and re-run Task 3. The richest expected failures are F4 (no fetch), F1 (commit-message reliance), F5 (fabricated command), F7 (no collision), F8 (skipped orientation).

- [ ] **Step 3: Commit**

```bash
git add tests/project-catchup-baseline-observations.md
git commit -m "Record baseline observations for project-catchup"
```

---

### Task 5: Draft initial SKILL.md

**Files:**
- Create: `skills/project-catchup/SKILL.md`

**Pre-read:** the engineer must have read `superpowers:writing-skills`, `skills/followup-tracking/SKILL.md`, and `skills/vault-brainstorming/SKILL.md`. Match that shape (frontmatter, overview, load-bearing core principle, phased procedure with exact commands, rationalization table, red flags, reference).

Write the file in the steps below. The procedure transcribes spec §6 (Phases 0–6) with concrete `git` commands; the rationalization table transcribes spec §8; red flags transcribe §9. **After drafting, prune the rationalization table to the failures Task 4 actually observed** — every row must map to a fired F-mode (or a new failure seen in the baseline). Cut rows that map to nothing.

- [ ] **Step 1: Frontmatter + description**

Path: `/home/nox/Documents/Projects/Nox/claude-config/skills/project-catchup/SKILL.md`

```markdown
---
name: project-catchup
description: Use when a developer returns to a git project after time away and wants a brief, impact-aware summary of what changed plus what they must do locally before resuming. Triggers on "catch me up on this project", "what changed since <commit|date|tag>", "what's new on main", "bring me up to speed", "what did I miss", "I've been away from this repo". Optional args: a target branch and/or a past node (commit, tag, or date). Requires a git repo. NOT a code-review/merge-readiness tool — that's feature-review.
---
```

- [ ] **Step 2: Overview + Core principle**

```markdown
# project-catchup

## Overview

Catch a returning developer up on a git project: orient on the project's own docs, resolve a base ("from when") and a target branch ("about what"), read the actual diffs, systematically scan for action-required items (migrations, deps, env, config, breaking), flag what collides with the developer's own local work, and render an action-first brief.

## Core principle (load-bearing)

**Read the diffs, then synthesise impact and action. Never summarise commit messages alone, and never report a catchup without a systematic action-required scan.**

Two failure modes define the skill by contrast: (1) paraphrasing `git log` as if commit messages were the change — they routinely omit and mislabel (a migration can hide behind "chore: misc tidy-ups"); and (2) producing a readable summary that silently misses the one migration or env var that blocks the first `pnpm dev`. Both are violations, not style choices.
```

- [ ] **Step 3: Procedure — Phase 0 and Phase 1**

```markdown
## Procedure

Seven phases (0–6). Phases 0–5 are mandatory; Phase 6 is optional and user-triggered.

### Phase 0 — Orient on project context (before anything else)

Before resolving endpoints, asking, or reading git history, read the project's own docs: root `README`, `CLAUDE.md` (and `AGENTS.md` / `CONTRIBUTING` if present). Enter Phase 1 already knowing the stack, package manager, branch model, and setup/migrate/run commands. This often settles the primary-branch question without asking, and is the **first and authoritative** source for fix-command inference in Phase 3. Absent/thin docs → note it and proceed. This does not replace reading the diff (Phase 2).

### Phase 1 — Resolve the two endpoints

**Target branch** (what the catchup is about):
- Explicit branch arg wins.
- Else infer the primary integration branch:
  `git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null` →
  else first existing of: `for b in main master develop staging dev; do git show-ref --verify --quiet "refs/remotes/origin/$b" && echo "$b" && break; done` →
  else, if multiple long-lived candidates and no `origin/HEAD`, **ask the user once**, naming the candidates.
- `git fetch --quiet` (skip with a noted caveat if offline / no remote), then compare against `origin/<target>`.
- Report local-behind: `git rev-list --count <target>..origin/<target>`.

**Base** (what to catch up from):
- Explicit commit / tag wins. A date resolves to a commit: `git rev-list -1 --before="<date>" origin/<target>`.
- Else **infer and confirm** — present candidates, let the user pick/override:
  - your last commit: `git log -1 --format='%h %ad %s' --author="$(git config user.email)" origin/<target> --` (also check all branches if empty)
  - merge-base: `git merge-base HEAD origin/<target>`
  - last pull: `git rev-parse --verify ORIG_HEAD 2>/dev/null`
  - last local commit on target: `git rev-parse <target>`
- **History-rewrite guard:** `git merge-base --is-ancestor <base> origin/<target>` — if it exits non-zero, the base is not an ancestor (force-push/rebase). Warn and fall back (date-based base, or merge-base) rather than emitting a wrong `base..target` diff.
```

- [ ] **Step 4: Procedure — Phases 2–4**

```markdown
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

Convert "what changed" into "what changed that affects *you*":
- **Uncommitted overlaps:** files in `git status --porcelain` that also appear in the `<base>..origin/<target>` name-status → likely conflict on pull/rebase.
- **Branch-dependency hits:** if on a feature branch, files it touched (`git diff --name-only <base>..HEAD`) that the target also changed/renamed/moved → rebase won't be mechanical.
- Report the local-behind count here as context. Omit the whole section if the tree is clean and sitting on the up-to-date target.
```

- [ ] **Step 5: Procedure — Phases 5–6 + output**

````markdown
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
````

- [ ] **Step 6: Rationalizations table**

Transcribe spec §8 into a `| Rationalization | Reality |` table, then prune to observed failures. Draft rows:

```markdown
## Rationalizations — these are violations, not exceptions

| Rationalization | Reality |
|---|---|
| "I'll jump straight to the git log — the project context will emerge from the diff." | Orient on README + CLAUDE.md first (Phase 0). It settles the branch question and grounds command inference; cold-reading from the diff is weaker and slower. |
| "The commit messages tell me what changed — I'll summarise those." | Commit messages omit and misstate (a migration hid behind "chore: misc tidy-ups"). Read the diff; it is the source of truth. |
| "I covered the big features — close enough." | A missed migration / env var blocks the first run. The Phase 3 scan is systematic and mandatory, not best-effort. |
| "Only additions matter." | A removed dependency or a renamed/deleted env key breaks local dev too. Add / remove / rename are all first-class. |
| "I'll just diff base..main from local refs." | Without `git fetch`, a stale clone yields an incomplete catchup. Fetch first; compare against `origin/<target>`. |
| "The base is whatever the user said — just diff it." | If the base isn't an ancestor of the target (force-push/rebase), the diff is wrong. Verify ancestry; warn and fall back. |
| "I don't know the migrate command, so I'll guess `npm run migrate`." | Infer from CLAUDE.md / package.json / Makefile. If unknown, say unknown — never fabricate a command. |
| "Several long-lived branches exist; I'll pick main and proceed." | If the primary branch is genuinely ambiguous, ask once. Don't catch up on the wrong line. |
| "Here's everything that changed." (flat dump) | Brief, grouped, impact-aware. Summarise by area; the report is not a re-rendered `git log`. |
| "I'll run the migrations to save a step." | Mutating actions are Phase 6, confirmation-gated, one at a time. Never auto-apply. |
```

Each kept row must trace to a Task 4 failure; annotate the mapping in the commit message or a trailing comment.

- [ ] **Step 7: Red flags + Reference**

```markdown
## Red flags — stop and re-read this skill

- About to resolve endpoints, ask, or read git history without having read README + CLAUDE.md first (Phase 0).
- About to report a catchup without having run `git diff` (commit messages only).
- About to present the summary without a systematic action-required scan.
- About to skip `git fetch` / compare against local refs without noting it.
- About to emit a `base..target` diff without confirming the base is an ancestor of the target.
- About to fabricate a fix command instead of inferring it or marking it unknown.
- About to run a migration or install without explicit user confirmation.

## Reference

REQUIRED BACKGROUND for editing this skill: `superpowers:writing-skills` (TDD-for-skills, rationalization closure).

Pressure scenario: `tests/project-catchup-baseline-pressure-scenario.md` (fixture: `tests/project-catchup-fixture.sh`). Failure modes it must close: `tests/project-catchup-baseline-observations.md`. Design rationale: `docs/specs/2026-06-19-project-catchup-design.md`.
```

- [ ] **Step 8: Commit**

```bash
git add skills/project-catchup/SKILL.md
git commit -m "Draft initial project-catchup SKILL.md against baseline failures"
```

---

### Task 6: Install the symlink

**Files:**
- Create (symlink, filesystem only): `~/.claude/skills/project-catchup` → repo `skills/project-catchup`

- [ ] **Step 1: Install**

```bash
ln -s /home/nox/Documents/Projects/Nox/claude-config/skills/project-catchup ~/.claude/skills/project-catchup
```

- [ ] **Step 2: Verify**

```bash
readlink -f ~/.claude/skills/project-catchup
```

Expected: `/home/nox/Documents/Projects/Nox/claude-config/skills/project-catchup`.

(No commit — filesystem only.)

---

### Task 7: Update README.md with the new symlink line

**Files:**
- Modify: `README.md` (the symlink-install block in Setup)

- [ ] **Step 1: Add the install line**

After the `vault-brainstorming` symlink line in step 3's block, append:

```bash
ln -s "$REPO/skills/project-catchup"      ~/.claude/skills/project-catchup
```

- [ ] **Step 2: Add the verification line**

After the `vault-brainstorming` readlink line in step 4's block, append:

```bash
readlink -f ~/.claude/skills/project-catchup
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Document project-catchup symlink in README"
```

---

### Task 8: Run the with-skill scenario

**Files:** none modified yet (output captured in Task 9)

- [ ] **Step 1: Verify install and rebuild a clean fixture**

```bash
test -L ~/.claude/skills/project-catchup && test -f ~/.claude/skills/project-catchup/SKILL.md && echo "OK: skill installed"
/home/nox/Documents/Projects/Nox/claude-config/tests/project-catchup-fixture.sh
```

Expected: `OK: skill installed`, then `Fixture ready …`.

- [ ] **Step 2: Dispatch the with-skill subagent**

Use the `Agent` tool, `subagent_type: "general-purpose"`, with the **same verbatim subagent prompt**. Subagents inherit the harness skill list, so `project-catchup` is visible; the prompt's "catch me up" phrasing should trigger it. If the subagent doesn't invoke the skill, add one line to the prompt: "Use the project-catchup skill."

- [ ] **Step 3: Save the response + tool-call trace**

Stash for Task 9 (note especially: fetch? diff? read CLAUDE.md? collisions flagged? `make db-migrate` vs fabricated command?).

---

### Task 9: Document with-skill observations

**Files:**
- Create: `tests/project-catchup-with-skill-observations.md`

- [ ] **Step 1: Write the observations file**

Same template as Task 4, plus a comparison section:

````markdown
## Comparison to baseline

For each F1–F10: **closed / leaked / partial** + one-line note.

- F1: <…>
- F2: <…>
- … through F10 …

## Coverage with skill

- Action-required items surfaced: <N of 5>  (correct command used? <yes/no>)
- Local collisions surfaced: <N of 2>

## Verdict

<all closed? iterate? acceptable?>
````

- [ ] **Step 2: Decide on iteration**

If **all observed-in-baseline failures are now closed**, proceed to Task 11 (skip Task 10). If **any leaked/partial**, proceed to Task 10.

- [ ] **Step 3: Commit**

```bash
git add tests/project-catchup-with-skill-observations.md
git commit -m "Record with-skill observations for project-catchup"
```

---

### Task 10: Iterate SKILL.md to close residual loopholes (CONDITIONAL)

**Run only if Task 9 found any leaked/partial failure.**

**Files:**
- Modify: `skills/project-catchup/SKILL.md`
- Append to: `tests/project-catchup-with-skill-observations.md`

- [ ] **Step 1: For each leak, name the rationalization the subagent used**

Find the sentence/thought that let the failure slip. That becomes a new "Rationalization" row; "Reality" states the rule + why, anchored in the observed leak. If the leak is *structural* (an unclear procedure step, not a rationalized skip), fix the procedure section directly instead.

- [ ] **Step 2: Edit SKILL.md**

Add the row(s) or tighten the procedure.

- [ ] **Step 3: Rebuild the fixture and re-dispatch**

```bash
/home/nox/Documents/Projects/Nox/claude-config/tests/project-catchup-fixture.sh
```

Then re-dispatch the subagent (same prompt as Task 8).

- [ ] **Step 4: Append an "Iteration N" section** to the with-skill observations (tool-call counts, F-statuses, verdict; date-stamped).

- [ ] **Step 5: Commit**

```bash
git add skills/project-catchup/SKILL.md tests/project-catchup-with-skill-observations.md
git commit -m "Close residual project-catchup loopholes (iteration N)"
```

- [ ] **Step 6: Loop**

Repeat Steps 1–5 if anything still leaks. **Hard ceiling: 3 iterations.** If 3 don't close it, stop and surface to the user — the gap may be a design-level (spec) issue, not a skill-wording one.

---

### Task 11: Final review and cleanup

**Files:** none modified

- [ ] **Step 1: Verify file map**

```bash
ls -la /home/nox/Documents/Projects/Nox/claude-config/skills/project-catchup/
ls -la /home/nox/Documents/Projects/Nox/claude-config/tests/ | grep project-catchup
readlink -f ~/.claude/skills/project-catchup
```

Expected: `SKILL.md` present; four `project-catchup-*` files in `tests/` (fixture script + scenario + baseline + with-skill); symlink resolves to the repo path.

- [ ] **Step 2: Remove the throwaway fixture and confirm a clean tree**

```bash
rm -rf /tmp/project-catchup-fixture
cd /home/nox/Documents/Projects/Nox/claude-config && git status
```

Expected: `nothing to commit, working tree clean`. Commit anything stray with an honest message.

- [ ] **Step 3: Smoke-test in a fresh Claude Code session**

In a new session, confirm `project-catchup` appears in the available-skills list, and that invoking it on a real git project (e.g. this repo, "catch me up since <a commit>") runs Phase 0 orientation → fetch → diff-based summary with an action-first block. (Manual check by the user; the engineer just confirms artifacts are in place.)

---

## Notes on subagent test fidelity

Subagent runs are stochastic — the exact F-modes that fire vary run to run on the same fixture. That's acceptable: the goal is coverage of the failure-mode space, not bit-reproducibility. Task 4 needs ≥3 of F1–F10 to have enough signal (else re-pressure the prompt per Task 4 Step 2). For Task 9, a single with-skill run that closes the baseline failures is sufficient; if one leaks, Task 10 extracts a rule from it. Don't rerun "for confidence" before iterating — each rerun should be paired with a rule change, or it just burns tokens. Always rebuild the fixture (`tests/project-catchup-fixture.sh`) before each dispatch so fetch state and the uncommitted edit are pristine.
```
