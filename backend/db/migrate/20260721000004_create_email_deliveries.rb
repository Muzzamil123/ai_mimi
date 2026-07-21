class CreateEmailDeliveries < ActiveRecord::Migration[7.1]
  def change
    create_table :email_deliveries do |t|
      # The account owner the email was sent to. project/video give context for
      # the notification center; both nullable (account/security emails have no
      # project).
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :project, foreign_key: { on_delete: :nullify }
      t.references :video, foreign_key: { on_delete: :nullify }

      t.string :email_type, null: false
      t.string :recipient, null: false
      t.string :subject
      t.string :provider
      t.string :provider_message_id
      t.integer :status, null: false, default: 0
      t.text :error_message

      t.datetime :sent_at
      t.datetime :delivered_at
      # Set when the owner has seen this in the notification center.
      t.datetime :read_at

      # Prevents duplicate workflow emails for the same event (e.g. one
      # "completed" email per generation run).
      t.string :dedupe_key

      t.timestamps
    end

    add_index :email_deliveries, [ :user_id, :created_at ]
    add_index :email_deliveries, :provider_message_id
    add_index :email_deliveries, :dedupe_key, unique: true

    add_column :users, :notification_preferences, :jsonb, null: false, default: {}
  end
end
