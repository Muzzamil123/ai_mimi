# Environment-Variable Reference

Every environment variable the backend and frontend read. `.env.example` is the
canonical template; this groups them with meaning and production guidance.
Anything marked **secret** must come from a secret manager, never source control.

## Core / app
| Variable | Required | Notes |
|---|---|---|
| `RAILS_ENV` | yes | `production` in prod. |
| `SECRET_KEY_BASE` | prod | **secret**. `bin/rails secret`. |
| `APP_VERSION` | no | Surfaced by the health endpoint. |
| `CORS_ORIGINS` | yes | Comma-separated allowed origins for the SPA. |
| `FRONTEND_URL` | yes | Base URL of the SPA (email links). |
| `API_PUBLIC_URL` | yes | Public API base URL (absolute signed links in emails). |

## Authentication & encryption (secret)
| Variable | Required | Notes |
|---|---|---|
| `JWT_SECRET` | yes | Signs access tokens. |
| `AR_ENCRYPTION_PRIMARY_KEY` | prod | Encrypts platform-setting secrets at rest. |
| `AR_ENCRYPTION_DETERMINISTIC_KEY` | prod | " |
| `AR_ENCRYPTION_KEY_DERIVATION_SALT` | prod | " |

Off-production these AR keys are derived from `secret_key_base` automatically.

## Database & Redis
| Variable | Required | Notes |
|---|---|---|
| `DATABASE_HOST` / `DATABASE_PORT` | yes | |
| `DATABASE_USERNAME` / `DATABASE_PASSWORD` | yes | **password is secret**. |
| `DATABASE_NAME` / `DATABASE_NAME_TEST` | yes / test | |
| `REDIS_URL` | yes | Sidekiq + cache/rate-limit/breaker. |
| `RACK_ATTACK_REDIS_URL` | no | Defaults to `REDIS_URL`. |
| `SIDEKIQ_CONCURRENCY` | no | Worker threads. |
| `SIDEKIQ_WEB_USER` / `SIDEKIQ_WEB_PASSWORD` | prod | Protects the Sidekiq dashboard. **secret**. |

## Storage
| Variable | Required | Notes |
|---|---|---|
| `STORAGE_BACKEND` | yes | `local` or `s3`. |
| `STORAGE_ROOT` | local | Local asset directory. |
| `S3_BUCKET` / `S3_REGION` | s3 | |
| `S3_ENDPOINT` | s3 (R2/MinIO) | Custom endpoint. |
| `S3_FORCE_PATH_STYLE` | s3 (MinIO) | `true` for path-style. |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | s3 | **secret**; or an instance role. |

## Providers (secret keys)
| Variable | Notes |
|---|---|
| `CHARACTER_IMAGE_PROVIDER` | `gemini` in prod; `fake` off-prod. |
| `GEMINI_API_KEY` | **secret**. Also settable via the admin portal. |
| `TEXT_GENERATION_PROVIDER` | `openai` in prod; `local` off-prod. |
| `SPEECH_TO_TEXT_PROVIDER` | `openai` in prod; `fake` off-prod. |
| `OPENAI_API_KEY`, `OPENAI_PROMPT_MODEL`, `OPENAI_*_TIMEOUT_SECONDS` | **secret** key. |
| `VIDEO_GENERATION_PROVIDER` | `google_labs` in prod; `fake` off-prod. |
| `GOOGLE_LABS_API_BASE_URL`, `GOOGLE_LABS_API_KEY`, `GOOGLE_LABS_WEBHOOK_SECRET` | **secret** key/secret. |

Provider keys resolve from the encrypted `PlatformSetting` first, then ENV
(Phase 13). See [providers.md](providers.md).

## Email
| Variable | Notes |
|---|---|
| `EMAIL_PROVIDER` | `letter_opener` (dev) or an SMTP/API provider (prod). |
| `MAIL_FROM` | Default From (overridable via platform settings). |
| `EMAIL_WEBHOOK_SECRET` | **secret**. Verifies delivery webhooks. |

## Reliability / observability
| Variable | Notes |
|---|---|
| `PROVIDER_CIRCUIT_THRESHOLD` | Failures before a provider circuit opens (default 5). |
| `PROVIDER_CIRCUIT_COOLDOWN_SECONDS` | Open duration before a trial call (default 30). |
| `SENTRY_DSN` | **secret**. Optional error tracking (needs the gem). |
| `APPROVAL_LINK_TTL_HOURS` | Character-approval link lifetime (default 72). |

## Frontend (build-time, Vite)
| Variable | Notes |
|---|---|
| `VITE_API_BASE_URL` | Baked at build; default `/api/v1` (same-origin via nginx). |
| `VITE_APP_NAME` | Display name. |
| `WEB_PORT` / `WEB_PORT_HOST` | Host port for the web container. |
