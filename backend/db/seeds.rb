# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# --- Default provider pricing (Phase 12) -------------------------------------
# Configurable defaults so cost tracking works out of the box; admins can edit
# these in the portal. Idempotent upsert keyed by provider/service/model.
# Rates are illustrative starting points — verify against current provider
# pricing before relying on them for billing.
[
  { provider: "openai", service_type: "text_generation", model: "",
    per_input_token: "0.00000015", per_output_token: "0.00000060" },
  { provider: "openai", service_type: "speech_to_text", model: "",
    per_second: "0.0001" },
  { provider: "gemini", service_type: "character_image", model: "",
    per_image: "0.04" },
  { provider: "google_labs", service_type: "video_generation", model: "",
    per_second: "0.05" }
].each do |attrs|
  price = ProviderPrice.find_or_initialize_by(
    provider: attrs[:provider], service_type: attrs[:service_type], model: attrs[:model]
  )
  price.update!(attrs)
end
