require "rails_helper"

RSpec.describe PurgeAccountJob, type: :job do
  it "destroys owned projects and anonymizes the deleted user" do
    user = create(:user, status: :deleted, email: "real@example.com", name: "Real Name")
    create(:project, user: user)
    create(:email_delivery, user: user)

    described_class.new.perform(user.id)

    user.reload
    expect(user.projects.count).to eq(0)
    expect(user.email_deliveries.count).to eq(0)
    expect(user.name).to eq("Deleted user")
    expect(user.email).to eq("deleted-#{user.id}@deleted.invalid")
  end

  it "does nothing for an account that is not marked deleted" do
    user = create(:user, email: "active@example.com")
    create(:project, user: user)

    described_class.new.perform(user.id)

    expect(user.reload.email).to eq("active@example.com")
    expect(user.projects.count).to eq(1)
  end

  it "is idempotent (safe to retry after anonymization)" do
    user = create(:user, status: :deleted)
    described_class.new.perform(user.id)
    anonymized = user.reload.email
    described_class.new.perform(user.id)
    expect(user.reload.email).to eq(anonymized)
  end
end
