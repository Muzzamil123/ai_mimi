require "rails_helper"
require "base64"

RSpec.describe "Character generation pipeline jobs", type: :job do
  include ActiveJob::TestHelper

  let(:project) { create(:project, status: :initializing_character) }
  let(:character) { create(:character, :generating, project: project) }
  let(:png) { Base64.decode64(CharacterImageProviders::Fake::PNG_1PX_BASE64) }

  def stage_asset(gen_id = character.generation_id)
    key = "characters/#{character.id}/#{gen_id}/source.png"
    Storage.adapter.store(key: key, data: png, content_type: "image/png")
    key
  end

  describe "end to end" do
    it "runs prompt -> image -> download -> email and awaits approval" do
      gen = character.generation_id

      perform_enqueued_jobs do
        GenerateCharacterPromptJob.perform_later(character.id, gen)
      end

      expect(character.reload).to be_awaiting_approval
      expect(character.latest_image).to be_present
      expect(project.reload).to be_awaiting_character_approval
      expect(ActionMailer::Base.deliveries.last.to).to eq([ project.user.email ])
    end
  end

  describe "idempotency and duplicate protection" do
    it "no-ops when the generation_id is stale" do
      character.update!(generation_prompt: nil)

      GenerateCharacterPromptJob.new.perform(character.id, "stale-id")

      expect(character.reload.generation_prompt).to be_nil
      expect(character).to be_generating
    end

    it "creates only one image when the download job runs twice" do
      key = stage_asset

      2.times do
        DownloadCharacterImageJob.new.perform(character.id, character.generation_id, key, "image/png", "a1")
      end

      expect(character.reload.images.count).to eq(1)
      expect(character).to be_awaiting_approval
    end
  end

  describe "failure handling" do
    it "marks the generation failed on a non-retryable provider error" do
      provider = instance_double(CharacterImageProviders::Fake)
      allow(provider).to receive(:generate)
        .and_raise(CharacterImageProviders::Error.new("bad request", retryable: false))
      allow(CharacterImageProviders).to receive(:build).and_return(provider)

      GenerateCharacterImageJob.new.perform(character.id, character.generation_id)

      expect(character.reload).to be_failed
      expect(character.failure_reason).to eq("bad request")
      expect(project.reload).to be_failed
    end

    it "re-raises transient provider errors so Sidekiq retries, without failing yet" do
      provider = instance_double(CharacterImageProviders::Fake)
      allow(provider).to receive(:generate).and_raise(CharacterImageProviders::TimeoutError.new)
      allow(CharacterImageProviders).to receive(:build).and_return(provider)

      expect { GenerateCharacterImageJob.new.perform(character.id, character.generation_id) }
        .to raise_error(Characters::TransientError)
      expect(character.reload).to be_generating
    end

    it "marks the generation failed when the stored asset is missing (storage failure)" do
      DownloadCharacterImageJob.new.perform(character.id, character.generation_id, "missing-key", "image/png", nil)

      expect(character.reload).to be_failed
      expect(project.reload).to be_failed
    end

    it "marks the generation failed on an unexpected (non-provider) error, never stranding it" do
      allow(Characters::GeneratePrompt).to receive(:call)
        .and_raise(ActiveRecord::RecordInvalid.new(Character.new))

      GenerateCharacterPromptJob.new.perform(character.id, character.generation_id)

      expect(character.reload).to be_failed
      expect(project.reload).to be_failed
    end
  end

  describe SendCharacterApprovalEmailJob do
    it "sends to the project owner while awaiting approval" do
      character.update!(status: :awaiting_approval)

      expect { described_class.new.perform(character.id, character.generation_id) }
        .to change { ActionMailer::Base.deliveries.size }.by(1)
      expect(ActionMailer::Base.deliveries.last.to).to eq([ project.user.email ])
    end

    it "does not send when the character is no longer awaiting approval" do
      character.update!(status: :approved)

      expect { described_class.new.perform(character.id, character.generation_id) }
        .not_to change { ActionMailer::Base.deliveries.size }
    end
  end
end
