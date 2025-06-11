class Comment < ApplicationRecord
  acts_as_nested_set

  belongs_to :user
  belongs_to :article
end
