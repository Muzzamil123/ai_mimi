require "rails_helper"

RSpec.describe Providers::Credentials, type: :service do
  around do |example|
    original = ENV["OPENAI_API_KEY"]
    example.run
    ENV["OPENAI_API_KEY"] = original
  end

  it "prefers the encrypted platform setting over ENV" do
    PlatformSetting.set("openai_api_key", "from-setting")
    ENV["OPENAI_API_KEY"] = "from-env"
    expect(described_class.fetch("openai_api_key", env: "OPENAI_API_KEY")).to eq("from-setting")
  end

  it "falls back to ENV when the setting is unset" do
    ENV["OPENAI_API_KEY"] = "from-env"
    expect(described_class.fetch("openai_api_key", env: "OPENAI_API_KEY")).to eq("from-env")
  end

  it "returns nil when neither source has a value" do
    ENV["OPENAI_API_KEY"] = nil
    expect(described_class.fetch("openai_api_key", env: "OPENAI_API_KEY")).to be_nil
  end

  it "ignores unknown setting keys and uses ENV only" do
    ENV["OPENAI_API_KEY"] = "x"
    expect(described_class.fetch("not_a_registry_key", env: "OPENAI_API_KEY")).to eq("x")
  end
end
