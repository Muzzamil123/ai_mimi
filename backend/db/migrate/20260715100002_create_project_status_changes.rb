class CreateProjectStatusChanges < ActiveRecord::Migration[7.1]
  def change
    create_table :project_status_changes do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      # Nullable (system transitions have no actor) and nullified on user delete
      # so removing an admin who acted on another user's project won't fail.
      t.references :actor, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :from_status
      t.string :to_status, null: false
      t.string :reason

      t.timestamps
    end
  end
end
