require "rails_helper"

RSpec.describe CharacterPolicy do
  let(:owner) { create(:user) }
  let(:other) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:project) { create(:project, user: owner) }
  let(:character) { create(:character, project: project) }

  permitted = %i[show? create? update? destroy? generate? approve? reject? image?]

  permitted.each do |action|
    it "allows the owner to #{action}" do
      expect(described_class.new(owner, character).public_send(action)).to be(true)
    end

    it "allows an admin to #{action}" do
      expect(described_class.new(admin, character).public_send(action)).to be(true)
    end

    it "forbids a non-owner to #{action}" do
      expect(described_class.new(other, character).public_send(action)).to be(false)
    end
  end

  describe "#reset?" do
    it "allows only admins" do
      expect(described_class.new(admin, character).reset?).to be(true)
      expect(described_class.new(owner, character).reset?).to be(false)
      expect(described_class.new(other, character).reset?).to be(false)
    end
  end
end
