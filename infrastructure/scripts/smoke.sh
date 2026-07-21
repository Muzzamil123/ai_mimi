#!/usr/bin/env bash
# Post-deploy smoke test (Phase 14): verifies a running deployment is live,
# ready, and serving the SPA. Point BASE_URL at the deployed origin.
#
#   BASE_URL=https://app.example.com infrastructure/scripts/smoke.sh
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost}"
API="${BASE_URL%/}/api/v1"

check() {
  local desc="$1" url="$2" expect="${3:-200}"
  local code
  code=$(curl -fsS -o /dev/null -w "%{http_code}" "$url" || true)
  if [ "$code" != "$expect" ]; then
    echo "FAIL: $desc ($url) => $code (expected $expect)"
    exit 1
  fi
  echo "ok: $desc ($code)"
}

echo "==> Smoke testing ${BASE_URL}"
check "API liveness"  "${API}/health/live"
check "API readiness" "${API}/health/ready"
check "SPA index"     "${BASE_URL}/"
# Auth is required here, so a 401 proves the endpoint is wired and protected.
check "Protected endpoint rejects anonymous" "${API}/me" 401

echo "==> Smoke test passed"
