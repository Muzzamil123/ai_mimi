require "rails_helper"

RSpec.describe Approvals::ApproveViaToken, type: :service do
  include ActiveJob::TestHelper

  let(:project) { create(:project) }
  # Drive the project + character into a synced `awaiting_approval` state via the
  # real transitions (the `:awaiting_approval` factory trait alone leaves the
  # project in `draft`, which would make the approve->ready transition illegal).
  let(:character) do
    c = create(:character, project: project)
    c.transition_to!(:generating)
    c.transition_to!(:awaiting_approval)
    c
  end
  let(:request) { Approvals::CreateApprovalRequest.call(character).approval_request }

  it "approves the character, readies the project, and marks the request approved" do
    described_class.call(request)

    expect(request.reload).to be_approved
    expect(request.responded_at).to be_present
    expect(character.reload).to be_approved
    expect(character.locked_at).to be_present
    expect(project.reload).to be_ready
    expect(project.active_character_id).to eq(character.id)
  end

  it "records the account owner as the transition actor" do
    described_class.call(request)
    change = project.status_changes.order(:created_at).last
    expect(change.to_status).to eq("ready")
    expect(change.actor_id).to eq(project.user_id)
  end

  it "queues an approval-confirmation email" do
    expect { described_class.call(request) }
      .to have_enqueued_mail(UserMailer, :character_approved)
  end

  it "raises LinkExpired for an expired link and marks it expired" do
    request.update!(expires_at: 1.hour.ago)
    expect { described_class.call(request) }.to raise_error(Approvals::LinkExpired)
    expect(request.reload).to be_expired
    expect(character.reload).to be_awaiting_approval
  end

  it "raises AlreadyProcessed on a reused (already approved) link" do
    described_class.call(request)
    expect { described_class.call(request.reload) }.to raise_error(Approvals::AlreadyProcessed)
  end

  it "raises AlreadyProcessed if the character moved on out of band" do
    character.reset_by_admin!(actor: create(:user, :admin))
    expect { described_class.call(request) }.to raise_error(Approvals::AlreadyProcessed)
  end
end
