# AI Character Video Automation Platform — Project Requirements

## 1. Project Overview

Build a mobile application and a web-based admin portal that automate the creation of short animated AI videos featuring a animated character character.

The platform should guide a user through the complete workflow:

1. Create a project.
2. Generate exactly one animated character for that project during project initialization.
3. Request approval of the generated character image by email.
4. Allow the user to create multiple video ideas under the same project.
5. Convert each spoken or typed video idea into a production-ready 15-second video prompt using an AI text-generation API.
6. Send the generated prompt to the video-generation provider together with the project's approved character image.
7. Generate, download, store, and present the resulting videos.
8. Email completion and approval notifications to the account owner who created the project.

Each project must have exactly one primary animated character. Every video created under that project must reuse the same approved character image as its reference image.

The recipient of approval and completion emails must be the authenticated user who created the account and owns the project. Email addresses must not be hard-coded.

---

## 2. Product Goals

The platform should:

- Reduce manual work involved in generating AI baby videos.
- Maintain visual consistency by assigning exactly one approved character to each project.
- Allow each project to contain multiple video ideas and generated videos.
- Allow users to create and track multiple projects.
- Support a review and approval step before video generation.
- Generate multiple video formats suitable for Instagram Reels, TikTok, YouTube Shorts, and other social platforms.
- Notify users and administrators by email when action is required.
- Provide clear visibility into project status, failures, generated assets, and processing history.

---

## 3. Target Platforms

### 3.1 Phase 1 Web Application

The first delivery phase must provide a production-ready web application consisting of:

- A Ruby on Rails backend API.
- A React frontend.
- A web-based user portal.
- A web-based admin portal.
- Background processing for AI generation, asset processing, and emails.
- Authentication, authorization, audit logs, and provider configuration.

The Phase 1 web portal must allow users to:

- Create a new project.
- Generate the project's single animated character during initialization.
- Approve or reject the generated character. (gemini)
- Create multiple videos under the project.
- Speak or type a video idea. (using chatgpt openai's api etc)
- Generate a 15-second video prompt. (using chatgpt openai apis)
- Review and edit the prompt.
- Start video generation using the project's approved character. (google labs)
- Track generation status.
- Preview and download completed videos.
- Receive email notifications.

### 3.2 Phase 2 Mobile Applications

The second delivery phase must provide native-distribution-ready mobile applications for:

- Android.
- iOS.

The mobile applications may be implemented using:

- Flutter, or
- React Native.

The mobile applications must consume the Rails APIs created in Phase 1.

The mobile apps must be prepared for production release, including:

- Production builds.
- App icons.
- Splash screens.
- Privacy policy links.
- Terms links.
- Store screenshots.
- Store descriptions.
- Versioning.
- Signing configuration.
- Android App Bundle generation.
- iOS archive generation.
- Push-notification configuration, if included.
- Google Play Store submission readiness.
- Apple App Store submission readiness.

### 3.3 Web Admin Portal

The web admin portal should allow administrators to:

- View all users and projects.
- Create and manage projects.
- Review generated prompts.
- Review character images.
- Approve or reject character images.
- Restart failed jobs.
- View video-generation progress.
- Download generated images and videos.
- Configure recipient email addresses.
- Configure AI provider credentials.
- Review email delivery history.
- View audit logs.
- Manage reusable character profiles.
- Manage prompt templates.
- Disable or archive projects.

---

## 4. User Roles

### 4.1 Standard User

A standard user can:

- Create a project.
- Enter a video idea.
- Generate and edit a prompt.
- Request character generation.
- Upload a custom character image.
- Approve a character.
- Start video generation.
- View and download their generated assets.

### 4.2 Administrator

An administrator can:

- Access all user and project data.
- Approve or reject content.
- Manage platform settings.
- Manage AI integrations.
- Retry failed processing jobs.
- Review operational logs.
- Configure email recipients.
- Manage users and permissions.

---

## 5. Core Workflow

## 5.1 Create and Initialize Project

The user creates a new project and enters:

- Project name.
- Character name, if desired.
- Character description.
- Preferred character gender presentation.
- Outfit preferences.
- Hair preferences.
- Skin tone.
- Eye color.
- Animation style.
- Personality.
- Default language.
- Default tone.
- Target social platforms.

During initialization, the project must create exactly one animated character.

A project cannot create additional primary characters after initialization. If the user wants a different character, they must create a new project or use an explicit admin-only character reset workflow.

Default video duration:

- 15 seconds

Phase 1 only supports fixed 15-second videos.

Future phases may support configurable durations between 1 and 5 minutes. Videos longer than 5 minutes are out of scope.

Possible languages should include:

- English
- Urdu
- Roman Urdu
- Punjabi

The architecture should allow more languages to be added later.

---

## 5.2 Create a Video Idea

After the project's character has been approved, the user can create multiple video records under the project.

For each video, the user can provide an idea by:

- Typing text.
- Recording speech.
- Uploading an audio recording, if supported.

When speech is used, the system must first transcribe it into text using a speech-to-text service.

The resulting idea is stored on the video record.

## 5.3 Generate Video Prompt

The system sends the user's typed or transcribed idea to an AI text-generation API such as the OpenAI API.

The generated prompt should describe:

- The character.
- Facial expression.
- Clothing.
- Environment.
- Camera movement.
- Character movement.
- Spoken dialogue.
- Audio style.
- Lighting.
- Animation style.
- Scene timing.
- Video duration.
- Output quality.
- Vertical-video composition.

The generated prompt must target a 15-second animated video.

The user must be able to:

- Regenerate the prompt.
- Edit the prompt manually.
- Save the final prompt.
- Copy the prompt.
- View prompt version history.

### Example Prompt Structure

The prompt generator should produce content similar to:

> Create a 15-second vertical animated video featuring a cute little baby girl with a chubby face, large expressive eyes, soft cheeks, and a cheerful personality. She is wearing a colorful traditional outfit and speaking a short Urdu dialogue. Use warm lighting, smooth animation, playful facial expressions, and gentle camera movement. Keep the approved character's face, hairstyle, outfit style, and visual identity consistent throughout the video.

This is only an example. The actual prompt should be generated dynamically from the user's project details.

---

## 5.4 Character Creation

When a project is first initialized, the system must generate a character-image prompt and create exactly one primary character image for that project.

The character should normally have:

- Cute animated appearance.
- Character or toddler age.
- Chubby face.
- Large expressive eyes.
- Soft facial features.
- Friendly facial expression.
- Consistent hairstyle.
- Consistent clothing style.
- Clean background.
- Full or medium body framing.
- High-quality 3D or 2D animation style.

The user should be able to configure these attributes during project initialization:

- Gender presentation.
- Outfit.
- Hair color.
- Hair style.
- Skin tone.
- Eye color.
- Animation style.
- Background.
- Accessories.
- Personality.

The system should then use an image-generation provider to generate one or more character-image options.

The initial character image-generation provider will be **Google Gemini** (via the official Gemini API where available). Gemini is responsible only for generating the project's single reference character image.

The integration layer must remain provider-independent so another image-generation provider can be added later.

Once the character is approved:

- The character becomes permanently associated with the project.
- Every video under the project must use that exact character image as a reference image.
- The user must not be asked to generate or choose a new character for each video.
- The same character image must be attached to every provider request for video generation.

---

## 5.5 Character Confirmation

After character images are generated:

1. Save the images in platform storage.
2. Set the project status to `awaiting_character_approval`.
3. Send a confirmation email to the configured recipient.
4. Include image previews or secure links in the email.
5. Allow the recipient to approve or reject the character.
6. Record the approval decision and timestamp.

The confirmation email recipient must be the email address of the authenticated user who created and owns the project.

The confirmation email should include:

- Project name.
- Character name, if available.
- Generated character preview.
- Approve button or link.
- Reject button or link.
- Link to open the project in the web portal.
- Expiration time for the approval link.

The email approval links must be secure and single-use.

When a character is approved:

- Set its status to `approved`.
- Store it as the project's active character.
- Allow it to be reused in later projects.
- Continue to the video-generation stage.

When a character is rejected during project initialization:

- Set its status to `rejected`.
- Allow the user to enter feedback.
- Regenerate the same project's character using the feedback.
- Replace the pending character candidate.
- Send another confirmation email.

After a character has been approved and used for video generation, changing it should be disabled for normal users.

---

## 5.6 Video Generation

Once the project's character is approved and a video's prompt is approved, the system should create video-generation jobs for that video.

The video generator must receive:

- The individual video's final prompt.
- The project's approved character image.
- Requested duration.
- Requested aspect ratio.
- Resolution or quality configuration.
- Project identifier.
- Character consistency instructions.

The initial video-generation provider will be **Google Labs** (or its official API successor if Google exposes one). The system should be designed specifically around Google Labs while keeping the provider abstraction so another provider can be added later.

For every generated video, the system must conceptually perform the equivalent of:

1. Take the AI-generated video prompt.
2. Send it to the Google video-generation service.
3. Attach the project's already approved character image.
4. Apply the required aspect-ratio and variation settings.
5. Track the provider job until completion.

If an official API is not available, browser automation may be implemented as an optional adapter, isolated from the core application and clearly marked as fragile.

The normal user workflow must not require manual copying, pasting, or reattaching the character image.

---

## 5.7 Required Video Variants

For every video record created under an approved project, the system should create the following outputs:

| Variant | Aspect Ratio | Quantity |
|---|---:|---:|
| Portrait | 3:4 | 2 |
| Vertical | 9:16 | 2 |

Total expected output:

- 4 generated videos per project

Each video should:

- Be approximately 15 seconds long.
- Use the same approved character.
- Follow the approved prompt.
- Preserve facial and visual consistency.
- Be downloadable.
- Have a preview thumbnail.
- Be associated with its aspect ratio and variation number.

Suggested output naming convention:

- `{project-slug}_3x4_v1.mp4`
- `{project-slug}_3x4_v2.mp4`
- `{project-slug}_9x16_v1.mp4`
- `{project-slug}_9x16_v2.mp4`
 
---

## 5.8 Download and Storage

When generation is complete, the system should:

1. Download the generated video from the provider.
2. Validate that the file is playable.
3. Record duration, dimensions, format, and file size.
4. Generate a thumbnail.
5. Upload the video to permanent object storage.
6. Save the storage URL in the database.
7. Mark the generation job as complete.

Recommended storage:

- Amazon S3
- Google Cloud Storage
- Cloudflare R2
- Another S3-compatible object store

Files should be private by default and accessed through signed URLs.

---

## 5.9 Completion Email

After all required outputs for a video are generated, the system should send a completion email to the project owner's account email address.

The email should include:

- Project name.
- Prompt summary.
- Character preview.
- Status of all four video outputs.
- Secure download links.
- Link to open the project in the mobile application or admin portal.

Large video files should normally be shared through secure download links instead of being attached directly to the email.

The system should record:

- Email sent time.
- Delivery status.
- Recipient.
- Provider message identifier.
- Failure reason, if delivery fails.

---

## 6. Project Statuses

Each project should have one of the following statuses:

- `draft`
- `generating_prompt`
- `prompt_ready`
- `generating_character`
- `awaiting_character_approval`
- `character_rejected`
- `character_approved`
- `queued_for_video_generation`
- `generating_videos`
- `partially_completed`
- `completed`
- `failed`
- `cancelled`
- `archived`

The user interface should show a clear progress indicator based on the current status.

---

## 7. Functional Requirements

### FR-001: User Authentication

The system must support secure authentication.

Possible methods:

- Email and password.
- Google login.
- Apple login.
- Magic-link login.

### FR-002: Project Management

Users must be able to:

- Create projects.
- Initialize exactly one character per project.
- Edit projects before character approval.
- Duplicate projects as new projects with a separately initialized character.
- Archive projects.
- Delete draft projects.
- Search and filter projects.
- View project processing history.

### FR-003: Multiple Videos Per Project

Users must be able to:

- Create multiple video records under one project.
- Enter or speak a different idea for each video.
- Generate a different prompt for each video.
- Reuse the same approved project character for every video.
- View all videos belonging to a project.

### FR-004: Prompt Generation

The system must:

- Accept typed or spoken video ideas.
- Transcribe spoken ideas.
- Generate a 15-second video prompt for each video.
- Allow manual prompt editing.
- Store prompt versions.
- Allow prompt regeneration.
- Store the final approved prompt.

### FR-005: Character Generation

The system must:

- Generate character-image prompts.
- Generate one or more character images.
- Allow image upload as an alternative.
- Store generated images.
- Support regeneration based on user feedback.

### FR-006: Character Approval

The system must:

- Send approval emails.
- Support secure approve and reject links.
- Record approval history.
- Prevent unapproved characters from being used for final video generation.

### FR-007: Project Character

Each project must have exactly one approved character.

The project character profile should include:

- Name.
- Description.
- Master image.
- Additional reference images.
- Prompt used to create it.
- Visual attributes.
- Approval status.
- Owner.
- Creation date.
- Usage history across all videos in the same project.

### FR-008: Video Generation

The system must:

- Generate two 3:4 videos.
- Generate two 9:16 videos.
- Use the approved character image.
- Store provider job identifiers.
- Poll or receive webhook updates from the provider.
- Retry transient failures.
- Avoid duplicate generation jobs.

### FR-009: Video Preview

Users must be able to:

- Play generated videos.
- View thumbnails.
- See aspect ratio.
- See file size and duration.
- Download individual videos.
- Download all project videos.

### FR-010: Email Notifications

The system must send emails for:

- Character ready for approval.
- Character rejected.
- Character approved.
- Video generation started.
- Video generation completed.
- Video generation partially failed.
- Project failed.

### FR-011: Admin Configuration

Administrators must be able to configure:

- Default recipient email.
- Email sender name.
- AI text provider.
- AI image provider.
- AI video provider.
- API credentials.
- Prompt templates.
- Generation timeout.
- Retry count.
- Output formats.
- File-retention policy.

### FR-012: Job Retry

Administrators must be able to retry:

- Prompt generation.
- Character generation.
- Individual video variants.
- Email delivery.
- Asset download.

Retry operations must be idempotent and must not create duplicate completed outputs.

### FR-013: Audit Logs

The system must record:

- User actions.
- Admin actions.
- Prompt changes.
- Character approvals and rejections.
- Provider requests.
- Provider responses.
- Generation retries.
- Email activity.
- Asset downloads.

Sensitive values such as API keys must never be stored in logs.

---

## 8. Mobile Application Screens

The mobile app should include:

1. Splash screen.
2. Sign-in and registration.
3. Home dashboard.
4. Projects list.
5. Create project.
6. Video idea form.
7. Generated prompt editor.
8. Character configuration.
9. Character gallery.
10. Character approval screen.
11. Generation progress screen.
12. Project details.
13. Video player.
14. Downloads.
15. Notifications.
16. User profile.
17. Application settings.

---

## 9. Admin Portal Screens

The web admin portal should include:

1. Admin login.
2. Dashboard.
3. Users list.
4. Projects list.
5. Project detail.
6. Prompt review.
7. Character review.
8. Character library.
9. Video-generation jobs.
10. Failed jobs.
11. Email delivery logs.
12. AI provider settings.
13. Prompt-template settings.
14. Storage settings.
15. Audit logs.
16. System-health page.

---

## 10. Suggested Data Model

## 10.1 User

Fields:

- `id`
- `name`
- `email`
- `password_digest` or authentication-provider identifier
- `role`
- `status`
- `created_at`
- `updated_at`

## 10.2 Project

Fields:

- `id`
- `user_id`
- `name`
- `slug`
- `topic`
- `story`
- `dialogue`
- `language`
- `tone`
- `duration_seconds`
- `status`
- `active_character_id`
- `created_at`
- `updated_at`

## 10.3 Video

Fields:

- `id`
- `project_id`
- `title`
- `idea_text`
- `idea_audio_url`
- `transcript`
- `language`
- `tone`
- `duration_seconds`
- `status`
- `active_prompt_id`
- `created_at`
- `updated_at`

## 10.4 Prompt

Fields:

- `id`
- `video_id`
- `version`
- `prompt_type`
- `content`
- `provider`
- `provider_model`
- `status`
- `created_by`
- `created_at`
- `updated_at`

## 10.5 Character

Fields:

- `id`
- `user_id`
- `project_id`
- `name`
- `description`
- `attributes`
- `status`
- `master_image_url`
- `provider`
- `provider_job_id`
- `approved_at`
- `approved_by`
- `created_at`
- `updated_at`

## 10.6 CharacterImage

Fields:

- `id`
- `character_id`
- `file_url`
- `thumbnail_url`
- `generation_prompt`
- `status`
- `provider`
- `provider_asset_id`
- `created_at`
- `updated_at`

## 10.7 ApprovalRequest

Fields:

- `id`
- `project_id`
- `character_id`
- `recipient_email`
- `token_digest`
- `status`
- `feedback`
- `expires_at`
- `responded_at`
- `created_at`
- `updated_at`

## 10.8 VideoGeneration

Fields:

- `id`
- `video_id`
- `project_id`
- `character_id`
- `prompt_id`
- `aspect_ratio`
- `variation_number`
- `duration_seconds`
- `status`
- `provider`
- `provider_job_id`
- `provider_asset_id`
- `attempt_count`
- `error_code`
- `error_message`
- `started_at`
- `completed_at`
- `created_at`
- `updated_at`

## 10.9 VideoAsset

Fields:

- `id`
- `video_generation_id`
- `file_url`
- `thumbnail_url`
- `filename`
- `mime_type`
- `width`
- `height`
- `duration_seconds`
- `file_size`
- `checksum`
- `created_at`
- `updated_at`

## 10.10 EmailDelivery

Fields:

- `id`
- `project_id`
- `email_type`
- `recipient`
- `subject`
- `status`
- `provider_message_id`
- `error_message`
- `sent_at`
- `created_at`
- `updated_at`

## 10.11 AuditLog

Fields:

- `id`
- `actor_type`
- `actor_id`
- `action`
- `resource_type`
- `resource_id`
- `metadata`
- `ip_address`
- `created_at`

---

## 11. API Requirements

The backend should provide REST or GraphQL APIs for the mobile app and admin portal.

Suggested REST endpoints:

### Authentication

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/logout`
- `POST /api/v1/auth/refresh`

### Projects

- `GET /api/v1/projects`
- `POST /api/v1/projects`
- `GET /api/v1/projects/:id`
- `PATCH /api/v1/projects/:id`
- `DELETE /api/v1/projects/:id`
- `POST /api/v1/projects/:id/duplicate`

### Videos

- `GET /api/v1/projects/:project_id/videos`
- `POST /api/v1/projects/:project_id/videos`
- `GET /api/v1/videos/:id`
- `PATCH /api/v1/videos/:id`
- `DELETE /api/v1/videos/:id`
- `POST /api/v1/videos/:id/transcribe`

### Prompts

- `POST /api/v1/videos/:id/prompts/generate`
- `GET /api/v1/videos/:id/prompts`
- `PATCH /api/v1/prompts/:id`
- `POST /api/v1/prompts/:id/approve`

### Characters

- `POST /api/v1/projects/:id/characters/generate`
- `POST /api/v1/projects/:id/characters/upload`
- `GET /api/v1/characters`
- `GET /api/v1/characters/:id`
- `POST /api/v1/characters/:id/approve`
- `POST /api/v1/characters/:id/reject`

### Video Generation

- `POST /api/v1/videos/:id/generate`
- `GET /api/v1/videos/:id/generations`
- `GET /api/v1/video-generations/:id`
- `POST /api/v1/video-generations/:id/retry`

### Downloads

- `GET /api/v1/video-assets/:id/download`
- `GET /api/v1/projects/:id/download-all`

### Admin

- `GET /api/v1/admin/projects`
- `GET /api/v1/admin/jobs`
- `POST /api/v1/admin/jobs/:id/retry`
- `GET /api/v1/admin/email-deliveries`
- `GET /api/v1/admin/audit-logs`
- `GET /api/v1/admin/settings`
- `PATCH /api/v1/admin/settings`

### Provider Webhooks

- `POST /api/v1/webhooks/image-provider`
- `POST /api/v1/webhooks/video-provider`
- `POST /api/v1/webhooks/email-provider`

Webhook endpoints must verify provider signatures.

---

## 12. Background Processing

AI generation and email delivery must run asynchronously using a background-job system.

Suggested job types:

- `TranscribeVideoIdeaJob`
- `GenerateVideoPromptJob`
- `GenerateCharacterPromptJob`
- `GenerateCharacterImagesJob`
- `SendCharacterApprovalEmailJob`
- `ProcessCharacterApprovalJob`
- `CreateVideoGenerationBatchJob`
- `GenerateVideoVariantJob`
- `PollVideoGenerationStatusJob`
- `DownloadGeneratedVideoJob`
- `GenerateVideoThumbnailJob`
- `SendProjectCompletionEmailJob`
- `RetryFailedGenerationJob`
- `CleanExpiredAssetsJob`

Requirements:

- Jobs must be idempotent.
- Jobs must support retries.
- Jobs must record failures.
- Jobs must use exponential backoff.
- Duplicate project-generation requests must not create duplicate video variants.
- Long-running provider jobs must use polling or webhooks.
- Provider rate limits must be respected.

---

## 13. Integration Requirements

## 13.1 Text Generation Provider

Used for:

- Video prompt generation.
- Character prompt generation.
- Prompt refinement.
- Translation.
- Dialogue generation.

The provider interface should support:

- Model selection.
- System prompt.
- User prompt.
- Structured JSON output.
- Timeout.
- Retry.
- Usage tracking.

## 13.2 Image Generation Provider

Used for:

- Character generation.
- Character variations.
- Background removal, if supported.
- Reference-image generation.

The provider interface should support:

- Text prompt.
- Number of outputs.
- Aspect ratio.
- Reference image, where supported.
- Seed, where supported.
- Provider job identifier.
- Webhook or polling.

## 13.3 Video Generation Provider

Used for:

- Image-to-video generation.
- Multiple aspect ratios.
- Multiple variations.
- 15-second videos.
- Reference-image consistency.

The provider interface should support:

- Prompt.
- Character reference image.
- Duration.
- Aspect ratio.
- Resolution.
- Number of variants.
- Provider job identifier.
- Progress.
- Webhook or polling.

## 13.4 Email Provider

Possible providers:

- Amazon SES
- SendGrid
- Postmark
- Mailgun

The email integration must support:

- HTML emails.
- Transactional templates.
- Delivery tracking.
- Failure reporting.
- Secure approval links.

---

## 14. Security Requirements

- Encrypt API credentials at rest.
- Never expose provider API keys to the mobile app.
- Use short-lived signed URLs for private assets.
- Require authorization for all project and asset access.
- Use role-based access control for admin features.
- Validate uploaded file types and sizes.
- Scan uploaded files where practical.
- Verify webhook signatures.
- Rate-limit authentication and generation endpoints.
- Store approval tokens as hashes.
- Expire approval links.
- Record suspicious approval attempts.
- Avoid placing sensitive provider responses in application logs.

---

## 15. Non-Functional Requirements

### Performance

- Standard API responses should normally complete within 500 ms, excluding AI-provider processing.
- Project lists should be paginated.
- Video files should be delivered through object storage or a CDN.
- Thumbnails should load before full videos.

### Reliability

- Failed provider calls should be retried.
- Completed provider jobs must not be regenerated unnecessarily.
- The system should recover after application restarts.
- Processing state must be stored in the database.
- Email-delivery failures should be retryable.

### Scalability

The system should support:

- Multiple users.
- Multiple concurrent projects.
- Multiple AI providers.
- Queue-based processing.
- Horizontal scaling of API and worker services.
- Provider-specific rate limits.

### Observability

The system should provide:

- Structured logs.
- Error tracking.
- Job metrics.
- Provider latency metrics.
- Provider failure-rate metrics.
- Email delivery metrics.
- Storage usage metrics.
- Project-completion metrics.

---

## 16. Error Handling

The user should see clear errors for:

- Prompt generation failure.
- Character generation failure.
- Character approval link expired.
- Video provider unavailable.
- Individual video variation failed.
- Invalid downloaded video.
- Email delivery failure.
- Unsupported uploaded image.
- Provider quota exceeded.
- Provider credentials invalid.

A failure in one video variant must not automatically discard successful variants.

Projects with some successful and some failed videos should use the status:

- `partially_completed`

Administrators and users should be able to retry only the failed variants.

---

## 17. Acceptance Criteria

### AC-001: Project Creation

Given an authenticated user, when they submit valid project details, then a new project is created with status `draft` and no videos yet exist under it.

### AC-002: Character Initialization

Given a newly created project, when initialization begins, then exactly one pending project character is generated.

### AC-003: Character Uniqueness

Given an initialized project, when the user creates additional videos, then the system does not generate additional project characters.

### AC-004: Video Idea Capture

Given an approved project character, when the user types or speaks a video idea, then the system stores the idea or its transcript on a new video record.

### AC-005: Prompt Generation

Given a valid video idea, when the user requests prompt generation, then the system generates and saves a prompt for a 15-second animated baby video.

### AC-006: Prompt Editing

Given a generated prompt, when the user edits and saves it, then the edited version becomes the project's active prompt.

### AC-007: Character Generation

Given a project that requires a new character, when character generation is started, then at least one character image is created and stored.

### AC-008: Character Approval Email

Given generated character images, when generation completes, then an approval email is sent to the configured recipient.

### AC-009: Approval Enforcement

Given an unapproved character, when video generation is requested, then the system must reject the request.

### AC-010: Character Approval

Given a valid approval link, when the recipient approves the character, then the character status becomes `approved`.

### AC-011: Video Batch Creation

Given an approved prompt and character, when video generation starts, then the system creates four jobs:

- Two for 3:4.
- Two for 9:16.

### AC-012: Video Storage

Given a completed provider job, when the platform downloads the result, then the video is validated, stored, and available through a secure link.

### AC-013: Completion Email

Given all four required videos are complete, when post-processing finishes, then the system sends a completion email to the configured recipient.

### AC-014: Partial Failure

Given one or more video variants fail, when other variants complete, then successful videos remain available and the project becomes `partially_completed`.

### AC-015: Retry

Given a failed video variant, when an authorized user retries it, then only that variant is generated again.

### AC-016: Character Reuse

Given a project with an approved character, when the user creates multiple videos under that project, then every video uses the same character image automatically.

### AC-017: Auditability

Given any approval, rejection, retry, or admin action, when it occurs, then the system creates an audit-log record.

---

## 18. Phase 1 Scope: Rails API and React Web Portal

The first phase must include:

- Ruby on Rails backend APIs.
- React user portal.
- React admin portal.
- User authentication.
- Responsive web interface.
- Project creation.
- AI prompt generation.
- Prompt editing.
- Character-image generation.
- Character approval by email.
- Exactly one approved character per project.
- Multiple videos per project.
- Four generation outputs per video.
- Video storage.
- Secure downloads.
- Completion email.
- Background jobs.
- Basic retry support.
- Basic audit logs.
- Configurable recipient email.

---

## 19. Phase 2 Scope: Mobile Applications and Store Release

The second phase must include:

- Flutter or React Native mobile application.
- Android production build.
- iOS production build.
- API integration with the Rails backend.
- Mobile authentication.
- Project creation.
- Character approval.
- Spoken and typed video ideas.
- Prompt review.
- Video-generation status.
- Video preview and downloads.
- Account settings.
- Store assets and metadata.
- Google Play Store release preparation.
- Apple App Store release preparation.
- Submission support for both stores.

The applications must satisfy applicable Google Play and Apple App Store requirements at the time of release.

## 20. Future Enhancements

Possible future features:

- Automatic social-media publishing.
- Scheduling posts.
- TikTok integration.
- Instagram integration.
- YouTube Shorts integration.
- Caption generation.
- Hashtag generation.
- Voice cloning.
- Lip synchronization.
- Background music selection.
- Urdu text-to-speech.
- Multi-scene storyboards.
- Team workspaces.
- Subscription plans.
- Credit-based billing.
- Provider cost tracking.
- Analytics for video views and engagement.
- Character marketplace.
- Reusable voice profiles.
- Brand templates.
- Bulk video generation.
- A/B testing of prompts and characters.

---



## 21. Estimated AI Provider Budget

The application should track AI usage and estimated costs for every request.

### OpenAI (ChatGPT API)

Used for:

- Converting spoken ideas into structured prompts.
- Prompt refinement.
- Translation.
- Dialogue generation.

The system should record:

- Model used.
- Tokens consumed.
- Estimated request cost.
- Total project cost.

### Google Gemini API

Used for:

- Initial project character generation.
- Character regeneration after rejection.

The system should record:

- Model used.
- Number of image generations.
- Estimated API cost.
- Total project cost.

### Google Labs

Used for:

- Video generation.
- Character-reference video generation.
- Multiple aspect-ratio outputs.

The system should record:

- Number of generation jobs.
- Number of generated variants.
- Generation duration.
- Estimated provider cost.
- Total project cost.

### Cost Dashboard

The admin portal should provide:

- Total API spend.
- Spend by provider.
- Spend by project.
- Spend by user.
- Average cost per video.
- Average cost per project.
- Daily, weekly, and monthly usage.
- Configurable spending limits and alerts.

## 22. Technical Assumptions and Constraints

- Official provider APIs should be preferred over browser automation.
- The names ChatGPT, Gemini, and Google Labs describe the desired workflow, but the implementation must use supported APIs or provider integrations.
- Browser automation should only be used when legally permitted and technically necessary.
- Browser automation may break when a provider changes its interface.
- Provider terms of service, rate limits, content rules, and commercial-use restrictions must be reviewed before production launch.
- The platform must support replacing any AI provider without rewriting the main project workflow.
- Video generation may take several minutes, so all generation operations must run asynchronously.
- Email links should open a responsive web approval page even when the primary client is a mobile application.

---

## 23. Suggested Architecture

The required Phase 1 architecture is:

- Backend API: Ruby on Rails.
- User portal: React.
- Admin portal: React.
- Database: PostgreSQL.
- Background jobs: Sidekiq.
- Cache and queue: Redis.

The required Phase 2 architecture is:

- Mobile app: Flutter or React Native.
- Shared Rails APIs from Phase 1.
- Database: PostgreSQL.
- Background jobs: Sidekiq, BullMQ, Celery, or equivalent.
- Cache and queue: Redis.
- Object storage: Amazon S3 or compatible provider.
- Email: Amazon SES, Postmark, SendGrid, or Mailgun.
- Authentication: JWT or secure session-based authentication.
- Monitoring: Sentry plus application metrics.
- Deployment: Docker-based cloud deployment.

The backend should use adapter classes such as:

- `TextGenerationProvider`
- `CharacterImageProvider`
- `VideoGenerationProvider`
- `EmailProvider`
- `StorageProvider`

This will keep the core workflow independent of a specific AI vendor.

---

## 24. Recommended Implementation Order

### Phase 1

1. Set up the Rails API, PostgreSQL, Redis, and Sidekiq.
2. Set up authentication and roles.
3. Create the project, project character, video, prompt, generation, and asset models.
4. Build project creation and one-time character initialization.
5. Add Gemini or Google image-generation integration.
6. Add email-based character approval to the project owner's account email.
7. Build multiple-video-per-project support.
8. Add speech capture and transcription support.
9. Add OpenAI API prompt generation.
10. Add prompt editing and version history.
11. Add Google video-generation integration with mandatory project-character attachment.
12. Generate the four required outputs per video.
13. Add download, validation, thumbnail, and storage processing.
14. Add completion emails to the project owner.
15. Build the React user portal.
16. Build the React admin portal.
17. Add retries, audit logs, observability, and production security.

### Phase 2

1. Select Flutter or React Native.
2. Build Android and iOS applications using the Rails APIs.
3. Add mobile authentication and project workflows.
4. Add mobile speech recording and upload.
5. Add character approval and video-generation status.
6. Add video preview, sharing, and downloads.
7. Prepare production signing and release builds.
8. Prepare store icons, screenshots, descriptions, policies, and metadata.
9. Validate Google Play Store requirements.
10. Validate Apple App Store requirements.
11. Produce submission-ready Android and iOS builds.

---

## 25. Definition of Done

Phase 1 is considered complete when a user can:

1. Sign in to the React web portal.
2. Create a project.
3. Generate exactly one animated character during project initialization.
4. Receive an approval email at the account owner's email address.
5. Approve the character.
6. Create multiple videos under the same project.
7. Type or speak a separate idea for each video.
8. Generate and edit a 15-second video prompt using an AI API.
9. Start video generation without manually attaching the character.
10. Have the system automatically attach the project's approved character to every video-generation request.
11. Receive two 3:4 videos and two 9:16 videos for each video record.
12. Preview and download generated videos.
13. Receive completion emails at the project owner's account email address.

An administrator must also be able to:

1. View the project.
2. View all generation jobs.
3. Review the approved character and prompt.
4. Retry failed jobs.
5. View email-delivery records.
6. Change the recipient email.
7. Review audit logs.


## 26. App Store and Production Readiness Requirements

Before Phase 2 is considered complete, the mobile applications must be technically and operationally ready for store publication.

### Google Play Store

The Android application must include:

- Unique application identifier.
- Signed Android App Bundle.
- Production API configuration.
- Privacy policy URL.
- Data safety declaration inputs.
- Content rating information.
- Store listing title and description.
- Feature graphic.
- Application icon.
- Phone screenshots.
- Tablet screenshots where required.
- Internal testing build.
- Closed or open testing support where required.
- Crash-free production validation.

### Apple App Store

The iOS application must include:

- Unique bundle identifier.
- Distribution signing configuration.
- App Store Connect configuration.
- Production API configuration.
- Privacy policy URL.
- App privacy declaration inputs.
- Age rating information.
- Store title and description.
- Application icon.
- Required iPhone screenshots.
- Required iPad screenshots if the app supports iPad.
- TestFlight build.
- App review notes.
- Demo account details if login is required.
- Production archive suitable for App Store submission.

### Shared Release Requirements

Both applications must:

- Use HTTPS only.
- Handle expired authentication sessions.
- Provide account deletion where required.
- Provide a way to contact support.
- Display privacy policy and terms.
- Avoid exposing provider API keys.
- Use production error tracking.
- Support production environment configuration.
- Pass basic accessibility checks.
- Handle network failures gracefully.
- Avoid broken links or placeholder screens.
