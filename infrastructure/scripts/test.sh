#!/usr/bin/env bash
# Runs the full backend and frontend test suites inside the dev containers.
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "==> Backend: RSpec"
docker compose run --rm -e RAILS_ENV=test api \
  bash -lc "bundle exec rails db:prepare && bundle exec rspec"

echo "==> Frontend: lint, typecheck, test, build"
docker compose run --rm web \
  sh -lc "npm run lint && npm run typecheck && npm run test && npm run build"

echo "==> All tests passed"
