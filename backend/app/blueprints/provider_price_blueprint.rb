class ProviderPriceBlueprint < Blueprinter::Base
  identifier :id

  fields :provider, :service_type, :model, :currency, :enabled

  ProviderPrice::RATE_COLUMNS.each do |col|
    field col do |price|
      price.public_send(col)&.to_s
    end
  end

  field :updated_at do |price|
    price.updated_at.iso8601
  end
end
