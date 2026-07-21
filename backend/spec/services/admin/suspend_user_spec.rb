require "rails_helper"

RSpec.describe Admin::SuspendUser, type: :service do
  let(:admin) { create(:user, :admin) }

  it "suspends an active user and revokes their refresh tokens" do
    user = create(:user)
    token = create(:refresh_token, user: user, expires_at: 1.day.from_now)

    described_class.call(user, actor: admin)

    expect(user.reload).to be_status_suspended
    expect(token.reload.revoked_at).to be_present
  end

  it "is a no-op on an already-suspended user" do
    user = create(:user, :suspended)
    expect { described_class.call(user, actor: admin) }.not_to raise_error
    expect(user.reload).to be_status_suspended
  end

  it "refuses to suspend a deleted account" do
    user = create(:user, status: :deleted)
    expect { described_class.call(user, actor: admin) }
      .to raise_error(Admin::InvalidOperation)
  end

  it "refuses self-suspension" do
    expect { described_class.call(admin, actor: admin) }
      .to raise_error(Admin::InvalidOperation)
  end
end
