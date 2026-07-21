# Read-only view of an audit-trail entry for the admin portal.
class AuditLogBlueprint < Blueprinter::Base
  identifier :id

  fields :action, :resource_type, :resource_id, :metadata,
         :ip_address, :user_agent, :actor_type, :actor_id

  # A human label for the actor (e.g. the admin's email) without a second query
  # beyond the association Rails already resolves.
  field :actor_label do |log|
    actor = log.actor
    actor.respond_to?(:email) ? actor.email : nil
  end

  field :created_at do |log|
    log.created_at.iso8601
  end
end
