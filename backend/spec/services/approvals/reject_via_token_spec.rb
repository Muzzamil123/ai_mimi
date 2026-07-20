require "rails_helper"

RSpec.describe Approvals::RejectViaToken, type: :service do
  include ActiveJob::TestHelper

  let(:project) { create(:project) }
  # Real transitions keep the project status in sync (see approve_via_token spec).
  let(:character) do
    c = create(:character, project: project)
    c.transition_to!(:generating)
    c.transition_to!(:awaiting_approval)
    c
  end
  let(:request) { Approvals::CreateApprovalRequest.call(character).approval_request }

  it "rejects the character, records feedback, and moves the project to character_rejected" do
    described_class.call(request, feedback: "make it friendlier")

    expect(request.reload).to be_rejected
    expect(request.feedback).to eq("make it friendlier")
    expect(request.responded_at).to be_present
    expect(character.reload).to be_rejected
    expect(character.rejection_feedback).to eq("make it friendlier")
    expect(project.reload.status).to eq("character_rejected")
  end

  it "allows rejection without feedback" do
    described_class.call(request)
    expect(request.reload).to be_rejected
    expect(character.reload).to be_rejected
  end

  it "queues a rejection-confirmation email" do
    expect { described_class.call(request, feedback: "nope") }
      .to have_enqueued_mail(UserMailer, :character_rejected)
  end

  it "raises AlreadyProcessed on a reused link" do
    described_class.call(request)
    expect { described_class.call(request.reload) }.to raise_error(Approvals::AlreadyProcessed)
  end
end
