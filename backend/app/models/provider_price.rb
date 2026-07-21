# Admin-editable unit pricing for a provider + service (+ optional model). Cost
# is derived from these rows by Pricing::Calculate, so provider pricing can be
# updated without a deploy. A blank model is the default price for the
# provider/service; a model-specific row overrides it.
class ProviderPrice < ApplicationRecord
  RATE_COLUMNS = %i[per_input_token per_output_token per_image per_second per_request].freeze

  # Normalize a missing model to "" so the unique index has a single default row
  # per provider/service (Postgres treats NULLs as distinct).
  before_validation { self.model = model.to_s.strip }

  validates :provider, presence: true
  validates :service_type, presence: true, inclusion: { in: ProviderUsage::SERVICE_TYPES }
  validates :provider, uniqueness: { scope: %i[service_type model] }
  validates :currency, presence: true
  RATE_COLUMNS.each do |col|
    validates col, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  end

  scope :enabled, -> { where(enabled: true) }

  # The best matching enabled price: a model-specific row wins over the
  # provider/service default (blank model). Returns nil when neither exists.
  def self.lookup(provider:, service_type:, model: nil)
    rows = enabled.where(provider: provider, service_type: service_type)
    rows.find_by(model: model.to_s.strip.presence || "") ||
      (model.present? ? rows.find_by(model: "") : nil)
  end
end
