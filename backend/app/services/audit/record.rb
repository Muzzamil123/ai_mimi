module Audit
  # Writes a single immutable AuditLog row — the one place audit records are
  # created. The Auditable controller concern calls it with the request context
  # so every recorded action captures who, what, which resource, and from where.
  # Secrets must never be passed in metadata — callers redact first.
  class Record < ApplicationService
    def initialize(actor:, action:, resource: nil, metadata: {}, request_context: {})
      @actor = actor
      @action = action.to_s
      @resource = resource
      @metadata = (metadata || {}).deep_stringify_keys
      @request_context = request_context || {}
    end

    def call
      AuditLog.create!(
        actor: @actor,
        action: @action,
        resource_type: resource_type,
        resource_id: resource_id,
        metadata: @metadata,
        ip_address: @request_context[:ip_address],
        user_agent: @request_context[:user_agent]
      )
    end

    private

    def resource_type
      return @resource if @resource.is_a?(String)

      @resource&.class&.name
    end

    def resource_id
      return nil if @resource.nil? || @resource.is_a?(String)

      @resource.try(:id)
    end
  end
end
