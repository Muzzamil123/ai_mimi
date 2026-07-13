require "rails_helper"

RSpec.describe RefreshToken, type: :model do
  let(:user) { create(:user) }

  it "digests raw tokens with SHA-256" do
    expect(described_class.digest("abc")).to eq(Digest::SHA256.hexdigest("abc"))
  end

  it "is active when not revoked and not expired" do
    token = user.refresh_tokens.create!(token_digest: "a", expires_at: 1.day.from_now)
    expect(token).to be_active
  end

  it "is inactive once revoked" do
    token = user.refresh_tokens.create!(token_digest: "b", expires_at: 1.day.from_now)
    token.revoke!
    expect(token).not_to be_active
    expect(token.revoked_at).to be_present
  end

  it "is inactive once expired" do
    token = user.refresh_tokens.create!(token_digest: "c", expires_at: 1.day.ago)
    expect(token).not_to be_active
  end

  describe ".active scope" do
    it "returns only non-revoked, unexpired tokens" do
      active = user.refresh_tokens.create!(token_digest: "d", expires_at: 1.day.from_now)
      user.refresh_tokens.create!(token_digest: "e", expires_at: 1.day.ago)
      revoked = user.refresh_tokens.create!(token_digest: "f", expires_at: 1.day.from_now)
      revoked.revoke!

      expect(described_class.active).to contain_exactly(active)
    end
  end
end
