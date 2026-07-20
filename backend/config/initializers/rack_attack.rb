# Rate limiting / brute-force protection for authentication endpoints.
# NOTE: uses a per-process in-memory store for now. Phase 13 (security hardening)
# moves this to a shared Redis-backed store so limits are enforced across all
# processes; that also resolves the ActiveSupport RedisCacheStore/connection_pool
# incompatibility present in this dependency set.
class Rack::Attack
  cache.store = ActiveSupport::Cache::MemoryStore.new

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

  # Public, token-gated asset/thumbnail/archive downloads. Throttle by IP to blunt
  # token brute force (tokens are signed + expiring, but defence in depth).
  throttle("downloads/ip", limit: 120, period: 60) do |req|
    req.ip if req.get? && req.path == "/api/v1/downloads"
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
