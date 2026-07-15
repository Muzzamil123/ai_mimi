class AddActiveCharacterForeignKeyToProjects < ActiveRecord::Migration[7.1]
  # The `active_character_id` column and its index were added in Phase 3; the
  # Character table only exists now, so the foreign key is introduced here.
  def change
    add_foreign_key :projects, :characters, column: :active_character_id, on_delete: :nullify
  end
end
