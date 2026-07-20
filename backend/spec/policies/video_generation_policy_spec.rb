require "rails_helper"

RSpec.describe VideoGenerationPolicy do
  let(:owner) { create(:user) }
  let(:other) { create(:user) }
  let(:admin) { create(:user, role: :admin) }
  let(:video) { create(:video, :with_idea, project: create(:project, :ready, user: owner)) }
  let(:generation) { create(:video_generation, video: video, project: video.project) }

  %i[create? retry? cancel?].each do |action|
    describe "##{action}" do
      it "allows owner/admin, denies others and anonymous" do
        expect(described_class.new(owner, generation).public_send(action)).to be(true)
        expect(described_class.new(admin, generation).public_send(action)).to be(true)
        expect(described_class.new(other, generation).public_send(action)).to be(false)
        expect(described_class.new(nil, generation).public_send(action)).to be(false)
      end
    end
  end

  describe "Scope" do
    it "returns only generations on the user's own videos" do
      mine = create(:video_generation, video: video, project: video.project)
      create(:video_generation)

      expect(described_class::Scope.new(owner, VideoGeneration.all).resolve).to contain_exactly(mine)
    end
  end
end
