# frozen_string_literal: true

# rbs_inline: enabled

class Session < ApplicationRecord
  belongs_to :user
end
