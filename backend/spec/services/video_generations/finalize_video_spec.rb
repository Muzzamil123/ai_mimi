require "rails_helper"

RSpec.describe VideoGenerations::FinalizeVideo do
  def generating_video_with(statuses)
    video = ready_to_generate_video
    video.update!(status: :generating)
    statuses.each_with_index do |status, index|
      create(:video_generation, status,
             video: video, project: video.project,
             character: video.project.active_character, prompt: video.active_prompt,
             aspect_ratio: index.even? ? "3:4" : "9:16", variation_number: (index % 2) + 1)
    end
    video
  end

  it "marks the video completed when all variants complete" do
    video = generating_video_with(%i[completed completed completed completed])
    described_class.call(video)
    expect(video.reload).to be_completed
  end

  it "marks the video partially_completed when some fail" do
    video = generating_video_with(%i[completed completed failed failed])
    described_class.call(video)
    expect(video.reload).to be_partially_completed
  end

  it "marks the video failed when all fail" do
    video = generating_video_with(%i[failed failed failed failed])
    described_class.call(video)
    expect(video.reload).to be_failed
  end

  it "does nothing while a variant is still processing" do
    video = generating_video_with(%i[completed completed completed processing])
    described_class.call(video)
    expect(video.reload).to be_generating
  end
end
