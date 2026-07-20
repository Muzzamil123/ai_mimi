# AI Character Video Generation Platform

Production-oriented platform that automates the creation of short animated AI
character videos: a user creates a **project**, generates exactly **one approved
character** (Gemini), then produces **multiple videos** — each with an OpenAI
prompt and four Google Labs renders (two 3:4, two 9:16, 15 seconds).

This repository is being built **phase by phase** per
[`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md).

> **Current status: Phase 5 — Email Approval Workflow** (Phases 1–4 complete).
> Delivered so far: health/tooling/Docker/CI foundation; JWT auth (access +
> rotating refresh tokens), registration, login/logout, password reset, email
> verification, `/me`, RBAC (user/admin), auth rate limiting; **project
> management** — CRUD, per-user unique slugs, a guarded status lifecycle with
> history, archive/restore, ownership enforcement, and list search/filter/
> pagination; and **character generation** — one character per project via a
> Gemini image adapter, an async Sidekiq pipeline (prompt → image → store →
> approval email), secure storage behind a storage abstraction, an
> approve/reject/regenerate lifecycle with a locked approved character and an
> audited admin reset, and a React character workspace. Videos and the remaining
> providers arrive in later phases.

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

- **Provider abstraction** — all AI/storage vendors sit behind adapter
  interfaces (`CharacterImageProviders`, `CharacterPromptProviders`, `Storage`);
  no provider SDK is ever called from a controller. Providers are selected by
  env var, defaulting to hermetic fakes in dev/test so the app runs without
  external credentials.
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

## Projects

Each user owns projects that move through a guarded status lifecycle
(`draft → initializing_character → awaiting_character_approval →
character_rejected → ready → failed`, plus `archived`). Every transition is
recorded in a status-history log. Editing and deleting are restricted to
`draft`; other projects are archived/restored instead. One character per
project is set up structurally now (`active_character_id`) and populated in
Phase 4.

| Method | Path | Purpose |
|---|---|---|
| GET | `/api/v1/projects?q=&status=&page=&per_page=` | List own projects (search/filter/paginate) |
| POST | `/api/v1/projects` | Create a draft project |
| GET | `/api/v1/projects/:id` | Show project + status history |
| PATCH | `/api/v1/projects/:id` | Update (draft only) |
| DELETE | `/api/v1/projects/:id` | Delete (draft only) |
| POST | `/api/v1/projects/:id/archive` | Archive |
| POST | `/api/v1/projects/:id/restore` | Restore to pre-archive status |

Send the access token as `Authorization: Bearer <token>`. Auth endpoints are
rate-limited (Rack::Attack). In development, outbound emails open in the browser
via `letter_opener`.

## Characters

Each project owns **exactly one** character (enforced by a unique index).
Generation is a fully asynchronous Sidekiq pipeline —
`GenerateCharacterPromptJob → GenerateCharacterImageJob →
DownloadCharacterImageJob → SendCharacterApprovalEmailJob` — where the prompt is
built via the prompt provider (OpenAI in production), the image via the Gemini
adapter, the asset stored via the storage abstraction, and an approval email is
sent to the authenticated owner. Every job is idempotent and keyed by a rotating
`generation_id`, so stale or duplicate jobs safely no-op.

The character status machine (`pending → generating → awaiting_approval →
approved`, with `rejected`/`failed` branches) is kept in lock-step with the
project status. An approved character is **locked** and becomes the project's
active character; only an administrator can reset it (an audited operation).
Generated image bytes are served through an authenticated download endpoint —
storage keys are never exposed.

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/api/v1/projects/:id/character` | owner/admin | Show the character |
| POST | `/api/v1/projects/:id/character` | owner/admin | Set up the character (draft project) |
| PATCH | `/api/v1/projects/:id/character` | owner/admin | Edit before generation |
| DELETE | `/api/v1/projects/:id/character` | owner/admin | Delete (unless approved) |
| POST | `/api/v1/projects/:id/character/generate` | owner/admin | Start / regenerate generation (202) |
| POST | `/api/v1/projects/:id/character/approve` | owner/admin | Approve & lock |
| POST | `/api/v1/projects/:id/character/reject` | owner/admin | Reject with optional feedback |
| POST | `/api/v1/projects/:id/character/reset` | admin | Audited reset of a locked character |
| GET | `/api/v1/projects/:id/character/image` | owner/admin | Stream the latest image |

---

## Email approval workflow

Once a character reaches `awaiting_approval`, `SendCharacterApprovalEmailJob`
mints a **secure, single-use, expiring `ApprovalRequest`** and emails the project
owner a tokenized link. The raw token lives only in the email; the database
stores a SHA-256 digest (mirrors the refresh-token design). The recipient is
always resolved from the owner's **current** account email — never hardcoded.

The link resolves to a **public, token-protected** approval page (no login) at
`/approvals/character/:token`. The token is the authorization, so these
endpoints skip authentication and are rate-limited (Rack::Attack). Approving
delegates to the same `Characters::ApproveCharacter` service the portal uses —
the character/project state machine stays the single source of truth — then
locks the character, readies the project, and sends a confirmation email.
Rejecting records feedback, moves the project to `character_rejected` (from which
the same project can regenerate), and confirms by email.

Links are **single-use** (a spent token → `409 already_processed`) and expire
after `APPROVAL_LINK_TTL_HOURS` (default 72). Expiry is enforced lazily on access
and proactively by `ExpireApprovalRequestsJob`, which also emails an
"link expired" notice. `CreateApprovalRequest` cancels any prior pending link
(cancel-and-replace), so a retry or regeneration never leaves two live tokens.
Unknown/tampered tokens 404 and are logged as suspicious attempts.

Emails sent: **character ready for approval**, **approved**, **rejected**,
**approval link expired** — all to the owner's account email.

> **Scheduling `ExpireApprovalRequestsJob`:** there is no scheduler gem yet
> (Phase 13 hardening). Run it periodically via cron/`sidekiq-cron` or manually:
> `ExpireApprovalRequestsJob.perform_later`. Expiry is still enforced lazily on
> every token access, so links never work past their window regardless.

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/api/v1/approvals/character/:token` | public (token) | Resolve link state (pending/approved/rejected/expired) |
| POST | `/api/v1/approvals/character/:token/approve` | public (token) | Approve & lock the character |
| POST | `/api/v1/approvals/character/:token/reject` | public (token) | Reject with optional feedback |
| GET | `/api/v1/approvals/character/:token/image` | public (token) | Stream the character preview |

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
| `STORAGE_BACKEND`   | Storage adapter (`local`)                | `local`                          |
| `STORAGE_ROOT`      | Root dir for local storage               | `backend/storage`                |
| `CHARACTER_IMAGE_PROVIDER`  | Image provider (`gemini`/`fake`) | `fake` (dev/test), `gemini` (prod) |
| `CHARACTER_PROMPT_PROVIDER` | Prompt provider (`openai`/`local`) | `local` (dev/test), `openai` (prod) |
| `GEMINI_API_KEY`    | Google Gemini API key (image generation) | — (required in production)       |
| `GEMINI_IMAGE_MODEL`| Gemini image model                       | `gemini-2.5-flash-image`         |
| `OPENAI_API_KEY`    | OpenAI API key (prompt generation)       | — (required in production)       |
| `SIDEKIQ_CONCURRENCY` | Sidekiq worker threads                 | `5`                              |

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
