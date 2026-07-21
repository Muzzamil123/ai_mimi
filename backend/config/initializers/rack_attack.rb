# Rate limiting / brute-force protection.
# The counter store is shared Redis in real environments so limits are enforced
# across every web process (Phase 13). Tests use a per-process memory store (and
# Rack::Attack is disabled there anyway) to stay hermetic.
class Rack::Attack
  cache.store =
    if Rails.env.test?
      ActiveSupport::Cache::MemoryStore.new
    else
      ActiveSupport::Cache::RedisCacheStore.new(
        url: ENV.fetch("RACK_ATTACK_REDIS_URL", ENV.fetch("REDIS_URL", "redis://localhost:6379/0")),
        namespace: "rack_attack",
        error_handler: ->(method:, returning:, exception:) {
          Rails.logger.warn(message: "rack_attack_cache_error", method: method, error: exception.class.name)
        }
      )
    end

  throttle("auth/login/ip", limit: 10, period: 60) do |req|
    req.ip if req.post? && req.path == "/api/v1/auth/login"
  end

  throttle("auth/register/ip", limit: 10, period: 3600) do |req|
    req.ip if req.post? && req.path == "/api/v1/auth/register"
  end

  throttle("auth/refresh/ip", limit: 60, period: 60) do |req|
    req.ip if req.post? && req.path == "/api/v1/auth/refresh"
  end

  throttle("auth/password_forgot/ip", limit: 5, period: 3600) do |req|
    req.ip if req.post? && req.path == "/api/v1/auth/password/forgot"
  end

  throttle("auth/email_verify/ip", limit: 20, period: 3600) do |req|
    req.ip if req.post? && req.path == "/api/v1/auth/email/verify"
  end

  # Public, token-protected character-approval links. Throttle by IP to blunt
  # token guessing/brute force (tokens are 48-byte random, but defence in depth).
  throttle("approvals/character/ip", limit: 30, period: 60) do |req|
    req.ip if req.path.start_with?("/api/v1/approvals/character/")
  end

  # Provider video-generation webhook. Signature-verified in the controller, but
  # throttle by IP as defence in depth against a flood of forged/replayed calls.
  throttle("webhooks/video_generations/ip", limit: 120, period: 60) do |req|
    req.ip if req.post? && req.path == "/api/v1/webhooks/video_generations"
  end

  # Email-provider delivery-status webhook (signature-verified; throttle as
  # defence in depth against forged/replayed floods).
  throttle("webhooks/email_deliveries/ip", limit: 240, period: 60) do |req|
    req.ip if req.post? && req.path == "/api/v1/webhooks/email_deliveries"
  end

  # Public, token-gated asset/thumbnail/archive downloads. Throttle by IP to blunt
  # token brute force (tokens are signed + expiring, but defence in depth).
  throttle("downloads/ip", limit: 120, period: 60) do |req|
    req.ip if req.get? && req.path == "/api/v1/downloads"
  end

  # Video generation is the most expensive operation (four provider renders per
  # request). Throttle batch starts by IP as defence in depth on top of budget
  # limits (Phase 12) and ownership authorization.
  throttle("generations/create/ip", limit: 20, period: 60) do |req|
    req.ip if req.post? && req.path.match?(%r{\A/api/v1/projects/\d+/videos/\d+/generations\z})
  end

  # Consistent JSON error envelope for throttled requests.
  self.throttled_responder = lambda do |_request|
    body = { error: { code: "rate_limited", messages: ["Too many requests. Please slow down and try again later."] } }
    [429, { "Content-Type" => "application/json" }, [body.to_json]]
  end
end

# Disabled during tests except where a spec explicitly enables it.
Rack::Attack.enabled = !Rails.env.test?

Rails.application.config.middleware.use Rack::Attack
