# Shared authorization contract for admin-portal endpoints: unauthenticated
# requests get 401, authenticated non-admins get 403. Usage:
#
#   it_behaves_like "an admin-only endpoint", :get, "/api/v1/admin/users"
RSpec.shared_examples "an admin-only endpoint" do |verb, path|
  it "requires authentication (401)" do
    public_send(verb, path)
    expect(response).to have_http_status(:unauthorized)
  end

  it "forbids a non-admin (403)" do
    public_send(verb, path, headers: auth_headers(create(:user)))
    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("forbidden")
  end
end
