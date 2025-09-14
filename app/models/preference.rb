# frozen_string_literal: true

# rbs_inline: enabled

class Preference < ApplicationRecord
  #: (String name) -> Hash[String, untyped] || Array[untyped]
  def self.get_value(name)
    Rails.cache.fetch(name) {
      Preference.find_by(name:)&.value
    }
  end

  def self.ignore_hosts #: Array[String]
    get_value("ignore_hosts")
  end
end
