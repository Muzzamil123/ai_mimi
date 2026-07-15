# A generated image asset belonging to a character. Multiple rows accumulate as
# a character is regenerated; the most recent is the one presented for approval.
class CharacterImage < ApplicationRecord
  belongs_to :character

  validates :storage_key, presence: true, uniqueness: true
  validates :mime_type, presence: true
  validates :file_size, numericality: { greater_than: 0 }, allow_nil: true
end
