require "rails_helper"

RSpec.describe Providers::CircuitBreaker, type: :service do
  let(:store) { ActiveSupport::Cache::MemoryStore.new }

  def breaker
    described_class.new(key: "test", store: store, threshold: 3, cooldown: 60)
  end

  it "runs the block and returns its value when closed" do
    expect(breaker.run { 42 }).to eq(42)
  end

  it "opens after the failure threshold, then fails fast with CircuitOpenError" do
    b = breaker
    3.times { expect { b.run { raise "boom" } }.to raise_error("boom") }

    expect(b).to be_open
    expect { b.run { 1 } }.to raise_error(Providers::CircuitOpenError)
  end

  it "resets the failure count after a success" do
    b = breaker
    2.times { expect { b.run { raise "boom" } }.to raise_error("boom") }
    b.run { :ok } # success resets

    2.times { expect { b.run { raise "boom" } }.to raise_error("boom") }
    expect(b).not_to be_open # only 2 since the reset, threshold is 3
  end

  it "only counts the listed failure types toward tripping" do
    b = breaker
    5.times do
      expect { b.run(count_as_failure: [ ArgumentError ]) { raise "uncounted" } }
        .to raise_error(RuntimeError)
    end
    expect(b).not_to be_open
  end
end
