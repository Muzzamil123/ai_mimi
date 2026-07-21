require "rails_helper"

RSpec.describe Costs::SpendByScope, type: :service do
  it "groups spend by user with a resolved label, highest first" do
    big = create(:user, email: "big@example.com")
    small = create(:user, email: "small@example.com")
    create(:provider_usage, user: big, estimated_cost: "10")
    create(:provider_usage, user: small, estimated_cost: "1")
    create(:provider_usage, user: nil, estimated_cost: "5") # unattributed, dropped

    rows = described_class.call(group: :user)

    expect(rows.map { |r| r[:id] }).to eq([ big.id, small.id ])
    expect(rows.first).to include(estimated_cost: 10.0, label: "big@example.com")
  end

  it "groups spend by project" do
    project = create(:project)
    create(:provider_usage, project: project, estimated_cost: "4")

    rows = described_class.call(group: :project)
    expect(rows.first).to include(id: project.id, estimated_cost: 4.0, label: project.name)
  end

  it "raises on an unknown grouping" do
    expect { described_class.call(group: :bogus) }.to raise_error(ArgumentError)
  end
end
