require "rails_helper"

RSpec.describe SendCharacterApprovalEmailJob, type: :job do
  include ActiveJob::TestHelper

  let(:user) { create(:user, email: "owner@example.com") }
  let(:project) { create(:project, user: user) }
  let(:character) { create(:character, :awaiting_approval, project: project) }

  it "creates a pending approval request and emails the owner" do
    expect do
      perform_enqueued_jobs do
        described_class.perform_later(character.id, character.generation_id)
      end
    end.to change { character.approval_requests.pending.count }.by(1)

    mail = ActionMailer::Base.deliveries.last
    expect(mail.to).to eq([ "owner@example.com" ])
    expect(mail.subject).to match(/ready for approval/i)
  end

  it "no-ops when the character is not awaiting approval" do
    character.update_columns(status: Character.statuses[:approved])
    expect do
      described_class.perform_now(character.id, character.generation_id)
    end.not_to change(ApprovalRequest, :count)
  end

  it "no-ops for a stale generation id" do
    expect do
      described_class.perform_now(character.id, SecureRandom.uuid)
    end.not_to change(ApprovalRequest, :count)
  end

  it "cancels the prior link when re-run (idempotent cancel-and-replace)" do
    described_class.perform_now(character.id, character.generation_id)
    described_class.perform_now(character.id, character.generation_id)

    expect(character.approval_requests.pending.count).to eq(1)
    expect(character.approval_requests.cancelled.count).to eq(1)
  end
end
