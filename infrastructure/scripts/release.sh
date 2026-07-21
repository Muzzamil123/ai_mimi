#!/usr/bin/env bash
# Release-validation gate (Phase 14): runs the full automated validation suite
# that must pass before promoting a build — backend security scans + specs
# (including the end-to-end acceptance workflow) and the full frontend checks.
# Run from a clean checkout of the release commit.
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "==> Backend: static security analysis (Brakeman)"
docker compose run --rm api bash -lc "bundle exec brakeman -q --no-pager -i config/brakeman.ignore"

echo "==> Backend: dependency vulnerability scan (bundler-audit)"
docker compose run --rm api bash -lc "bundle exec bundler-audit check --update"

echo "==> Backend: RuboCop"
docker compose run --rm api bash -lc "bundle exec rubocop"

echo "==> Backend: RSpec (unit, request, job, and end-to-end acceptance specs)"
docker compose run --rm -e RAILS_ENV=test api \
  bash -lc "bundle exec rails db:prepare && bundle exec rspec"

echo "==> Frontend: lint, typecheck, test, build"
docker compose run --rm web \
  sh -lc "npm run lint && npm run typecheck && npm run test && npm run build"

echo "==> Release validation passed"
