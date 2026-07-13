require "rails_helper"

RSpec.describe Auth::RefreshTokens do
  let(:user) { create(:user) }
  let(:issued) { Auth::IssueTokens.call(user) }

  it "rotates the refresh token and returns a new pair" do
    raw = issued.refresh_token
    result = described_class.call(raw)

    expect(result.user).to eq(user)
    expect(result.tokens.refresh_token).to be_present
    expect(result.tokens.refresh_token).not_to eq(raw)
  end

  it "makes the presented token single-use (rotation revokes it)" do
    raw = issued.refresh_token
    described_class.call(raw)
    expect { described_class.call(raw) }.to raise_error(Auth::InvalidTokenError)
  end

  it "raises for an unknown token" do
    expect { described_class.call("garbage") }.to raise_error(Auth::InvalidTokenError)
  end

  it "raises for a blank token" do
    expect { described_class.call(nil) }.to raise_error(Auth::InvalidTokenError)
  end

  it "raises AccountInactive when the user is suspended" do
    raw = issued.refresh_token
    user.update!(status: :suspended)
    expect { described_class.call(raw) }.to raise_error(Auth::AccountInactive)
  end
end
