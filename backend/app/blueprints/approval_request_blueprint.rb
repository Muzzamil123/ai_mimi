# Public-facing view of an approval request. This is served on an UNAUTHENTICATED
# (token-protected) endpoint, so it deliberately exposes only what the approval
# page needs to render — no user ids, no internal digests, no owner email.
class ApprovalRequestBlueprint < Blueprinter::Base
  identifier :id

  field :status

  # Whether the link can still be acted on (pending and unexpired). Drives the
  # approve/reject vs. already-processed/expired states on the public page.
  field :actionable do |request|
    request.actionable?
  end

  field :feedback

  field :expires_at do |request|
    request.expires_at&.iso8601
  end

  field :responded_at do |request|
    request.responded_at&.iso8601
  end

  # Minimal project/character context for the preview card.
  field :project do |request|
    { name: request.project.name }
  end

  field :character do |request|
    {
      name: request.character.name,
      description: request.character.description,
      has_image: request.character.latest_image.present?
    }
  end
end
