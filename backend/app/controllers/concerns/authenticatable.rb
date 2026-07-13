# Token-based authentication for API controllers. Reads a Bearer access token,
# resolves the current user, and enforces that the account is active. Include in
# the API base controller; endpoints that must be public call `skip_authentication`.
module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  class_methods do
    def skip_authentication(**options)
      skip_before_action :authenticate_user!, **options
    end
  end

  private

  def authenticate_user!
    return if current_user

    raise Auth::AuthenticationError, "Missing or invalid access token"
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = resolve_current_user
  end

  def resolve_current_user
    payload = JsonWebToken.decode(bearer_token)
    return nil unless payload && payload[:type] == "access"

    user = User.find_by(id: payload[:sub])
    user if user&.status_active?
  end

  def bearer_token
    header = request.authorization
    return nil unless header&.start_with?("Bearer ")

    header.split(" ", 2).last
  end

  def require_admin!
    raise Pundit::NotAuthorizedError unless current_user&.admin?
  end

  # Pundit uses this as the authorization subject.
  def pundit_user
    current_user
  end

  def request_context
    { user_agent: request.user_agent, ip_address: request.remote_ip }
  end
end
