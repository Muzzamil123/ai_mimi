require "rails_helper"

RSpec.describe Projects::CreateProject do
  let(:user) { create(:user) }

  it "creates a draft project owned by the user with an initial status change" do
    project = described_class.call(user, { name: "First", default_language: "urdu" })

    expect(project).to be_persisted
    expect(project.user).to eq(user)
    expect(project).to be_draft
    expect(project.slug).to eq("first")

    initial = project.status_changes.last
    expect(initial.to_status).to eq("draft")
    expect(initial.from_status).to be_nil
    expect(initial.actor).to eq(user)
  end

  it "raises on invalid params without creating a project" do
    expect { described_class.call(user, { name: "" }) }.to raise_error(ActiveRecord::RecordInvalid)
    expect(user.projects.count).to eq(0)
  end
end
