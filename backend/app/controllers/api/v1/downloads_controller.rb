module Api
  module V1
    # Public, token-gated streaming of stored assets, thumbnails, and archives.
    # There is no session — a valid signed token (see Downloads::SignedUrl) is the
    # authorization, so playback (<video src>) and download links work directly.
    # Storage keys are never exposed to clients.
    class DownloadsController < ActionController::API
      def show
        payload = Downloads::SignedUrl.verify(params[:token])

        case payload[:kind]
        when "asset"     then stream_asset(payload, key: :storage_key)
        when "thumbnail" then stream_asset(payload, key: :thumbnail_storage_key)
        when "archive"   then stream_archive(payload)
        else render_error(:not_found, "not_found", "Nothing to download")
        end
      rescue Downloads::SignedUrl::InvalidToken => e
        render_error(:gone, "link_expired", e.message)
      end

      private

      def stream_asset(payload, key:)
        asset = VideoAsset.find_by(id: payload[:asset_id])
        return render_error(:not_found, "not_found", "Asset not found") if asset.nil? || !asset.ready?

        storage_key = asset.public_send(key)
        data = storage_key && Storage.adapter.read(storage_key)
        return render_error(:not_found, "not_found", "File not found") if data.nil?

        content_type = key == :thumbnail_storage_key ? Media::Thumbnail::MIME_TYPE : asset.mime_type
        send_data data, type: content_type, disposition: payload[:disposition] || "attachment",
                        filename: download_filename(asset, key)
      end

      def stream_archive(payload)
        storage_key = payload[:storage_key].to_s
        # Only archive blobs are streamable this way (defence in depth even though
        # the token is signed).
        return render_error(:not_found, "not_found", "Archive not found") unless storage_key.start_with?("archives/")

        data = Storage.adapter.read(storage_key)
        return render_error(:not_found, "not_found", "Archive not found") if data.nil?

        send_data data, type: "application/zip", disposition: "attachment",
                        filename: payload[:filename].presence || "outputs.zip"
      end

      def download_filename(asset, key)
        key == :thumbnail_storage_key ? "thumbnail-#{asset.id}.jpg" : (asset.filename.presence || "output-#{asset.id}.mp4")
      end

      def render_error(status, code, message)
        render json: { error: { code: code, messages: [ message ] } }, status: status
      end
    end
  end
end
