# Helpers for authenticating request specs with a Bearer access token.
module AuthHelpers
  def issue_access_token(user)
    JsonWebToken.encode({ sub: user.id, role: user.role, type: "access" })
  end

  def auth_headers(user)
    { "Authorization" => "Bearer #{issue_access_token(user)}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
