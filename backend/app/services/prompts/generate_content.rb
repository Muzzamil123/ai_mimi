module Prompts
  # Runs the configured text-generation provider for a prompt version, persists
  # the generated content, provider metadata, and token/cost usage, moves the
  # prompt to `draft`, and advances the video to `prompt_ready`. Called from the
  # generation job within the idempotency guard, so it assumes the prompt is the
  # active `generating` attempt.
  #
  # Kept separate from the job so the provider call and persistence can be unit
  # tested without Sidekiq.
  class GenerateContent < ApplicationService
    def initialize(prompt, provider: nil, actor: nil)
      @prompt = prompt
      @video = prompt.video
      @provider = provider || TextGenerationProviders.build
      @actor = actor
    end

    def call
      context = Prompts::BuildContext.call(@video)
      result = @provider.generate_video_prompt(idea: @video.idea_source, context: context)

      readied = false
      @prompt.transaction do
        @prompt.update!(
          content: result.content,
          provider: result.provider,
          provider_model: result.model,
          provider_request_id: result.provider_request_id,
          input_tokens: result.input_tokens,
          output_tokens: result.output_tokens,
          estimated_cost: result.estimated_cost,
          failure_reason: nil
        )
        @prompt.transition_to!(:draft)
        if @video.generating_prompt?
          @video.transition_to!(:prompt_ready, actor: @actor, reason: "prompt generated")
          readied = true
        end
      end

      log_provider_request(result)
      record_usage(result)
      # Notify the owner the prompt is ready (post-commit, exactly once).
      SendPromptReadyEmailJob.perform_later(@video.id) if readied
      @prompt
    end

    private

    # Ledger the billable prompt generation (Phase 12), keyed by the prompt
    # version so a retried job never double-counts.
    def record_usage(result)
      project = @video.project
      Usage::Record.call(
        source: @prompt,
        provider: result.provider,
        service_type: "text_generation",
        model: result.model,
        user: project&.user,
        project: project,
        video: @video,
        provider_request_id: result.provider_request_id,
        input_tokens: result.input_tokens,
        output_tokens: result.output_tokens,
        provider_reported_cost: result.estimated_cost
      )
    end

    # Structured, secret-free record of the provider call (never the API key or
    # prompt content) for observability and cost auditing.
    def log_provider_request(result)
      Rails.logger.info(
        message: "prompt_generated",
        prompt_id: @prompt.id,
        video_id: @video.id,
        provider: result.provider,
        provider_model: result.model,
        provider_request_id: result.provider_request_id,
        input_tokens: result.input_tokens,
        output_tokens: result.output_tokens,
        estimated_cost: result.estimated_cost&.to_s
      )
    end
  end
end
