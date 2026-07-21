# Deployment Guide

How to build, configure, and deploy the platform to production (Phase 14).
Pair with the [environment-variable reference](environment.md),
[provider setup guide](providers.md), and the [operations runbook](runbook.md)
(backups, incident response, rollback detail).

## Topology

Five services (see `docker-compose.prod.yml` for a runnable single-host
reference of the exact topology):

| Service | Image | Role |
|---|---|---|
| `api` | `backend/Dockerfile` | Rails API (Puma). Runs migrations on boot. |
| `worker` | `backend/Dockerfile` (`bundle exec sidekiq`) | Background jobs. |
| `web` | `infrastructure/docker/frontend.Dockerfile` | React SPA via nginx; reverse-proxies `/api` to `api`. |
| `postgres` | managed Postgres 15 (or the compose service) | Application data. |
| `redis` | managed Redis 7 (or the compose service) | Sidekiq queues + rate-limit/circuit-breaker state. |

For real production, prefer **managed Postgres, Redis, and object storage** and
a container platform (ECS/Kubernetes/Fly/Render); the compose file documents the
same shape for a single host or staging box.

## Environments

| Env | Purpose | Notes |
|---|---|---|
| local | development | `docker-compose.yml`, `.env` (fakes; no cloud) |
| test | CI | GitHub Actions; fakes; ephemeral Postgres/Redis |
| staging | pre-prod validation | production images; real providers in sandbox mode |
| production | live | production images; managed datastores + object storage |

## Build the images

```bash
# API + worker (same image)
docker build -t aicvp-api:$(git rev-parse --short HEAD) backend

# Frontend (SPA → nginx). Bake the API base URL; default "/api/v1" (same-origin).
docker build -t aicvp-web:$(git rev-parse --short HEAD) \
  -f infrastructure/docker/frontend.Dockerfile \
  --build-arg VITE_API_BASE_URL=/api/v1 .
```

Tag images immutably (git SHA). Push to your registry. Add container image
scanning (e.g. Trivy) in the build pipeline before push.

## Configure secrets

Never commit secrets. Provide them through your platform's secret manager (or a
`.env.production` for the reference compose). Required in production:

- `SECRET_KEY_BASE` (generate with `bin/rails secret`)
- `JWT_SECRET`, `AR_ENCRYPTION_PRIMARY_KEY`, `AR_ENCRYPTION_DETERMINISTIC_KEY`,
  `AR_ENCRYPTION_KEY_DERIVATION_SALT`
- `DATABASE_*`, `REDIS_URL`, `CORS_ORIGINS`, `FRONTEND_URL`, `API_PUBLIC_URL`
- Storage: `STORAGE_BACKEND=s3` + `S3_*` / `AWS_*`
- Providers + email (see [providers.md](providers.md))

See the [environment reference](environment.md) for the full list.

## Database migrations

The API image entrypoint runs `db:prepare` (create if needed + migrate) before
Puma starts, so a rolling deploy migrates automatically. Keep migrations
backward-compatible so old and new code can run against the new schema during a
rollout. For a manual run: `docker compose -f docker-compose.prod.yml run --rm api ./bin/rails db:migrate`.

## Deploy (reference, single host)

```bash
cp .env.example .env.production   # then fill in real secrets
docker compose -f docker-compose.prod.yml --env-file .env.production up -d --build
# Verify:
BASE_URL=http://localhost infrastructure/scripts/smoke.sh
```

On a container platform, deploy the `api`, `worker`, and `web` images as
separate services pointing at managed Postgres/Redis, put a TLS-terminating
load balancer / CDN in front of `web`, and wire the probes below.

## Health probes, monitoring & alerts

- **Liveness**: `GET /api/v1/health/live` (always 200 if the process is up).
- **Readiness**: `GET /api/v1/health/ready` (200 when Postgres + Redis reachable).
- Ship JSON logs (they carry `request_id`; responses echo `X-Request-Id`) to a
  log aggregator. Enable error tracking via `sentry-ruby` + `SENTRY_DSN`.
- Alert on: readiness failing, elevated 5xx / error-report rate, Sidekiq queue
  latency and Dead set growth, and budget-limit breaches (Phase 12).

## TLS, domain & CDN

Terminate TLS at the load balancer / CDN and forward to `web:80`. Front the SPA
and (optionally) signed asset downloads with a CDN. The app issues **HTTPS-only**
absolute links from `API_PUBLIC_URL`.

## Rollback

Deploy immutable image tags; to roll back, redeploy the previous tag. Because
migrations are backward-compatible, app code can roll back without a schema
change. See the [runbook](runbook.md#deployment-rollback) for the full procedure.

## Release-validation checklist

Run `infrastructure/scripts/release.sh` (Brakeman + bundler-audit + RuboCop +
full RSpec incl. the end-to-end acceptance spec + frontend checks). Then, against
staging:

- [ ] `smoke.sh` passes (live/ready/SPA/protected endpoint)
- [ ] End-to-end workflow: register → project → character generate + **approval
      email** → approve → video → prompt → **four outputs** → asset download →
      **completion email** (the `end_to_end_acceptance_spec` automates this)
- [ ] Budget tracking records usage; admin cost dashboard reflects it
- [ ] Backup + restore rehearsed (runbook) and **rollback** verified
- [ ] Monitoring dashboards + alerts firing
