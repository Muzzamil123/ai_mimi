require "rails_helper"
require "tmpdir"

RSpec.describe Storage::LocalDisk do
  around do |example|
    Dir.mktmpdir do |dir|
      @root = dir
      example.run
    end
  end

  subject(:storage) { described_class.new(root: @root) }

  it "stores bytes and returns blob metadata" do
    blob = storage.store(key: "characters/1/source.png", data: "hello", content_type: "image/png")

    expect(blob.byte_size).to eq(5)
    expect(blob.content_type).to eq("image/png")
    expect(blob.checksum).to eq(Digest::SHA256.hexdigest("hello"))
    expect(storage.exist?("characters/1/source.png")).to be(true)
  end

  it "reads back stored bytes and returns nil for a missing key" do
    storage.store(key: "a/b.png", data: "data")

    expect(storage.read("a/b.png")).to eq("data")
    expect(storage.read("missing.png")).to be_nil
  end

  it "deletes a stored object" do
    storage.store(key: "x.png", data: "d")
    expect(storage.delete("x.png")).to be(true)
    expect(storage.delete("x.png")).to be(false)
  end

  it "refuses keys that escape the storage root" do
    expect { storage.store(key: "../escape.png", data: "d") }
      .to raise_error(Storage::Error, /Invalid storage key/)
  end
end
