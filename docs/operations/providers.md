# Provider Setup Guide

The platform integrates external providers strictly behind adapter interfaces
(swap a provider without touching the workflow). Off-production, deterministic
**fake/local** adapters run with no credentials, so the whole pipeline works in
dev/test/CI offline. This guide covers wiring the real providers for production.

Credentials resolve from the encrypted **`PlatformSetting`** (admin portal →
Settings) first, then ENV (Phase 13). Prefer the admin portal for rotation;
secrets are encrypted at rest and never displayed after saving.

## OpenAI — prompts + transcription
- Responsibilities: video-prompt generation and speech-to-text.
- Set `TEXT_GENERATION_PROVIDER=openai`, `SPEECH_TO_TEXT_PROVIDER=openai`.
- Credential: `OPENAI_API_KEY` (ENV) or the `openai_api_key` platform setting.
- Optional: `OPENAI_PROMPT_MODEL`, timeout overrides.

## Google Gemini — character image
- Responsibility: the project's single approved character image.
- Set `CHARACTER_IMAGE_PROVIDER=gemini`.
- Credential: `GEMINI_API_KEY` / `gemini_api_key` setting.

## Google Labs — video generation
- Responsibility: the four 15-second outputs per video.
- Set `VIDEO_GENERATION_PROVIDER=google_labs`.
- Config: `GOOGLE_LABS_API_BASE_URL` (the gateway/automation endpoint),
  `GOOGLE_LABS_API_KEY` / `google_labs_api_key` setting, and
  `GOOGLE_LABS_WEBHOOK_SECRET` (HMAC verification of status webhooks).
- No official public API: the adapter is an isolated, replaceable HTTP gateway;
  see [google-labs-automation.md](google-labs-automation.md) for the contract
  and browser-automation maintenance notes.

## Email
- Set `EMAIL_PROVIDER` to your transactional provider (SES/Postmark/SendGrid/
  Mailgun) and configure Action Mailer SMTP/API delivery accordingly;
  `letter_opener` is dev-only.
- `MAIL_FROM` sets the default sender (overridable in platform settings).
- `EMAIL_WEBHOOK_SECRET` verifies delivery-status webhooks.

## Object storage (S3-compatible)
- Set `STORAGE_BACKEND=s3` + `S3_BUCKET`, `S3_REGION`, credentials
  (`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` or an instance role).
- For Cloudflare R2 / MinIO set `S3_ENDPOINT` (and `S3_FORCE_PATH_STYLE=true`
  for MinIO). Objects are stored **private**; delivery stays behind the app's
  signed, expiring URLs, so a CDN can front the app without exposing keys.

## Cost & pricing
Each provider has configurable per-unit pricing (admin portal → Pricing) used
for usage/cost tracking and budgets (Phase 12). Verify the seeded default rates
against current provider pricing before relying on them for billing.

## Sandbox vs. fake vs. production
- **fake/local**: default off-production; deterministic, no network.
- **sandbox**: point real adapters at a provider's sandbox/test mode on staging.
- **production**: real keys via secrets. No automated test depends on live paid
  calls.
