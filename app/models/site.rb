# frozen_string_literal: true

# rbs_inline: enabled

class Site < ApplicationRecord
  validates :name, :client, presence: true

  def execute_client #: Object?
    return unless base_uri.is_a?(String)

    client.constantize.new(base_uri: base_uri)
  end
end
