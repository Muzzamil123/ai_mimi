class CreateProviderPrices < ActiveRecord::Migration[7.1]
  def change
    # Admin-editable pricing so cost is configurable rather than hard-coded
    # permanently (Phase 12). A row keys a provider + service_type (+ optional
    # model; a null model is the default for that provider/service). Only the
    # per-unit rates relevant to the service need a value.
    create_table :provider_prices do |t|
      t.string :provider, null: false
      t.string :service_type, null: false
      t.string :model # null = default for this provider/service

      t.decimal :per_input_token, precision: 16, scale: 10
      t.decimal :per_output_token, precision: 16, scale: 10
      t.decimal :per_image, precision: 14, scale: 6
      t.decimal :per_second, precision: 14, scale: 6
      t.decimal :per_request, precision: 14, scale: 6

      t.string :currency, null: false, default: "USD"
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end

    # One price row per provider/service/model. A NULL model is treated as a
    # distinct (default) key by Postgres' NULLS NOT DISTINCT default; to make the
    # default row unique we store model as '' when absent (enforced in the model).
    add_index :provider_prices, %i[provider service_type model], unique: true
  end
end
