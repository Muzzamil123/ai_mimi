# Renders the standard authentication response: the user plus a token bundle.
module TokenResponder
  extend ActiveSupport::Concern

  private

  def render_auth(user, tokens, status: :ok)
    render json: {
      user: UserBlueprint.render_as_hash(user),
      tokens: {
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token,
        token_type: tokens.token_type,
        expires_in: tokens.expires_in
      }
    }, status: status
  end
end
