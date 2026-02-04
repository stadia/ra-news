class Comment < ApplicationRecord
  acts_as_nested_set

  MAX_BODY_LENGTH = 1000

  belongs_to :user, optional: true
  belongs_to :article, counter_cache: true

  validates :body, presence: true, length: { minimum: 1, maximum: MAX_BODY_LENGTH }

  def content
    body
  end

  def author_name
    user&.name || "익명"
  end

  def guest?
    user_id.nil?
  end
end
