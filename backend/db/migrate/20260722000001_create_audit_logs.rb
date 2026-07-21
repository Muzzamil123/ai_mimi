class CreateAuditLogs < ActiveRecord::Migration[7.1]
  def change
    # Immutable record of a privileged/destructive action (Phase 11 requirement:
    # "every destructive or privileged action is audited"). The actor is
    # polymorphic — a User admin today, but the shape leaves room for system
    # actors later. There is no updated_at: rows are append-only.
    create_table :audit_logs do |t|
      # Polymorphic actor (nullable for system-originated events). Not a hard FK
      # so an audit trail survives the deletion of the actor it references.
      t.string :actor_type
      t.bigint :actor_id

      # What happened, e.g. "user.suspend", and the target it happened to.
      t.string :action, null: false
      t.string :resource_type
      t.bigint :resource_id

      # Structured, non-sensitive context (reason, changed fields, etc.). Secrets
      # must never be written here.
      t.jsonb :metadata, null: false, default: {}

      # Request provenance for the action.
      t.string :ip_address
      t.string :user_agent

      # Append-only: created_at only (see AuditLog model).
      t.datetime :created_at, null: false
    end

    add_index :audit_logs, [ :actor_type, :actor_id ]
    add_index :audit_logs, [ :resource_type, :resource_id ]
    add_index :audit_logs, :action
    add_index :audit_logs, :created_at
  end
end
