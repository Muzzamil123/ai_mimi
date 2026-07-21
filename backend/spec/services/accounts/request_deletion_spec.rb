require "rails_helper"

RSpec.describe Accounts::RequestDeletion, type: :service do
  include ActiveJob::TestHelper

  it "revokes sessions, marks the account deleted, and enqueues the purge" do
    user = create(:user)
    token = create(:refresh_token, user: user, expires_at: 1.day.from_now)

    expect {
      described_class.call(user)
    }.to have_enqueued_job(PurgeAccountJob).with(user.id)

    expect(user.reload).to be_status_deleted
    expect(token.reload.revoked_at).to be_present
  end

  it "is idempotent on an already-deleted account" do
    user = create(:user, status: :deleted)
    expect { described_class.call(user) }.not_to raise_error
    expect(user.reload).to be_status_deleted
  end
end
