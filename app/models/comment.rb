class Comment < ApplicationRecord
  acts_as_nested_set

  MAX_BODY_LENGTH = 1000

  belongs_to :user
  belongs_to :article

  validates :body, presence: true, length: { minimum: 1, maximum: MAX_BODY_LENGTH }

  def content
    body
  end
end
