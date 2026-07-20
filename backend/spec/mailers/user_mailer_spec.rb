require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  let(:user) { create(:user, email: "m@example.com", name: "Mia") }

  describe "email_verification" do
    let(:mail) { described_class.email_verification(user, "verify-token-123") }

    it "is addressed to the user with a verification subject" do
      expect(mail.to).to eq([ "m@example.com" ])
      expect(mail.subject).to match(/verify/i)
    end

    it "links to the frontend verify page with the token" do
      expect(mail.body.encoded).to include("/verify-email")
      expect(mail.body.encoded).to include("verify-token-123")
    end
  end

  describe "password_reset" do
    let(:mail) { described_class.password_reset(user, "reset-token-456") }

    it "links to the frontend reset page with the token" do
      expect(mail.to).to eq([ "m@example.com" ])
      expect(mail.body.encoded).to include("/reset-password")
      expect(mail.body.encoded).to include("reset-token-456")
    end
  end

  describe "character_approval" do
    let(:project) { create(:project, user: user, name: "Baby Shark") }
    let(:character) { create(:character, project: project, name: "Sharky") }
    let(:approval_request) { create(:approval_request, project: project, character: character, user: user) }
    let(:raw_token) { "raw-approval-token-xyz" }
    let(:mail) { described_class.character_approval(character, approval_request, raw_token) }

    it "is sent to the authenticated account owner's email" do
      expect(mail.to).to eq([ "m@example.com" ])
      expect(mail.subject).to match(/ready for approval/i)
    end

    it "embeds the secure token in tokenized approve/reject links" do
      expect(mail.body.encoded).to include("/approvals/character/#{raw_token}")
      expect(mail.body.encoded).to include("intent=approve")
      expect(mail.body.encoded).to include("intent=reject")
      expect(mail.body.encoded).to include("Sharky")
    end
  end

  describe "character_approved" do
    let(:project) { create(:project, user: user, name: "Baby Shark") }
    let(:character) { create(:character, :approved, project: project, name: "Sharky") }
    let(:mail) { described_class.character_approved(character) }

    it "confirms approval to the owner and links to the project" do
      expect(mail.to).to eq([ "m@example.com" ])
      expect(mail.subject).to match(/approved/i)
      expect(mail.body.encoded).to include("/projects/#{project.id}/character")
    end
  end

  describe "character_rejected" do
    let(:project) { create(:project, user: user, name: "Baby Shark") }
    let(:character) do
      create(:character, :rejected, project: project, name: "Sharky", rejection_feedback: "too old")
    end
    let(:mail) { described_class.character_rejected(character) }

    it "confirms rejection to the owner including the feedback" do
      expect(mail.to).to eq([ "m@example.com" ])
      expect(mail.subject).to match(/rejected/i)
      expect(mail.body.encoded).to include("too old")
    end
  end

  describe "approval_link_expired" do
    let(:project) { create(:project, user: user, name: "Baby Shark") }
    let(:approval_request) { create(:approval_request, :expired, project: project, user: user) }
    let(:mail) { described_class.approval_link_expired(approval_request) }

    it "notifies the owner that the link expired" do
      expect(mail.to).to eq([ "m@example.com" ])
      expect(mail.subject).to match(/expired/i)
      expect(mail.body.encoded).to include("/projects/#{project.id}/character")
    end
  end
end
