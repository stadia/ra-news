class Comment < ApplicationRecord
  acts_as_nested_set

  belongs_to :user
  belongs_to :article

  validates :body, presence: true, length: { minimum: 1, maximum: 1000 }
end
