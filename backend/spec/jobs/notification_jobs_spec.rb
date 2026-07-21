require "rails_helper"

RSpec.describe "Notification jobs & seams" do
  include ActiveJob::TestHelper
  include GenerationHelpers

  def video_with_batch(statuses, video_status:)
    video = ready_to_generate_video
    video.update!(status: :generating)
    statuses.each_with_index do |status, index|
      create(:video_generation, status,
             video: video, project: video.project,
             character: video.project.active_character, prompt: video.active_prompt,
             aspect_ratio: index.even? ? "3:4" : "9:16", variation_number: (index % 2) + 1)
    end
    video.update!(status: video_status)
    video
  end

  before { ActionMailer::Base.deliveries.clear }

  describe SendVideoCompletionEmailJob do
    it "sends the partial-completion email" do
      video = video_with_batch(%i[completed completed failed failed], video_status: :partially_completed)

      described_class.perform_now(video.id)

      expect(EmailDelivery.last.email_type).to eq("video_generation_partially_completed")
    end

    it "sends the failed-generation email" do
      video = video_with_batch(%i[failed failed failed failed], video_status: :failed)

      described_class.perform_now(video.id)

      expect(EmailDelivery.last.email_type).to eq("video_generation_failed")
    end

    it "is a no-op for a non-terminal video" do
      video = ready_to_generate_video
      described_class.perform_now(video.id)
      expect(EmailDelivery.count).to eq(0)
    end
  end

  describe RetryEmailDeliveryJob do
    it "re-sends a failed delivery" do
      video = video_with_batch(%i[completed completed completed completed], video_status: :completed)
      delivery = create(:email_delivery, :failed, user: video.project.user, video: video,
                                                  email_type: "video_generation_completed",
                                                  dedupe_key: "video_generation_completed:#{video.id}:#{video.active_prompt_id}")

      described_class.perform_now(delivery.id)

      expect(delivery.reload).to be_sent
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it "ignores a non-failed delivery" do
      delivery = create(:email_delivery, status: :sent)
      described_class.perform_now(delivery.id)
      expect(delivery.reload).to be_sent
    end
  end

  describe HandleEmailDeliveryWebhookJob do
    it "marks the matching delivery delivered" do
      delivery = create(:email_delivery, provider_message_id: "msg-1")

      described_class.perform_now({ "message_id" => "msg-1", "event" => "delivered" })

      expect(delivery.reload).to be_delivered
      expect(delivery.delivered_at).to be_present
    end

    it "marks a bounce" do
      delivery = create(:email_delivery, provider_message_id: "msg-2")
      described_class.perform_now({ "message_id" => "msg-2", "event" => "bounce" })
      expect(delivery.reload).to be_bounced
    end

    it "ignores an unknown message id" do
      expect { described_class.perform_now({ "message_id" => "nope", "event" => "delivered" }) }
        .not_to raise_error
    end
  end

  describe "seams" do
    it "enqueues the completion email when a batch finalizes" do
      video = video_with_batch(%i[completed completed completed completed], video_status: :generating)

      expect { VideoGenerations::FinalizeVideo.call(video) }
        .to have_enqueued_job(SendVideoCompletionEmailJob).with(video.id)
    end

    it "enqueues the started email when a batch is created" do
      video = ready_to_generate_video
      video.update!(status: :queued)

      expect { VideoGenerations::CreateBatch.call(video) }
        .to have_enqueued_job(SendVideoGenerationStartedEmailJob).with(video.id)
    end
  end
end
