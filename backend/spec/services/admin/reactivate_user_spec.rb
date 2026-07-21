require "rails_helper"

RSpec.describe Admin::ReactivateUser, type: :service do
  let(:admin) { create(:user, :admin) }

  it "reactivates a suspended user" do
    user = create(:user, :suspended)
    described_class.call(user, actor: admin)
    expect(user.reload).to be_status_active
  end

  it "refuses to reactivate an active user" do
    user = create(:user)
    expect { described_class.call(user, actor: admin) }
      .to raise_error(Admin::InvalidOperation)
  end

  it "refuses to reactivate a deleted account" do
    user = create(:user, status: :deleted)
    expect { described_class.call(user, actor: admin) }
      .to raise_error(Admin::InvalidOperation)
  end
end
