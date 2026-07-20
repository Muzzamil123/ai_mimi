require "rails_helper"

RSpec.describe Approvals::CreateApprovalRequest, type: :service do
  let(:user) { create(:user, email: "owner@example.com") }
  let(:project) { create(:project, user: user) }
  let(:character) { create(:character, :awaiting_approval, project: project) }

  it "creates a pending request with a hashed token and returns the raw token" do
    result = described_class.call(character)

    request = result.approval_request
    expect(request).to be_persisted
    expect(request).to be_pending
    expect(result.raw_token).to be_present
    # Only the digest is stored; the raw token must resolve back to it.
    expect(request.token_digest).to eq(ApprovalRequest.digest(result.raw_token))
    expect(request.token_digest).not_to eq(result.raw_token)
  end

  it "resolves the recipient from the owner's current account email (never hardcoded)" do
    result = described_class.call(character)
    expect(result.approval_request.recipient_email).to eq("owner@example.com")

    user.update!(email: "changed@example.com")
    later = create(:character, :awaiting_approval, project: create(:project, user: user))
    expect(described_class.call(later).approval_request.recipient_email).to eq("changed@example.com")
  end

  it "sets an expiry from the configured TTL" do
    ttl = Rails.application.config.x.approvals.link_ttl_hours
    result = described_class.call(character)
    expect(result.approval_request.expires_at).to be_within(1.minute).of(ttl.hours.from_now)
  end

  it "cancels any prior pending request (cancel-and-replace)" do
    first = described_class.call(character).approval_request
    second = described_class.call(character).approval_request

    expect(first.reload).to be_cancelled
    expect(second).to be_pending
    expect(character.approval_requests.pending).to contain_exactly(second)
  end
end
