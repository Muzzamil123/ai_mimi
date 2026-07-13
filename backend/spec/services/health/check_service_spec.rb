require "rails_helper"

RSpec.describe Health::CheckService do
  let(:fake_redis) { instance_double(Redis, ping: "PONG", close: nil) }

  before do
    allow(ActiveRecord::Base.connection).to receive(:execute).and_return(true)
    allow(Redis).to receive(:new).and_return(fake_redis)
    allow(Sidekiq).to receive(:redis).and_return("PONG")
  end

  describe ".call" do
    it "reports ok for every component when all dependencies respond" do
      report = described_class.call

      expect(report).to be_healthy
      expect(report.status).to eq("ok")
      expect(report.components).to eq(database: "ok", redis: "ok", sidekiq: "ok")
      expect(report.version).to eq(Rails.application.config.x.app_version)
    end

    it "fails closed and marks the component as error when a dependency raises" do
      allow(Redis).to receive(:new).and_raise(Redis::CannotConnectError)

      report = described_class.call

      expect(report).not_to be_healthy
      expect(report.status).to eq("degraded")
      expect(report.components[:redis]).to eq("error")
      expect(report.components[:database]).to eq("ok")
    end

    it "marks the database as error when the connection query raises" do
      allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(ActiveRecord::StatementInvalid)

      report = described_class.call

      expect(report.components[:database]).to eq("error")
    end
  end
end
