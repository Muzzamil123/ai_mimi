require "rails_helper"

RSpec.describe AuditLog, type: :model do
  it "requires an action" do
    log = build(:audit_log, action: nil)
    expect(log).not_to be_valid
    expect(log.errors[:action]).to be_present
  end

  it "stamps created_at on create without an updated_at column" do
    log = create(:audit_log)
    expect(log.created_at).to be_present
    expect(AuditLog.column_names).not_to include("updated_at")
  end

  it "is read-only once persisted (append-only trail)" do
    log = create(:audit_log)
    expect(log.readonly?).to be(true)
    expect { log.update!(action: "tampered") }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "keeps the record when the actor is later removed (no hard FK)" do
    admin = create(:user, :admin)
    log = create(:audit_log, actor: admin)
    admin.destroy!
    expect(log.reload.actor_id).to eq(admin.id)
    expect(log.actor).to be_nil
  end

  describe "scopes" do
    it "filters by action, actor, and resource" do
      admin = create(:user, :admin)
      a = create(:audit_log, actor: admin, action: "user.suspend", resource_type: "User", resource_id: 7)
      create(:audit_log, action: "settings.update", resource_type: "PlatformSetting")

      expect(AuditLog.for_action("user.suspend")).to contain_exactly(a)
      expect(AuditLog.for_actor(admin)).to contain_exactly(a)
      expect(AuditLog.for_resource("User", 7)).to contain_exactly(a)
    end
  end
end
