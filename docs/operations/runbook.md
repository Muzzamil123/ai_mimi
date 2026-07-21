# Operations Runbook

Failure-recovery and routine operational procedures for the platform
(Phase 13). Pair with `security.md` (controls) and `google-labs-automation.md`
(video provider).

## Health & probes
- Liveness: `GET /api/v1/health/live` — always 200 if the process is up. Use for
  the container liveness probe (do **not** gate it on dependencies).
- Readiness: `GET /api/v1/health/ready` — 200 only when Postgres + Redis are
  reachable; 503 otherwise. Use for the load-balancer readiness probe.
- Deep check: `GET /api/v1/health` — DB, Redis, and Sidekiq; 200/503.

## Observability
- Logs are JSON with `request_id`; correlate a client report via the
  `X-Request-Id` response header. Ship logs to your aggregator.
- Enable an error tracker in production: add `sentry-ruby`/`sentry-rails` and set
  `SENTRY_DSN`. Errors and exhausted Sidekiq jobs already flow through
  `Rails.error.report`.

## Database (PostgreSQL)
- **Backups**: schedule `pg_dump` (or managed provider snapshots) at least daily;
  retain per policy; store off-host/encrypted.
  Example: `pg_dump "$DATABASE_URL" | gzip > aicvp-$(date +%F).sql.gz`.
- **Restore**: provision a fresh DB, `gunzip -c backup.sql.gz | psql "$DATABASE_URL"`,
  then `bin/rails db:migrate` if needed. Verify with `GET /api/v1/health/ready`.
- **Migrations**: run `bin/rails db:migrate` on deploy before starting new web
  pods; migrations are backward-compatible within a release.

## Redis
- Two logical uses: Sidekiq queues and the rate-limit/circuit-breaker cache.
- **Persistence**: enable AOF (`appendonly yes`) so queued jobs and breaker state
  survive a restart. The rate-limit/breaker data is regenerable, so a flush is
  non-fatal (limits reset, breakers close).
- If Redis is unavailable: readiness returns 503; Rack::Attack fails open
  (logged) so auth still works; Sidekiq pauses until Redis returns.

## Background jobs (Sidekiq)
- Queues: `default`, `mailers`, `ai_generation` (see `config/sidekiq.yml`).
- **Dead jobs**: a job that exhausts retries lands in the Dead set and is
  reported via the death handler (error tracker). Inspect/retry from the Sidekiq
  web dashboard (`/sidekiq`, HTTP-Basic-protected outside development).
- **Scheduled sweeps** (no scheduler gem bundled — wire via cron / a scheduler):
  - `PurgeExpiredAssetsJob` — data retention (daily).
  - `ExpireApprovalRequestsJob` — approval-link expiry (hourly).

## Account deletion (right to erasure)
- `DELETE /api/v1/me` revokes sessions + soft-deletes immediately, then
  `PurgeAccountJob` destroys owned data and anonymizes PII. Safe to re-run.

## Incident response
1. Check `GET /api/v1/health` and the error tracker for the failing component.
2. **Provider outage**: circuit breakers fail fast and auto-heal after cooldown;
   affected generations are retryable from the admin portal once recovered.
3. **DB down**: readiness 503 pulls instances from rotation; restore/failover,
   then verify readiness before returning to the pool.
4. **Abuse / spike**: Rack::Attack throttles blunt it; tighten limits via the
   initializer and redeploy if needed.
5. **Stuck generation**: cancel/retry the batch or variant from the admin portal
   (audited).

## Container & dependency scanning
- CI runs Brakeman + bundler-audit on every push/PR.
- Add container image scanning (e.g. Trivy) in the image-build pipeline before
  pushing to the registry.

## Deployment rollback
- Deploy immutable images by tag. To roll back, redeploy the previous tag.
  Only roll back the database when a migration is not backward-compatible
  (avoid such migrations); otherwise leave the schema and roll app code back.
