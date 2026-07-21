require "rails_helper"

RSpec.describe Notifications::DeliverEmail do
  include GenerationHelpers

  # A video with a completed generation batch so completion emails have context.
  def completed_video(status: :completed)
    video = ready_to_generate_video
    video.update!(status: :generating)
    VideoGenerations.variant_matrix.each do |variant|
      create(:video_generation, :completed,
             video: video, project: video.project,
             character: video.project.active_character, prompt: video.active_prompt,
             aspect_ratio: variant[:aspect_ratio], variation_number: variant[:variation_number])
    end
    video.update!(status: status)
    video
  end

  before { ActionMailer::Base.deliveries.clear }

  it "sends to the project owner's current account email (never hardcoded)" do
    video = completed_video
    video.project.user.update!(email: "owner-new@example.com")

    described_class.call(email_type: "video_generation_completed", video: video.reload)

    delivery = EmailDelivery.last
    expect(delivery.recipient).to eq("owner-new@example.com")
    expect(delivery).to be_sent
    expect(delivery.provider_message_id).to be_present
    expect(ActionMailer::Base.deliveries.last.to).to eq([ "owner-new@example.com" ])
  end

  it "prevents duplicate emails for the same event" do
    video = completed_video

    described_class.call(email_type: "video_generation_completed", video: video)
    expect {
      described_class.call(email_type: "video_generation_completed", video: video)
    }.not_to change(EmailDelivery, :count)
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it "still sends a different email type for the same video (partial then completed)" do
    video = completed_video(status: :partially_completed)
    described_class.call(email_type: "video_generation_partially_completed", video: video)
    video.update!(status: :completed)
    described_class.call(email_type: "video_generation_completed", video: video)

    expect(EmailDelivery.pluck(:email_type))
      .to contain_exactly("video_generation_partially_completed", "video_generation_completed")
  end

  it "records failed and re-raises when delivery raises, keeping it retryable" do
    video = completed_video
    mail = double("mail", subject: "x", message_id: "m")
    allow(mail).to receive(:deliver_now).and_raise(Net::SMTPServerBusy, "busy")
    allow(Notifications::MailFactory).to receive(:build).and_return(mail)

    expect { described_class.call(email_type: "video_generation_completed", video: video) }
      .to raise_error(Net::SMTPServerBusy)

    delivery = EmailDelivery.last
    expect(delivery).to be_failed
    expect(delivery.error_message).to include("busy")
  end

  it "honours a disabled optional preference (no send)" do
    video = ready_to_generate_video
    video.project.user.update_notification_preferences!("prompt_ready" => false)

    described_class.call(email_type: "prompt_ready", video: video)

    expect(EmailDelivery.count).to eq(0)
    expect(ActionMailer::Base.deliveries).to be_empty
  end
end
