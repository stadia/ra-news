class Tag < ActsAsTaggableOn::Tag
  scope :confirmed, -> { where(is_confirmed: true) }

  scope :unconfirmed, -> { where(is_confirmed: false) }

  def self.popular_tags(size = 10)
    where(is_confirmed: true).where("taggings_count > ?", 1).order(taggings_count: :desc).limit(size)
  end
end
