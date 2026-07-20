require "rails_helper"

RSpec.describe VideoPolicy do
  let(:owner) { create(:user) }
  let(:other) { create(:user) }
  let(:admin) { create(:user, role: :admin) }
  let(:project) { create(:project, :ready, user: owner) }
  let(:video) { create(:video, project: project) }

  %i[show? update? destroy? upload_audio?].each do |action|
    describe "##{action}" do
      it "allows the project owner" do
        expect(described_class.new(owner, video).public_send(action)).to be(true)
      end

      it "allows an admin" do
        expect(described_class.new(admin, video).public_send(action)).to be(true)
      end

      it "denies another user" do
        expect(described_class.new(other, video).public_send(action)).to be(false)
      end

      it "denies an anonymous user" do
        expect(described_class.new(nil, video).public_send(action)).to be(false)
      end
    end
  end

  describe "Scope" do
    it "returns only videos from the user's own projects" do
      mine = create(:video, project: project)
      create(:video, project: create(:project, :ready, user: other))

      resolved = described_class::Scope.new(owner, Video.all).resolve

      expect(resolved).to contain_exactly(mine)
    end

    it "returns all videos for an admin" do
      create(:video, project: project)
      create(:video, project: create(:project, :ready, user: other))

      expect(described_class::Scope.new(admin, Video.all).resolve.count).to eq(2)
    end
  end
end
