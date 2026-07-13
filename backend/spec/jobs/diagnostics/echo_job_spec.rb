require "rails_helper"

RSpec.describe Diagnostics::EchoJob, type: :job do
  include ActiveJob::TestHelper

  it "enqueues on the default queue with its argument" do
    expect { described_class.perform_later("hi") }
      .to have_enqueued_job(described_class).with("hi").on_queue("default")
  end

  it "returns the message when performed" do
    expect(described_class.new.perform("hello")).to eq("hello")
  end

  it "defaults the message to 'pong'" do
    expect(described_class.new.perform).to eq("pong")
  end
end
