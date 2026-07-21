# Security Controls

Security posture of the AI Character Video Generation Platform, consolidated for
a production-readiness review (Phase 13). Controls introduced in earlier phases
are cross-referenced.

## Authentication & sessions
- JWT **access tokens** (short-lived) + **rotating, hashed refresh tokens**
  (only a SHA-256 digest is stored; the raw value is returned once). Phase 2.
- Suspended/deleted accounts are rejected by the stateless access-token check;
  suspension and account deletion **revoke all refresh tokens** immediately.
- Password change revokes all existing sessions.

## Authorization
- Pundit policies enforce ownership and role; non-owners get **404, not 403**
  (no existence leak). Admin endpoints require the `admin` role (401 → 403).
- Every admin/operational endpoint is admin-gated and audited.

## Secrets
- Provider API keys resolve through `Providers::Credentials`: the **encrypted
  `PlatformSetting`** (Active Record encryption, keys from `AR_ENCRYPTION_*`)
  first, then ENV. Secrets are never logged, never returned by the API, and are
  masked in the settings snapshot (write-only). Adapters never read raw ENV.
- Rotate `AR_ENCRYPTION_*`, `JWT_SECRET`, and provider keys per your policy.

## Rate limiting
- `Rack::Attack` on a **shared Redis store** (enforced across all web
  processes). Throttles: login, register, refresh, password-reset, email-verify,
  approval links, downloads, provider webhooks, and **video-generation starts**.
  429 responses use the standard JSON error envelope.

## Input & output safety
- Uploaded audio is validated by MIME, size cap, and magic-byte spoof check.
- Private assets are served only via **signed, expiring URLs**
  (`Downloads::SignedUrl`); storage keys are never exposed to clients.
- Provider webhooks are **HMAC-SHA256 signature-verified** (constant-time) and
  throttled as defence in depth.
- Approval links are single-use, expiring, and stored as hashes.

## Logging & observability
- Structured single-line JSON logs (lograge) with a **request id**; the same id
  is echoed on responses as `X-Request-Id`.
- **PII-safe logs**: `config.filter_parameters` filters passwords/tokens/keys,
  and lograge applies the same filter to its params payload.
- Errors flow through `Rails.error.report` to a structured subscriber; a Sidekiq
  **death handler** reports jobs that exhaust retries. An external tracker
  (e.g. Sentry) can be layered in via the gem + `SENTRY_DSN` with no code change.

## Reliability
- Provider HTTP calls run behind a **circuit breaker** (`Providers::CircuitBreaker`,
  shared Redis state, `PROVIDER_CIRCUIT_THRESHOLD`/`PROVIDER_CIRCUIT_COOLDOWN_SECONDS`)
  that fails fast when a provider is down and auto-heals after the cooldown.
- Jobs are idempotent, use exponential backoff, and never strand work state.

## Data lifecycle
- **Account deletion**: `Accounts::RequestDeletion` revokes sessions and
  soft-deletes immediately; `PurgeAccountJob` then destroys owned data
  (projects → characters/videos/prompts/generations/assets) and anonymizes PII.
- **Retention**: `PurgeExpiredAssetsJob` (schedule via cron) deletes assets past
  `file_retention_days` and their storage blobs (dedupe-safe).

## Audit trail
- Append-only `AuditLog` (immutable rows). Covers privileged admin actions
  (Phase 11) **and** sensitive user actions (Phase 13): failed logins, password
  resets, account-deletion requests, and token-based character approve/reject.

## Automated scanning (CI)
- **Brakeman** (static analysis) and **bundler-audit** (dependency CVEs) run on
  every push/PR and block the build on new findings.

## Accepted risks (tracked)
- **Rails 7.1 is end-of-life** for security support (2025-10-01). A cluster of
  ActiveSupport/ActiveStorage/ActionView advisories is fixed only in Rails
  ≥ 7.2.3.1. These are documented in `backend/.bundler-audit.yml` and
  `backend/config/brakeman.ignore` as **accepted risk**: the API-only backend
  does not expose the affected surfaces (number/HTML helpers over untrusted
  input, Active Storage proxy multi-range) to exploitable input.
  **Follow-up:** upgrade to the maintained Rails 7.2.x line, then remove both
  ignore files and re-audit.
