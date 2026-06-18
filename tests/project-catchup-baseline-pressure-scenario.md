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
