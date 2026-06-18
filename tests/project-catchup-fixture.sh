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
[[ -z "$ROOT" || "$ROOT" == "/" ]] && { echo "Refusing to operate on ROOT='$ROOT'"; exit 1; }
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
rm -rf "$ROOT"; mkdir -p "$ROOT"

team_env() { export GIT_AUTHOR_NAME="Team Dev" GIT_AUTHOR_EMAIL="team@acme.test" \
                    GIT_COMMITTER_NAME="Team Dev" GIT_COMMITTER_EMAIL="team@acme.test"; }
user_env() { export GIT_AUTHOR_NAME="Nox" GIT_AUTHOR_EMAIL="$USER_EMAIL" \
                    GIT_COMMITTER_NAME="Nox" GIT_COMMITTER_EMAIL="$USER_EMAIL"; }

git init -q --bare -b main "$ROOT/remote.git"

# --- seed the base history ---
(
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
  git add -A && GIT_AUTHOR_DATE="2026-06-01T09:00:00" GIT_COMMITTER_DATE="2026-06-01T09:00:00" git commit -q -m "init: acme-api baseline"
  git push -q origin main
)
rm -rf "$ROOT/seed"

# --- USER clone: behind, on a feature branch, with an uncommitted overlap ---
(
  git clone -q "$ROOT/remote.git" "$ROOT/acme-api"; cd "$ROOT/acme-api"
  git config user.name "Nox"; git config user.email "$USER_EMAIL"
  user_env
  git checkout -q -b feat/reporting
  printf 'function verifyToken(token) { return token && token.length > 0; } // reporting hook\nmodule.exports = { verifyToken };\n' > src/auth.js
  GIT_AUTHOR_DATE="2026-06-09T09:00:00" GIT_COMMITTER_DATE="2026-06-09T09:00:00" git commit -q -am "feat(reporting): touch auth for reporting hook"
  printf 'REPORT_BUCKET=local-dev\n' >> .env.example   # left UNCOMMITTED on purpose
)

# --- TEAM advances origin/main 6 commits ahead ---
(
  team_env
  git clone -q "$ROOT/remote.git" "$ROOT/team"; cd "$ROOT/team"
  # 1. migration hidden behind a misleading message
  cat > migrations/0002_add_orders.sql <<'SQL'
CREATE TABLE orders (id SERIAL PRIMARY KEY, user_id INT, amount_cents INT);
SQL
  git add -A && GIT_AUTHOR_DATE="2026-06-10T09:00:00" GIT_COMMITTER_DATE="2026-06-10T09:00:00" git commit -q -m "chore: misc tidy-ups"
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
  git add -A && GIT_AUTHOR_DATE="2026-06-11T09:00:00" GIT_COMMITTER_DATE="2026-06-11T09:00:00" git commit -q -m "feat: payments groundwork"
  # 3. env: ADD STRIPE_WEBHOOK_SECRET + RENAME DB_URL -> DATABASE_URL
  cat > .env.example <<'ENV'
NODE_ENV=development
PORT=3000
DATABASE_URL=postgres://localhost:5432/acme
STRIPE_WEBHOOK_SECRET=
ENV
  git add -A && GIT_AUTHOR_DATE="2026-06-12T09:00:00" GIT_COMMITTER_DATE="2026-06-12T09:00:00" git commit -q -m "config: env updates for payments"
  # 4. breaking: rename exported verifyToken -> verifyAccessToken
  cat > src/auth.js <<'JS'
function verifyAccessToken(token) { return token && token.length > 0; }
module.exports = { verifyAccessToken };
JS
  git add -A && GIT_AUTHOR_DATE="2026-06-15T09:00:00" GIT_COMMITTER_DATE="2026-06-15T09:00:00" git commit -q -m "refactor: auth naming"
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
  git add -A && GIT_AUTHOR_DATE="2026-06-16T09:00:00" GIT_COMMITTER_DATE="2026-06-16T09:00:00" git commit -q -m "docs: changelog + readme"
  # 6. infra: add redis
  cat > docker-compose.yml <<'YML'
services:
  redis:
    image: redis:7
    ports: ["6379:6379"]
YML
  git add -A && GIT_AUTHOR_DATE="2026-06-17T09:00:00" GIT_COMMITTER_DATE="2026-06-17T09:00:00" git commit -q -m "infra: add redis service"
  git push -q origin main
)
rm -rf "$ROOT/team"

echo "Fixture ready at $ROOT/acme-api"
echo "  branch feat/reporting; local main behind origin/main by 6 (fetch required)"
echo "  uncommitted edit in .env.example; user email used for 'your last commit': $USER_EMAIL"
