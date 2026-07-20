class CreateApprovalRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :approval_requests do |t|
      t.references :project, null: false, index: true,
                   foreign_key: { on_delete: :cascade }
      t.references :character, null: false, index: true,
                   foreign_key: { on_delete: :cascade }
      # The account owner the approval belongs to.
      t.references :user, null: false, index: true,
                   foreign_key: { on_delete: :cascade }

      # Snapshot of the owner's account email at send time (for the audit trail),
      # even though the live recipient is always resolved from the current owner.
      t.string :recipient_email, null: false

      # The single-use link token is stored only as a SHA-256 digest, never in
      # the clear. The raw token lives solely in the emailed URL.
      t.string :token_digest, null: false

      t.integer :status, null: false, default: 0

      t.text :feedback

      t.datetime :expires_at, null: false
      t.datetime :responded_at

      t.timestamps
    end

    add_index :approval_requests, :token_digest, unique: true
    add_index :approval_requests, :status
    # Fast lookup / uniqueness guard for the single active (pending) request per
    # character. Partial index so approved/rejected/expired history can pile up.
    add_index :approval_requests, :character_id,
              unique: true,
              where: "status = 0",
              name: "index_approval_requests_on_pending_character"
  end
end
