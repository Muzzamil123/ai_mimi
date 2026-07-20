require "rails_helper"

RSpec.describe ExpireApprovalRequestsJob, type: :job do
  include ActiveJob::TestHelper

  it "expires pending past-expiry requests and notifies the owner" do
    stale = create(:approval_request, :past_expiry)
    fresh = create(:approval_request)

    expect { described_class.perform_now }
      .to have_enqueued_mail(UserMailer, :approval_link_expired).once

    expect(stale.reload).to be_expired
    expect(fresh.reload).to be_pending
  end

  it "is idempotent — a second run re-notifies nothing" do
    create(:approval_request, :past_expiry)
    described_class.perform_now

    expect { described_class.perform_now }
      .not_to have_enqueued_mail(UserMailer, :approval_link_expired)
  end

  it "ignores already-terminal requests" do
    create(:approval_request, :expired)
    create(:approval_request, :approved)

    expect { described_class.perform_now }
      .not_to have_enqueued_mail(UserMailer, :approval_link_expired)
  end
end
