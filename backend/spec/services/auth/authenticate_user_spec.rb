require "rails_helper"

RSpec.describe Auth::AuthenticateUser do
  let!(:user) { create(:user, email: "a@example.com", password: "password123") }

  it "returns the user for valid credentials and updates last_login_at" do
    result = described_class.call("A@Example.com", "password123")
    expect(result).to eq(user)
    expect(user.reload.last_login_at).to be_present
  end

  it "raises InvalidCredentials for a wrong password" do
    expect { described_class.call("a@example.com", "wrong") }
      .to raise_error(Auth::InvalidCredentials)
  end

  it "raises InvalidCredentials for an unknown email" do
    expect { described_class.call("missing@example.com", "password123") }
      .to raise_error(Auth::InvalidCredentials)
  end

  it "raises AccountInactive for a suspended account" do
    user.update!(status: :suspended)
    expect { described_class.call("a@example.com", "password123") }
      .to raise_error(Auth::AccountInactive)
  end
end
