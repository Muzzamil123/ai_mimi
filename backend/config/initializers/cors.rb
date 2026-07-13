# Be sure to restart your server when you modify this file.
#
# Cross-Origin Resource Sharing for the React user and admin portals.
# Allowed origins are environment-driven (comma-separated) so production can
# lock this down without code changes.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(ENV.fetch("CORS_ORIGINS", "http://localhost:5173").split(",").map(&:strip))

    resource "*",
             headers: :any,
             expose: %w[Authorization],
             methods: %i[get post put patch delete options head],
             credentials: false
  end
end
