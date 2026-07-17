require "rails_helper"

RSpec.describe Approvals::ResolveToken, type: :service do
  let(:character) { create(:character, :awaiting_approval) }

  def mint
    Approvals::CreateApprovalRequest.call(character)
  end

  it "resolves a valid raw token to its request" do
    result = mint
    expect(described_class.call(result.raw_token)).to eq(result.approval_request)
  end

  it "raises InvalidToken for a blank token" do
    expect { described_class.call("") }.to raise_error(Approvals::InvalidToken)
  end

  it "raises InvalidToken for an unknown/tampered token" do
    mint
    expect { described_class.call("not-a-real-token") }.to raise_error(Approvals::InvalidToken)
  end

  it "lazily flips a pending-but-past-expiry request to expired" do
    result = mint
    result.approval_request.update!(expires_at: 1.hour.ago)

    resolved = described_class.call(result.raw_token)
    expect(resolved).to be_expired
  end

  it "leaves already-responded requests untouched" do
    result = mint
    result.approval_request.update!(status: :approved, responded_at: Time.current)

    expect(described_class.call(result.raw_token)).to be_approved
  end
end
