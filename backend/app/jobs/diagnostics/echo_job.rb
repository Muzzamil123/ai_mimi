module Diagnostics
  # Minimal Sidekiq-backed job used to verify that background processing is wired
  # end-to-end (enqueue -> Redis -> worker). Real domain jobs arrive in later phases.
  class EchoJob < ApplicationJob
    queue_as :default

    def perform(message = "pong")
      Rails.logger.info(message: "diagnostics_echo", payload: message)
      message
    end
  end
end
