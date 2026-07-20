# Google Labs Video Generation — Operations

Google Labs has **no official public API**. Phase 8 integrates it behind the
`VideoGenerationProviders::GoogleLabs` adapter, which speaks plain HTTP to a
**configurable gateway** you operate. That gateway is where the actual Google
Labs interaction lives — typically a small, isolated **browser-automation
service** — kept entirely separate from this Rails application.

## Design principles (why it's isolated)

The core platform only ever calls the adapter interface
(`create_generation` / `fetch_status` / `fetch_asset`) and receives normalized
`Result` / `StatusResult` values. It never drives a browser, holds Google
credentials, or knows the provider's response shape. This means:

- **Isolation** — the automation runs as its own service/process; if it breaks or
  is rate-limited, the Rails app degrades gracefully (variants fail and can be
  retried), it does not crash.
- **Dedicated credentials** — the Google Labs account/session lives only in the
  automation service, injected via its own secrets, never in this repo or DB.
- **Secure session storage** — the automation service persists its browser
  session/cookies in its own encrypted store; they are never returned to Rails.
- **Replaceable** — if Google ships an official API, swap the adapter's HTTP
  target (or the adapter) with no change to the rest of the pipeline.
- **No credential leakage** — the adapter sends only a bearer token to the
  gateway and never logs it; logs carry provider job ids and normalized status
  only.

## Gateway HTTP contract

The adapter expects the gateway to expose:

| Method | Path | Purpose |
|---|---|---|
| POST | `/generations` | Accept a job. Body: `{ prompt, model, duration_seconds, aspect_ratio, variation, reference_image: { mime_type, data(base64) } }`. Returns `{ id, request_id, model }`. |
| GET | `/generations/:id` | Report status: `{ status, progress, asset: { url }, error: { code, message } }`. `status` ∈ queued/running/succeeded/failed (normalized by the adapter). |
| GET | `/generations/:id/asset` | Return the finished video bytes (used by Phase 9 download). |

Authentication: `Authorization: Bearer $GOOGLE_LABS_API_KEY`.

## Status delivery: polling and/or webhook

- **Polling** — `PollVideoGenerationStatusJob` calls `GET /generations/:id` on an
  interval (`VIDEO_GENERATION_POLL_INTERVAL_SECONDS`, default 15s) up to
  `VIDEO_GENERATION_MAX_POLLS` (default 40); past that a variant is failed with
  `error_code=timeout`.
- **Webhook** — the gateway may instead POST status to
  `/api/v1/webhooks/video_generations` with an `X-Signature` header containing the
  hex HMAC-SHA256 of the raw body under `GOOGLE_LABS_WEBHOOK_SECRET`. Invalid
  signatures are rejected (401). Payload: `{ job_id, status, progress, error_code,
  error_message }` where `status` ∈ processing/completed/failed.

Both paths converge on `VideoGenerations::ApplyStatus`, so they are consistent
and idempotent.

## Environment

See `.env.example` for the full list: `VIDEO_GENERATION_PROVIDER`,
`GOOGLE_LABS_API_BASE_URL`, `GOOGLE_LABS_API_KEY`, `GOOGLE_LABS_MODEL`,
`GOOGLE_LABS_COST_USD`, `GOOGLE_LABS_TIMEOUT_SECONDS`,
`GOOGLE_LABS_WEBHOOK_SECRET`, `VIDEO_GENERATION_MAX_POLLS`,
`VIDEO_GENERATION_POLL_INTERVAL_SECONDS`.

Without `GOOGLE_LABS_API_BASE_URL` + `GOOGLE_LABS_API_KEY`, the adapter raises
`NotConfigured`. Off-production the default provider is the deterministic `fake`,
so local development and the test suite never need Google Labs.

## Phase boundary

Phase 8 tracks each output through to `completed`/`failed` at the provider.
**Downloading, validating, and permanently storing** the finished videos (and
making them playable/downloadable) is Phase 9 via `fetch_asset`.
