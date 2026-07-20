require "rails_helper"

RSpec.describe PromptPolicy do
  let(:owner) { create(:user) }
  let(:other) { create(:user) }
  let(:admin) { create(:user, role: :admin) }
  let(:video) { create(:video, :with_idea, project: create(:project, :ready, user: owner)) }
  let(:prompt) { create(:prompt, video: video) }

  %i[show? create? generate? approve?].each do |action|
    describe "##{action}" do
      it "allows the owner and admin, denies others and anonymous" do
        expect(described_class.new(owner, prompt).public_send(action)).to be(true)
        expect(described_class.new(admin, prompt).public_send(action)).to be(true)
        expect(described_class.new(other, prompt).public_send(action)).to be(false)
        expect(described_class.new(nil, prompt).public_send(action)).to be(false)
      end
    end
  end

  describe "Scope" do
    it "returns only prompts on the user's own videos" do
      mine = create(:prompt, video: video)
      create(:prompt, video: create(:video, :with_idea, project: create(:project, :ready, user: other)))

      expect(described_class::Scope.new(owner, Prompt.all).resolve).to contain_exactly(mine)
    end

    it "returns all prompts for an admin" do
      create(:prompt, video: video)
      create(:prompt, video: create(:video, :with_idea, project: create(:project, :ready, user: other)))

      expect(described_class::Scope.new(admin, Prompt.all).resolve.count).to eq(2)
    end
  end
end
