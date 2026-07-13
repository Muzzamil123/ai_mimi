class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    enable_extension "citext" unless extension_enabled?("citext")

    create_table :users do |t|
      t.string :name, null: false
      t.citext :email, null: false
      t.string :password_digest, null: false
      t.integer :role, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.datetime :email_verified_at
      t.datetime :last_login_at

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
