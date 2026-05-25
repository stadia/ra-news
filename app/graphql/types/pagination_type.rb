# frozen_string_literal: true

module Types
  class PaginationType < Types::BaseObject
    field :page, String, null: true
    field :next_page, String, null: true
    field :limit, Integer, null: false
  end
end
