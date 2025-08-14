class Tag < ActsAsTaggableOn::Tag
  scope :confirmed, -> { where(is_confirmed: true) }

  scope :unconfirmed, -> { where(is_confirmed: false) }
end
