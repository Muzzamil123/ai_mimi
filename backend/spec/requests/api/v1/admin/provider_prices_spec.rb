require "rails_helper"

RSpec.describe "Admin Provider Prices API", type: :request do
  let(:admin) { create(:user, :admin) }

  it_behaves_like "an admin-only endpoint", :get, "/api/v1/admin/provider_prices"

  describe "POST /api/v1/admin/provider_prices" do
    it "creates a price and audits it" do
      expect {
        post "/api/v1/admin/provider_prices",
             params: { provider_price: {
               provider: "openai", service_type: "text_generation", model: "gpt-4o",
               per_input_token: "0.00000015", per_output_token: "0.00000060"
             } },
             headers: auth_headers(admin)
      }.to change(ProviderPrice, :count).by(1).and change(AuditLog, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(AuditLog.last.action).to eq("provider_price.create")
    end

    it "rejects an unknown service_type (422)" do
      post "/api/v1/admin/provider_prices",
           params: { provider_price: { provider: "openai", service_type: "bogus" } },
           headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/admin/provider_prices/:id" do
    it "updates and audits" do
      price = create(:provider_price)
      patch "/api/v1/admin/provider_prices/#{price.id}",
            params: { provider_price: { per_input_token: "0.00000099" } },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(price.reload.per_input_token).to eq(BigDecimal("0.00000099"))
      expect(AuditLog.last.action).to eq("provider_price.update")
    end
  end

  describe "DELETE /api/v1/admin/provider_prices/:id" do
    it "deletes and audits" do
      price = create(:provider_price)
      expect {
        delete "/api/v1/admin/provider_prices/#{price.id}", headers: auth_headers(admin)
      }.to change(ProviderPrice, :count).by(-1).and change(AuditLog, :count).by(1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
