# Streams a stored character image inline via the storage abstraction. Shared by
# the authenticated character endpoint and the public token-gated approval
# endpoint so the read/stream logic lives in one place. Storage keys are never
# exposed to clients. Raises RecordNotFound when the image or its bytes are gone.
module StreamsCharacterImage
  extend ActiveSupport::Concern

  private

  def stream_character_image(image)
    raise ActiveRecord::RecordNotFound if image.nil?

    data = Storage.adapter.read(image.storage_key)
    raise ActiveRecord::RecordNotFound if data.nil?

    send_data data, type: image.mime_type, disposition: "inline", filename: image.original_filename
  end
end
