require "aws-sdk-s3"
require "digest"

module Storage
  # S3-compatible object storage for production (Phase 14). Works with Amazon S3
  # and any S3-compatible provider (Cloudflare R2, MinIO, GCS interop) via an
  # optional custom endpoint. Objects are private; delivery stays behind the
  # app's signed-URL flow (Downloads::SignedUrl), which reads bytes through this
  # adapter — so a CDN can front the app without exposing storage keys.
  #
  # Config (ENV): S3_BUCKET (required), S3_REGION, S3_ENDPOINT (for R2/MinIO),
  # S3_FORCE_PATH_STYLE (true for MinIO), plus standard AWS credential ENV
  # (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY) or the instance role.
  class S3 < Base
    def initialize(bucket: nil, client: nil)
      @bucket = bucket || ENV.fetch("S3_BUCKET")
      @client = client || build_client
    end

    def store(key:, data:, content_type: nil)
      @client.put_object(
        bucket: @bucket, key: normalize(key), body: data,
        content_type: content_type, acl: "private"
      )
      Blob.new(
        key: key,
        byte_size: data.bytesize,
        checksum: Digest::SHA256.hexdigest(data),
        content_type: content_type
      )
    rescue Aws::Errors::ServiceError => e
      raise Storage::Error, "Failed to store '#{key}': #{e.message}"
    end

    def read(key)
      @client.get_object(bucket: @bucket, key: normalize(key)).body.read
    rescue Aws::S3::Errors::NoSuchKey
      nil
    rescue Aws::Errors::ServiceError => e
      raise Storage::Error, "Failed to read '#{key}': #{e.message}"
    end

    def delete(key)
      @client.delete_object(bucket: @bucket, key: normalize(key))
      true
    rescue Aws::Errors::ServiceError => e
      raise Storage::Error, "Failed to delete '#{key}': #{e.message}"
    end

    def exist?(key)
      @client.head_object(bucket: @bucket, key: normalize(key))
      true
    rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchKey
      false
    end

    private

    def normalize(key)
      key.to_s.gsub(%r{\A/+}, "")
    end

    def build_client
      options = { region: ENV.fetch("S3_REGION", "us-east-1") }
      options[:endpoint] = ENV["S3_ENDPOINT"] if ENV["S3_ENDPOINT"].present?
      options[:force_path_style] = true if ActiveModel::Type::Boolean.new.cast(ENV["S3_FORCE_PATH_STYLE"])
      Aws::S3::Client.new(options)
    end
  end
end
