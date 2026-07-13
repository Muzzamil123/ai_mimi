# Implementation Plan
# AI Character Video Generation Platform

Version: 1.0

This implementation plan should be used together with:

- `requirements.md`
- `SRS.md`

The work is intentionally divided into large, cohesive implementation phases rather than small tickets.

Each phase should produce a runnable, testable increment of the platform.

---

# Guiding Principles

The implementation must follow these principles:

- Ruby on Rails is the backend API.
- React is used for the Phase 1 web user portal and admin portal.
- PostgreSQL stores application data.
- Redis and Sidekiq handle background processing.
- Google Gemini generates the project's single animated character image.
- OpenAI generates and refines prompts.
- Google Labs generates videos.
- Each project has exactly one approved character.
- Each project can have many videos.
- Every generated video under a project must use the project's approved character image.
- Phase 1 supports 15-second videos only.
- Future phases may support video durations from 1 to 5 minutes.
- All provider integrations must use adapter interfaces.
- No user should need to manually copy prompts or upload the same character image between providers.
- Email notifications must be sent to the project owner's account email.
- Provider usage and estimated cost must be recorded.
- Background jobs must be idempotent.
- The system must be production-deployable.

---

# Recommended Repository Structure

Use a monorepo unless there is a strong operational reason to separate repositories.

```text
/
├── backend/
│   ├── app/
│   ├── config/
│   ├── db/
│   ├── spec/
│   └── ...
├── frontend/
│   ├── src/
│   ├── public/
│   ├── tests/
│   └── ...
├── mobile/
│   └── created during Phase 2
├── infrastructure/
│   ├── docker/
│   ├── deployment/
│   └── scripts/
├── docs/
│   ├── requirements.md
│   ├── SRS.md
│   └── IMPLEMENTATION_PLAN.md
├── docker-compose.yml
├── .env.example
└── README.md
```

---

# Phase 1 — Repository, Rails API, React, and Local Development Foundation

## Objective

Create the technical foundation for the entire platform.

## Backend Work

Create a Rails API application with:

- PostgreSQL
- Redis
- Sidekiq
- Active Storage or a storage abstraction
- RSpec
- FactoryBot
- API versioning
- JSON serialization
- CORS configuration
- Environment-based configuration
- Health-check endpoint
- Structured application logging

Recommended initial endpoint:

```text
GET /api/v1/health
```

The endpoint should report:

- API status
- database connectivity
- Redis connectivity
- Sidekiq connectivity
- application version

## Frontend Work

Create a React application with:

- TypeScript
- Routing
- API client
- environment configuration
- authentication state placeholder
- application layout
- error boundary
- reusable loading state
- reusable empty state
- toast or notification system
- form library
- validation library

## Infrastructure Work

Create:

- Dockerfile for Rails
- Dockerfile for React
- Docker Compose configuration
- PostgreSQL service
- Redis service
- Sidekiq service
- local object-storage option if useful
- `.env.example`
- setup scripts
- database initialization scripts

## Testing

Add:

- backend test command
- frontend test command
- linting
- formatting
- CI workflow
- smoke test for health endpoint

## Definition of Done

- A developer can clone the repository and start the full stack locally.
- Rails, React, PostgreSQL, Redis, and Sidekiq run together.
- The frontend can call the Rails health endpoint.
- CI runs backend and frontend tests.
- Setup instructions are documented.

---

# Phase 2 — Authentication, Authorization, Accounts, and Roles

## Objective

Implement secure user accounts and platform roles.

## Backend Work

Create the following models:

### User

Suggested fields:

- id
- name
- email
- encrypted_password
- role
- status
- email_verified_at
- last_login_at
- created_at
- updated_at

Roles:

- user
- admin

Statuses:

- active
- suspended
- deleted

Implement:

- registration
- login
- logout
- password reset
- email verification
- token refresh if JWT is used
- account profile
- account deletion request
- authorization policies
- admin-only endpoints

Choose either:

- secure cookie-based sessions, or
- JWT access and refresh tokens

The chosen authentication mechanism must work for both React and future mobile clients.

## Frontend Work

Create:

- registration screen
- login screen
- forgot-password screen
- reset-password screen
- email-verification screen
- profile screen
- session-expired handling
- protected routes
- admin-protected routes

## API Endpoints

Suggested endpoints:

```text
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/logout
POST /api/v1/auth/refresh
POST /api/v1/auth/password/forgot
POST /api/v1/auth/password/reset
POST /api/v1/auth/email/verify
GET  /api/v1/me
PATCH /api/v1/me
DELETE /api/v1/me
```

## Testing

Test:

- registration
- duplicate email handling
- login
- invalid credentials
- password reset
- authorization
- admin access restrictions
- account suspension
- session expiration

## Definition of Done

- Users can create and access accounts securely.
- Admin-only routes are protected.
- The authentication design is reusable by mobile applications.
- Account email is available for project notifications.

---

# Phase 3 — Project Domain and Project Lifecycle

## Objective

Implement project management and the one-character-per-project rule.

## Backend Work

Create the `Project` model.

Suggested fields:

- id
- user_id
- name
- slug
- description
- default_language
- default_tone
- target_platforms
- status
- active_character_id
- archived_at
- created_at
- updated_at

Suggested statuses:

- draft
- initializing_character
- awaiting_character_approval
- character_rejected
- ready
- failed
- archived

Implement validations:

- project belongs to a user
- project owner cannot be changed normally
- project may have only one active character
- videos cannot be generated until the project is ready

Implement:

- create project
- update draft project
- archive project
- restore archived project
- delete draft project
- list projects
- search projects
- pagination
- project status history

## Frontend Work

Create:

- user dashboard
- projects list
- create project flow
- edit project form
- project details shell
- project status badge
- archive confirmation
- pagination and filters

## API Endpoints

```text
GET    /api/v1/projects
POST   /api/v1/projects
GET    /api/v1/projects/:id
PATCH  /api/v1/projects/:id
DELETE /api/v1/projects/:id
POST   /api/v1/projects/:id/archive
POST   /api/v1/projects/:id/restore
```

## Testing

Test:

- ownership
- status transitions
- archive behavior
- invalid project access
- pagination
- search
- deletion rules

## Definition of Done

- Users can create and manage projects.
- Project ownership is enforced.
- A project cannot proceed to video generation before character approval.
- Project statuses are visible in the UI.

---

# Phase 4 — Gemini Character Generation and Project Initialization

## Objective

Generate exactly one animated character for each project using Google Gemini.

## Backend Work

Create:

### Character

Suggested fields:

- id
- project_id
- name
- description
- attributes
- status
- provider
- provider_model
- provider_job_id
- generation_prompt
- approved_at
- rejected_at
- locked_at
- created_at
- updated_at

### CharacterImage

Suggested fields:

- id
- character_id
- storage_key
- original_filename
- mime_type
- width
- height
- file_size
- checksum
- provider_asset_id
- created_at
- updated_at

Character statuses:

- pending
- generating
- awaiting_approval
- rejected
- approved
- failed

Create a provider interface:

```ruby
module CharacterImageProviders
  class Base
    def generate(prompt:, options:); end
  end
end
```

Implement:

```text
CharacterImageProviders::Gemini
```

The provider adapter must support:

- character prompt
- style preferences
- response parsing
- error normalization
- provider request ID
- model used
- estimated cost
- generated asset download

Create jobs:

- GenerateCharacterPromptJob
- GenerateCharacterImageJob
- DownloadCharacterImageJob
- SendCharacterApprovalEmailJob

Rules:

- only one active character may exist per project
- regeneration is allowed before approval
- approved character is locked for normal users
- administrator may reset a character through an audited operation
- project status must follow character status

## Frontend Work

Create:

- character setup form
- character attributes form
- generation-progress view
- character preview
- rejection feedback form
- regenerate action
- approval status view

## Testing

Test:

- one-character-per-project validation
- duplicate job protection
- failed provider response
- character regeneration before approval
- immutable approved character
- provider timeout
- storage failure
- project status synchronization

## Definition of Done

- A project can generate one character through Gemini.
- The character image is stored securely.
- Duplicate character generation is prevented.
- The project enters an approval state after successful generation.

---

# Phase 5 — Email Approval Workflow

## Objective

Allow the account owner to approve or reject the generated character securely through email.

## Backend Work

Create:

### ApprovalRequest

Suggested fields:

- id
- project_id
- character_id
- user_id
- recipient_email
- token_digest
- status
- feedback
- expires_at
- responded_at
- created_at
- updated_at

Statuses:

- pending
- approved
- rejected
- expired
- cancelled

Create secure single-use approval links.

Implement:

- approval token generation
- token hashing
- expiration
- approve action
- reject action
- rejection feedback
- duplicate-click handling
- audit logging
- project state update
- character state update

Create email templates for:

- character ready for approval
- character approved
- character rejected
- approval link expired

The recipient must always come from the project owner's current account email.

## Frontend Work

Create public but token-protected pages:

- character approval page
- character rejection page
- expired-link page
- already-processed page

Create authenticated project pages that reflect the approval result.

## API Endpoints

```text
GET  /api/v1/approvals/character/:token
POST /api/v1/approvals/character/:token/approve
POST /api/v1/approvals/character/:token/reject
```

## Testing

Test:

- valid approval
- valid rejection
- expired token
- reused token
- token tampering
- account email recipient
- state transitions
- email failure and retry

## Definition of Done

- The project owner receives the character approval email.
- The user can approve or reject from the secure link.
- Approved characters become locked.
- Rejected characters can be regenerated in the same project.

---

# Phase 6 — Video Workspace, Typed Ideas, and Speech Input

## Objective

Allow users to create many videos under a project and provide an idea by typing or speaking.

## Backend Work

Create:

### Video

Suggested fields:

- id
- project_id
- title
- idea_text
- idea_audio_storage_key
- transcript
- language
- tone
- duration_seconds
- status
- active_prompt_id
- created_at
- updated_at

Phase 1 duration validation:

- duration_seconds must equal 15

Future duration validation:

- between 60 and 300 seconds when enabled

Suggested statuses:

- draft
- transcribing
- idea_ready
- generating_prompt
- prompt_ready
- queued
- generating
- partially_completed
- completed
- failed
- cancelled

Implement:

- create video
- update video idea
- upload audio
- transcribe audio
- delete draft video
- list project videos
- pagination
- status history

Create speech provider abstraction:

```ruby
module SpeechToTextProviders
  class Base
    def transcribe(file:, language:); end
  end
end
```

Use a supported transcription provider such as OpenAI speech-to-text unless another provider is selected.

Create jobs:

- TranscribeVideoIdeaJob
- ProcessVideoAudioUploadJob

## Frontend Work

Create:

- video list in project
- create-video form
- text idea input
- browser audio recorder
- audio upload
- transcription progress
- transcript editor
- video details page

Supported languages must include:

- English
- Urdu
- Roman Urdu
- Punjabi

## Testing

Test:

- multiple videos per project
- project ownership
- no video before character approval
- audio upload validation
- transcription failure
- transcript editing
- 15-second duration enforcement

## Definition of Done

- A ready project can contain multiple videos.
- A user can type or speak a separate idea for each video.
- Speech is transcribed and editable.
- Each video keeps its own idea and transcript.

---

# Phase 7 — OpenAI Prompt Generation and Prompt Versioning

## Objective

Generate a production-ready video prompt from each video's idea.

## Backend Work

Create:

### Prompt

Suggested fields:

- id
- video_id
- version
- content
- source_idea
- provider
- provider_model
- provider_request_id
- input_tokens
- output_tokens
- estimated_cost
- status
- created_by_type
- created_by_id
- created_at
- updated_at

Statuses:

- generating
- draft
- approved
- failed
- superseded

Create provider interface:

```ruby
module TextGenerationProviders
  class Base
    def generate_video_prompt(idea:, context:, options:); end
  end
end
```

Implement:

```text
TextGenerationProviders::OpenAI
```

The prompt-generation context must include:

- project's character description
- video's idea
- transcript
- language
- tone
- 15-second duration
- camera direction
- visual direction
- character movement
- dialogue
- audio style
- target platform
- character-consistency instruction
- requirement to use the attached character image

Implement:

- generate prompt
- regenerate prompt
- edit prompt
- save new version
- approve prompt
- mark previous versions superseded
- usage tracking
- error handling
- provider request logging without secrets

Create jobs:

- GenerateVideoPromptJob
- RegenerateVideoPromptJob

## Frontend Work

Create:

- prompt generation screen
- prompt editor
- prompt history
- compare versions
- regenerate action
- approve prompt action
- copy button for convenience, though copying is not required for normal processing

## Testing

Test:

- prompt generation
- version increment
- active prompt selection
- token usage recording
- provider failure
- unauthorized edits
- prompt approval
- no generation without idea

## Definition of Done

- Each video can have multiple prompt versions.
- One prompt is active and approved.
- OpenAI usage and estimated cost are recorded.
- The approved prompt is ready for automated video generation.

---

# Phase 8 — Google Labs Video Generation Adapter

## Objective

Generate four 15-second outputs for each video using Google Labs and the project's approved character.

## Backend Work

Create:

### VideoGeneration

Suggested fields:

- id
- video_id
- project_id
- character_id
- prompt_id
- aspect_ratio
- variation_number
- duration_seconds
- provider
- provider_model
- provider_job_id
- provider_request_id
- status
- attempt_count
- progress
- estimated_cost
- error_code
- error_message
- started_at
- completed_at
- created_at
- updated_at

Required generation records per video:

- 3:4 variation 1
- 3:4 variation 2
- 9:16 variation 1
- 9:16 variation 2

Create provider interface:

```ruby
module VideoGenerationProviders
  class Base
    def create_generation(prompt:, reference_image:, options:); end
    def fetch_status(job_id:); end
    def fetch_asset(job_id:); end
  end
end
```

Implement:

```text
VideoGenerationProviders::GoogleLabs
```

The adapter must always receive:

- approved prompt
- project's approved character image
- aspect ratio
- variation number
- duration of 15 seconds
- provider-specific generation settings

If no official Google Labs API is available, implement the integration behind a separate automation adapter.

Browser automation must:

- be isolated from the core application
- use dedicated credentials
- use secure session storage
- be replaceable later
- expose normalized job states
- avoid leaking credentials
- include clear operational documentation

Create jobs:

- CreateVideoGenerationBatchJob
- SubmitVideoGenerationJob
- PollVideoGenerationStatusJob
- HandleVideoGenerationWebhookJob
- RetryVideoGenerationJob

Implement idempotency keys.

A repeated generation request must not create duplicate active jobs for the same:

- video
- prompt
- character
- aspect ratio
- variation

## Frontend Work

Create:

- generation confirmation screen
- generation progress grid
- output status cards
- partial failure display
- retry failed output
- cancel generation where supported

## Testing

Test:

- exactly four generation records
- mandatory character attachment
- mandatory approved prompt
- mandatory approved character
- duplicate request prevention
- partial completion
- provider polling
- webhook verification
- retry behavior
- timeout handling
- rate-limit handling

## Definition of Done

- A user can start generation from an approved prompt.
- Four provider jobs are created.
- Every job uses the project's approved character image.
- Successful and failed variants are tracked independently.
- Phase 1 generates 15-second outputs only.

---

# Phase 9 — Asset Download, Validation, Storage, and Delivery

## Objective

Download generated videos, validate them, store them permanently, and make them securely downloadable.

## Backend Work

Create:

### VideoAsset

Suggested fields:

- id
- video_generation_id
- storage_key
- filename
- mime_type
- width
- height
- duration_seconds
- file_size
- checksum
- thumbnail_storage_key
- validation_status
- created_at
- updated_at

Implement:

- provider asset download
- file-type validation
- playable-video validation
- duration validation
- aspect-ratio validation
- checksum calculation
- thumbnail generation
- permanent upload
- signed download URLs
- download-all archive
- duplicate asset detection

Create jobs:

- DownloadGeneratedVideoJob
- ValidateGeneratedVideoJob
- GenerateVideoThumbnailJob
- StoreGeneratedVideoJob
- BuildProjectDownloadArchiveJob

## Frontend Work

Create:

- video player
- thumbnail grid
- output metadata
- individual download
- download all outputs
- signed URL refresh
- failed asset-processing display

## Testing

Test:

- invalid video
- incorrect duration
- incorrect aspect ratio
- storage failure
- signed URL expiration
- duplicate asset
- archive download
- unauthorized access

## Definition of Done

- Completed provider outputs are stored permanently.
- Videos are playable from the portal.
- Users can securely download individual outputs or all outputs.
- Metadata and thumbnails are available.

---

# Phase 10 — Notifications and Completion Emails

## Objective

Provide reliable project and video notifications.

## Backend Work

Create:

### EmailDelivery

Suggested fields:

- id
- user_id
- project_id
- video_id
- email_type
- recipient
- subject
- provider
- provider_message_id
- status
- error_message
- sent_at
- delivered_at
- created_at
- updated_at

Implement emails for:

- character ready for approval
- character approved
- character rejected
- prompt ready
- video generation started
- video generation partially completed
- video generation completed
- video generation failed
- account and security emails

Completion emails should include:

- project name
- video title
- character preview
- output status
- secure portal link
- signed download links where appropriate

The recipient must always be the current account email of the project owner.

Create jobs:

- SendCharacterApprovalEmailJob
- SendVideoGenerationStartedEmailJob
- SendVideoCompletionEmailJob
- RetryEmailDeliveryJob

## Frontend Work

Create:

- notification center
- unread count
- notification preferences
- email history view where appropriate

## Testing

Test:

- owner email resolution
- delivery retries
- duplicate email prevention
- partial-completion email
- failed-generation email
- provider webhook processing

## Definition of Done

- Users receive all required workflow emails.
- Emails are tracked.
- Failed deliveries can be retried.
- No hard-coded recipient exists.

---

# Phase 11 — Admin Portal and Operational Controls

## Objective

Build a complete web admin portal.

## Backend Work

Implement admin APIs for:

- users
- projects
- characters
- videos
- prompts
- video generations
- assets
- email deliveries
- provider requests
- usage records
- audit logs
- platform settings

Admin actions:

- suspend user
- reactivate user
- inspect project
- retry character generation
- retry prompt generation
- retry video variant
- retry asset processing
- retry email
- reset approved character with reason
- archive project
- cancel stuck job
- update platform configuration

All admin actions must be audited.

## Frontend Work

Create admin modules:

- admin dashboard
- user management
- project explorer
- character review
- video explorer
- generation jobs
- failed jobs
- email delivery logs
- provider usage
- audit logs
- configuration
- health status

## Testing

Test:

- admin authorization
- audited actions
- retry behavior
- user suspension
- character reset
- settings access
- no cross-user data leakage

## Definition of Done

- Administrators can operate and troubleshoot the platform without direct database access.
- Sensitive provider secrets are never displayed after saving.
- Every destructive or privileged action is audited.

---

# Phase 12 — Cost Tracking, Usage Limits, and Budget Controls

## Objective

Track and control spending across OpenAI, Gemini, and Google Labs.

## Backend Work

Create:

### ProviderUsage

Suggested fields:

- id
- user_id
- project_id
- video_id
- provider
- service_type
- model
- provider_request_id
- units
- input_tokens
- output_tokens
- generated_images
- generated_seconds
- estimated_cost
- currency
- metadata
- occurred_at
- created_at

Create:

### BudgetPolicy

Suggested fields:

- id
- scope_type
- scope_id
- provider
- daily_limit
- monthly_limit
- warning_percentage
- action_on_limit
- enabled
- created_at
- updated_at

Implement:

- provider pricing configuration
- usage aggregation
- project cost
- user cost
- daily cost
- monthly cost
- average cost per video
- average cost per project
- budget warnings
- hard limits
- soft limits
- admin override
- usage exports

Because provider pricing can change, pricing must be configurable rather than hard-coded permanently.

## Frontend Work

Create:

- admin cost dashboard
- charts by provider
- user spend table
- project spend table
- budget configuration
- warning banners
- cost estimate before video generation

## Testing

Test:

- cost aggregation
- budget threshold
- hard-limit prevention
- admin override
- missing provider pricing
- estimated cost updates

## Definition of Done

- Every billable provider call creates a usage record.
- Admin can see spend by provider, project, user, and date.
- Budget alerts and limits work.
- Users can see estimated generation cost before submitting.

---

# Phase 13 — Security, Auditability, Reliability, and Observability

## Objective

Prepare the platform for production use.

## Backend Work

Implement:

- secure secret storage
- encrypted provider credentials
- rate limiting
- request IDs
- structured logs
- PII-safe logs
- webhook signature verification
- file-upload restrictions
- signed URLs
- token expiration
- audit logs
- account deletion workflow
- data-retention policies
- database backups
- Redis persistence strategy
- Sidekiq dead-job handling
- circuit breakers for providers
- retry backoff
- provider timeout configuration
- health and readiness endpoints
- metrics
- error tracking

Create:

### AuditLog

Suggested fields:

- id
- actor_type
- actor_id
- action
- resource_type
- resource_id
- metadata
- ip_address
- user_agent
- created_at

## Frontend Work

Implement:

- permission-aware UI
- generic error screens
- maintenance mode
- accessibility improvements
- session-expiration handling
- network retry UX
- privacy and terms links
- account deletion UI

## Testing

Add:

- security request specs
- authorization coverage
- rate-limit tests
- webhook verification tests
- signed URL tests
- dependency scanning
- static analysis
- container vulnerability scanning
- end-to-end happy-path test

## Definition of Done

- The platform passes a production-readiness review.
- Critical operations are observable.
- Security controls are documented.
- Audit coverage exists for sensitive actions.
- Failure recovery procedures are documented.

---

# Phase 14 — Production Deployment and Release Readiness

## Objective

Deploy Phase 1 to a production environment.

## Infrastructure Work

Prepare:

- production Docker images
- Rails web service
- Sidekiq worker service
- React hosting
- PostgreSQL
- Redis
- object storage
- CDN
- email provider
- domain and TLS
- environment secrets
- database migrations
- backup policy
- monitoring
- alerts
- log aggregation
- deployment rollback

Recommended environments:

- local
- test
- staging
- production

## Documentation

Create:

- deployment guide
- rollback guide
- environment-variable reference
- provider setup guide
- admin operations guide
- incident guide
- backup and restore guide
- browser-automation maintenance guide if required

## Release Validation

Run:

- full test suite
- smoke test
- end-to-end test
- character generation test
- approval email test
- prompt generation test
- four-output video test
- asset download test
- budget tracking test
- backup test
- rollback test

## Definition of Done

- Phase 1 is deployed.
- A real user can complete the full workflow.
- Monitoring and alerts are active.
- Rollback is verified.
- Production documentation is complete.

---

# Phase 15 — Flutter or React Native Mobile Foundation

## Objective

Create the Phase 2 mobile application using the Rails APIs.

Flutter is preferred unless React Native provides a stronger project-specific advantage.

## Mobile Work

Implement:

- application foundation
- environment configuration
- API client
- authentication
- secure token storage
- routing
- state management
- error handling
- analytics
- crash reporting
- app theme
- accessibility baseline
- localization foundation

## Mobile Screens

Create:

- splash
- registration
- login
- dashboard
- projects
- project details
- character approval
- videos
- create video
- audio recorder
- transcription editor
- prompt editor
- generation progress
- video player
- downloads
- notifications
- profile
- settings
- account deletion

## Testing

Add:

- unit tests
- widget/component tests
- API integration tests
- device smoke tests

## Definition of Done

- Android and iOS development builds work.
- Core Phase 1 workflows are available on mobile.
- The same Rails APIs are used.
- No provider API keys are included in the application.

---

# Phase 16 — Mobile Production Hardening and Store Submission

## Objective

Prepare Android and iOS applications for publication.

## Android Work

Prepare:

- application ID
- signing keys
- Android App Bundle
- production API environment
- app icon
- adaptive icon
- splash screen
- feature graphic
- phone screenshots
- tablet screenshots where required
- privacy policy
- data safety information
- content rating
- internal testing release
- closed testing release if required
- production release notes

## iOS Work

Prepare:

- bundle identifier
- distribution certificate
- provisioning profiles
- App Store Connect record
- production API environment
- app icon
- launch screen
- iPhone screenshots
- iPad screenshots if supported
- privacy declarations
- age rating
- TestFlight release
- app review notes
- demo account
- production archive

## Shared Work

Validate:

- HTTPS only
- account deletion
- privacy policy
- terms
- support contact
- no placeholder content
- graceful offline behavior
- permission explanations
- production analytics
- crash reporting
- session recovery
- accessibility
- app-link/deep-link behavior

## Definition of Done

- Signed Android and iOS release builds exist.
- Store metadata and screenshots are complete.
- Applications are ready for Google Play and Apple App Store submission.
- Submission steps are documented.

---

# Cross-Phase Testing Strategy

## Backend

Use:

- model specs
- service specs
- request specs
- job specs
- policy specs
- provider adapter contract tests
- webhook tests

## Frontend

Use:

- component tests
- form validation tests
- API mocking
- route protection tests
- end-to-end tests

## Mobile

Use:

- unit tests
- widget/component tests
- integration tests
- device smoke tests

## Provider Testing

Each provider adapter should support:

- real production mode
- sandbox mode when available
- fake mode for local development
- deterministic test fixtures

No automated test suite should depend on live paid provider calls by default.

---

# Recommended Implementation Agent Workflow

The implementation agent should work phase by phase.

For each phase:

1. Read `requirements.md`.
2. Read `SRS.md`.
3. Read this phase in `IMPLEMENTATION_PLAN.md`.
4. Inspect the existing codebase.
5. Produce a concise implementation plan for the phase.
6. Implement the complete phase.
7. Run tests and linters.
8. Fix failures.
9. Update documentation.
10. Summarize completed work and any unresolved limitations.

The implementation agent should not:

- build later phases prematurely
- introduce provider-specific logic directly into controllers
- hard-code API credentials
- hard-code notification email addresses
- bypass approval rules
- create multiple project characters
- generate video without attaching the approved character
- silently ignore failed jobs
- depend on live paid APIs in automated tests

---

# Final Phase 1 Acceptance Scenario

A Phase 1 release is acceptable when the following works end-to-end:

1. A user registers.
2. The user creates a project.
3. Gemini generates exactly one animated character.
4. The image is stored.
5. An approval email is sent to the user's account email.
6. The user approves the character.
7. The project becomes ready.
8. The user creates multiple video records.
9. For each video, the user types or speaks an idea.
10. Speech is transcribed when used.
11. OpenAI generates a 15-second video prompt.
12. The user reviews and approves the prompt.
13. Google Labs receives the prompt and the project's character image.
14. The system creates two 3:4 outputs and two 9:16 outputs.
15. Videos are downloaded and validated.
16. Videos are stored securely.
17. Usage and estimated costs are recorded.
18. A completion email is sent to the project owner.
19. The user previews and downloads the videos.
20. Administrators can inspect and retry failed operations.

---

# Final Phase 2 Acceptance Scenario

A Phase 2 release is acceptable when:

1. The same workflow is available through Android and iOS applications.
2. Mobile applications use the Rails backend.
3. Users can record spoken ideas.
4. Users can approve characters.
5. Users can monitor video generation.
6. Users can preview and download videos.
7. Android and iOS release builds are signed.
8. Store metadata is complete.
9. The applications are ready for Google Play Store and Apple App Store submission.
