class CreateVideoStatusChanges < ActiveRecord::Migration[7.1]
  def change
    create_table :video_status_changes do |t|
      t.references :video, null: false, foreign_key: { on_delete: :cascade }
      t.references :actor, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :from_status
      t.string :to_status, null: false
      t.string :reason

      t.timestamps
    end

    add_index :video_status_changes, [ :video_id, :created_at ]
  end
end
