module Admin
  # Writes a single immutable AuditLog row. This is the one place audit records
  # are created; the Auditable controller concern calls it with the request
  # context so every privileged action captures who, what, where, and why.
  # Secrets must never be passed in metadata — callers redact first.
  class RecordAudit < ApplicationService
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
