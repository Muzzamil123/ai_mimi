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
    let(:mail) { described_class.character_approval(character) }

    it "is sent to the authenticated account owner's email" do
      expect(mail.to).to eq([ "m@example.com" ])
      expect(mail.subject).to match(/ready for approval/i)
    end

    it "links to the project's character review page" do
      expect(mail.body.encoded).to include("/projects/#{project.id}/character")
      expect(mail.body.encoded).to include("Sharky")
    end
  end
end
