# One billable provider call, recorded idempotently by Usage::Record. This is
# the authoritative ledger for all cost/usage aggregation (Costs::Report) and
# budget evaluation (Budgets::Evaluate). Effectively append-only: a row is
# created once per source and only re-priced in place, never duplicated.
class ProviderUsage < ApplicationRecord
  SERVICE_TYPES = %w[character_image text_generation speech_to_text video_generation].freeze

  belongs_to :user, optional: true
  belongs_to :project, optional: true
  belongs_to :video, optional: true
  # The domain record that produced the call (Prompt / CharacterImage /
  # VideoGeneration / Video). Not a hard FK so the ledger outlives the source.
  belongs_to :source, polymorphic: true, optional: true

  validates :provider, presence: true
  validates :service_type, presence: true, inclusion: { in: SERVICE_TYPES }
  validates :currency, presence: true
  validates :estimated_cost, numericality: { greater_than_or_equal_to: 0 }

  before_validation :stamp_occurred_at, on: :create

  scope :in_period, ->(range) { where(occurred_at: range) }
  scope :for_provider, ->(provider) { provider.present? ? where(provider: provider) : all }
  scope :for_service, ->(service) { service.present? ? where(service_type: service) : all }

  # Whether the effective cost came from configured pricing, a provider-reported
  # fallback, or nothing (missing pricing) — surfaced so admins can spot gaps.
  def pricing_source
    metadata["pricing_source"]
  end

  def unpriced?
    pricing_source == "unpriced"
  end

  private

  def stamp_occurred_at
    self.occurred_at ||= Time.current
  end
end
