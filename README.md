# AI Character Video Generation Platform

Production-oriented platform that automates the creation of short animated AI
character videos: a user creates a **project**, generates exactly **one approved
character** (Gemini), then produces **multiple videos** — each with an OpenAI
prompt and four Google Labs renders (two 3:4, two 9:16, 15 seconds).

This repository is being built **phase by phase** per
[`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md).

> **Current status: Phase 2 — Authentication, Authorization, Accounts & Roles**
> (Phase 1 foundation complete). Delivered so far: health/tooling/Docker/CI
> foundation, plus JWT auth (access + rotating refresh tokens), registration,
> login/logout, password reset, email verification, account profile (`/me`),
> role-based access control (user/admin), and rate limiting on auth endpoints.
> Projects, characters, videos, and AI providers arrive in later phases.

---

## Architecture

| Layer          | Technology                                             |
| -------------- | ------------------------------------------------------ |
| Backend API    | Ruby on Rails 7.1 (API-only), Ruby 3.3                 |
| Database       | PostgreSQL 15                                          |
| Cache / queue  | Redis 7                                                 |
| Background jobs| Sidekiq 7                                               |
| Frontend       | React 19 + TypeScript, Vite 6                           |
| Tests          | RSpec + FactoryBot (backend), Vitest + Testing Library |
| Local dev      | Docker Compose                                         |

### Repository layout

```text
/
├── backend/          # Rails API application
├── frontend/         # React + TypeScript (Vite) web app
├── infrastructure/
│   ├── docker/       # Dev Dockerfiles
│   └── scripts/      # setup.sh, test.sh
├── docs/             # requirements.md, SRS.md, IMPLEMENTATION_PLAN.md
├── docker-compose.yml
├── .env.example
└── README.md
```

### Design principles

- **Provider abstraction** — all AI/storage/email vendors sit behind adapter
  interfaces (introduced in later phases); no provider SDK is ever called from a
  controller.
- **Service objects** — business logic lives in `app/services`, keeping
  controllers and models thin (see `Health::CheckService`).
- **Serialization layer** — JSON responses are produced by Blueprinter
  blueprints (`app/blueprints`), not inline in controllers.
- **Background-first** — long-running work runs in idempotent Sidekiq jobs.

---

## Prerequisites

- Docker + Docker Compose (the supported, one-command path), **or**
- For native runs: Ruby 3.3.11, Node 20 LTS, PostgreSQL 15, Redis 7.

---

## Quick start (Docker)

```bash
cp .env.example .env
docker compose build
docker compose up
```

Then open:

- **Frontend:** http://localhost:5173 (shows live system-health status)
- **API health:** http://localhost:3000/api/v1/health
- **Sidekiq dashboard:** http://localhost:3000/sidekiq (development only)

Or use the helper script, which builds, starts, and waits for health:

```bash
./infrastructure/scripts/setup.sh
```

> Host ports for Postgres and Redis are mapped to **5433** and **6380** to avoid
> clashing with services already running on your machine. Containers talk to each
> other over the compose network on the standard 5432/6379.

---

## The health endpoint

`GET /api/v1/health` reports API, database, Redis, and Sidekiq connectivity plus
the app version. Returns `200` when healthy, `503` when any dependency is down.

```json
{
  "status": "ok",
  "version": "0.1.0",
  "components": { "database": "ok", "redis": "ok", "sidekiq": "ok" },
  "timestamp": "2026-07-14T00:00:00Z"
}
```

---

## Authentication

JWT-based auth designed to serve both the React portal and future mobile apps:
a short-lived **access token** (15 min, HS256) plus a long-lived **refresh
token** (30 days) stored hashed and **rotated** on every refresh (revocable for
real logout). Email verification and password-reset use stateless, expiring
tokens. Roles: `user`, `admin`.

| Method | Path | Auth | Purpose |
|---|---|---|---|
| POST | `/api/v1/auth/register` | public | Create account, returns tokens |
| POST | `/api/v1/auth/login` | public | Authenticate, returns tokens |
| POST | `/api/v1/auth/logout` | public | Revoke a refresh token |
| POST | `/api/v1/auth/refresh` | public | Rotate tokens |
| POST | `/api/v1/auth/password/forgot` | public | Send reset email (always 202) |
| POST | `/api/v1/auth/password/reset` | public | Set new password via token |
| POST | `/api/v1/auth/email/verify` | public | Verify email via token |
| GET/PATCH/DELETE | `/api/v1/me` | user | View / update / delete own account |
| GET | `/api/v1/admin/users` | admin | List users (RBAC) |

Send the access token as `Authorization: Bearer <token>`. Auth endpoints are
rate-limited (Rack::Attack). In development, outbound emails open in the browser
via `letter_opener`.

---

## Running tests

**Everything, in containers:**

```bash
./infrastructure/scripts/test.sh
```

**Backend (RSpec):**

```bash
docker compose run --rm -e RAILS_ENV=test api \
  bash -lc "bundle exec rails db:prepare && bundle exec rspec"
```

**Frontend (Vitest + lint + typecheck + build):**

```bash
cd frontend
npm run lint && npm run typecheck && npm run test && npm run build
```

CI (GitHub Actions, `.github/workflows/ci.yml`) runs both suites on every push
and pull request to `main`.

---

## Environment variables

All configuration is environment-driven. See [`.env.example`](.env.example) for
the full list. Key variables:

| Variable            | Purpose                                  | Default                          |
| ------------------- | ---------------------------------------- | -------------------------------- |
| `DATABASE_HOST`     | Postgres host                            | `localhost` (`postgres` in compose) |
| `DATABASE_USERNAME` | Postgres user                            | `aicvp`                          |
| `DATABASE_PASSWORD` | Postgres password                        | `aicvp_password`                 |
| `REDIS_URL`         | Redis connection URL                     | `redis://localhost:6379/0`       |
| `CORS_ORIGINS`      | Comma-separated allowed frontend origins | `http://localhost:5173`          |
| `APP_VERSION`       | Version reported by `/health`            | `0.1.0`                          |
| `JWT_SECRET`        | Secret for signing JWT access tokens     | Rails `secret_key_base`          |
| `FRONTEND_URL`      | Base URL used to build links in emails   | `http://localhost:5173`          |
| `MAIL_FROM`         | Default From address for outbound email  | `no-reply@aicvp.local`           |
| `VITE_API_BASE_URL` | API base URL used by the frontend        | `http://localhost:3000/api/v1`   |

---

## Development notes

- Backend and frontend source directories are bind-mounted into their containers,
  so edits reload live (Rails reloading / Vite HMR).
- Gems are cached in a named Docker volume (`bundle_cache`); after changing the
  `Gemfile`, run `docker compose build api`.
- Frontend `node_modules` lives in an anonymous volume so host and container
  dependency trees stay isolated.

---

## Roadmap

Subsequent phases (see `docs/IMPLEMENTATION_PLAN.md`): authentication & roles →
project lifecycle → Gemini character generation → email approval → video
workspace & transcription → OpenAI prompts → Google Labs video generation →
asset storage → notifications → admin portal → cost tracking → security
hardening → production deployment. Phase 2 adds Flutter mobile apps.
