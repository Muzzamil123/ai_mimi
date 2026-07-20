require "rails_helper"

RSpec.describe ApprovalRequest, type: :model do
  describe "validations" do
    it "has a valid default factory" do
      expect(build(:approval_request)).to be_valid
    end

    it "requires recipient_email, token_digest, and expires_at" do
      request = ApprovalRequest.new
      request.valid?
      expect(request.errors.attribute_names).to include(:recipient_email, :token_digest, :expires_at)
    end

    it "enforces a unique token_digest" do
      existing = create(:approval_request)
      dup = build(:approval_request, token_digest: existing.token_digest)
      expect(dup).not_to be_valid
    end
  end

  describe "one active pending request per character" do
    it "is blocked by the partial unique index" do
      first = create(:approval_request)
      expect do
        create(:approval_request, project: first.project, character: first.character, user: first.user)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows a new pending request once the prior one is cancelled" do
      first = create(:approval_request)
      first.update!(status: :cancelled)
      expect do
        create(:approval_request, project: first.project, character: first.character, user: first.user)
      end.not_to raise_error
    end
  end

  describe ".digest / .generate_token" do
    it "hashes deterministically and never returns the raw value" do
      raw, digest = ApprovalRequest.generate_token
      expect(digest).to eq(ApprovalRequest.digest(raw))
      expect(digest).not_to eq(raw)
      expect(raw.length).to be >= 32
    end
  end

  describe "#past_expiry? / #actionable?" do
    it "is actionable while pending and unexpired" do
      expect(build(:approval_request)).to be_actionable
    end

    it "is not actionable once past expiry" do
      request = build(:approval_request, :past_expiry)
      expect(request).to be_past_expiry
      expect(request).not_to be_actionable
    end

    it "is not actionable once responded" do
      expect(build(:approval_request, :approved)).not_to be_actionable
    end
  end

  describe ".active scope" do
    it "returns only pending, unexpired requests" do
      active = create(:approval_request)
      create(:approval_request, :past_expiry) # pending but expired
      create(:approval_request, :approved)

      expect(ApprovalRequest.active).to contain_exactly(active)
    end
  end
end
