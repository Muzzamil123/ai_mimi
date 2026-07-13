require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  it "is valid with default attributes" do
    expect(user).to be_valid
  end

  it "normalizes email to stripped lowercase" do
    record = create(:user, email: "  MixedCase@Example.COM ")
    expect(record.email).to eq("mixedcase@example.com")
  end

  it "requires a password of at least 8 characters" do
    record = build(:user, password: "short")
    expect(record).not_to be_valid
    expect(record.errors[:password]).to be_present
  end

  it "enforces case-insensitive email uniqueness" do
    create(:user, email: "dup@example.com")
    expect(build(:user, email: "DUP@example.com")).not_to be_valid
  end

  it "defaults to the user role and active status" do
    record = create(:user)
    expect(record).to be_user
    expect(record).to be_status_active
  end

  describe "email verification token" do
    it "round-trips a valid token" do
      user = create(:user)
      token = user.generate_token_for(:email_verification)
      expect(User.find_by_token_for(:email_verification, token)).to eq(user)
    end

    it "is invalidated once the account is verified" do
      user = create(:user)
      token = user.generate_token_for(:email_verification)
      user.mark_email_verified!
      expect(User.find_by_token_for(:email_verification, token)).to be_nil
    end
  end

  describe "password reset token" do
    it "is invalidated after the password changes" do
      user = create(:user)
      token = user.generate_token_for(:password_reset)
      user.update!(password: "newpassword123")
      expect(User.find_by_token_for(:password_reset, token)).to be_nil
    end
  end
end
