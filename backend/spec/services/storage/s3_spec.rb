require "rails_helper"

RSpec.describe Storage::S3, type: :service do
  # Aws stub_responses keeps these tests fully offline (no network, no creds).
  let(:client) { Aws::S3::Client.new(stub_responses: true, region: "us-east-1") }
  let(:adapter) { described_class.new(bucket: "test-bucket", client: client) }

  describe "#store" do
    it "uploads a private object and returns blob metadata" do
      blob = adapter.store(key: "/videos/out.mp4", data: "DATA", content_type: "video/mp4")

      req = client.api_requests.last
      expect(req[:operation_name]).to eq(:put_object)
      expect(req[:params][:bucket]).to eq("test-bucket")
      expect(req[:params][:key]).to eq("videos/out.mp4") # leading slash stripped
      expect(req[:params][:acl]).to eq("private")
      expect(blob.byte_size).to eq(4)
      expect(blob.checksum).to eq(Digest::SHA256.hexdigest("DATA"))
    end

    it "wraps provider errors in Storage::Error" do
      client.stub_responses(:put_object, "AccessDenied")
      expect { adapter.store(key: "k", data: "x") }.to raise_error(Storage::Error)
    end
  end

  describe "#read" do
    it "returns the object bytes" do
      client.stub_responses(:get_object, body: "HELLO")
      expect(adapter.read("k")).to eq("HELLO")
    end

    it "returns nil for a missing key" do
      client.stub_responses(:get_object, "NoSuchKey")
      expect(adapter.read("missing")).to be_nil
    end

    it "raises Storage::Error on other service errors" do
      client.stub_responses(:get_object, "InternalError")
      expect { adapter.read("k") }.to raise_error(Storage::Error)
    end
  end

  describe "#exist?" do
    it "is true when the object is present" do
      expect(adapter.exist?("k")).to be(true)
    end

    it "is false when not found" do
      client.stub_responses(:head_object, "NotFound")
      expect(adapter.exist?("k")).to be(false)
    end
  end

  describe "#delete" do
    it "deletes the object and returns true" do
      expect(adapter.delete("k")).to be(true)
      expect(client.api_requests.last[:operation_name]).to eq(:delete_object)
    end
  end
end
