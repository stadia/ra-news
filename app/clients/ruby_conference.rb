# frozen_string_literal: true
# rbs_inline: enabled

module RubyConference
  module_function

  BASE_URL = "https://raw.githubusercontent.com/ruby-conferences/ruby-conferences.github.io/refs/heads/main"

  def conferences #: Array[untyped]
    YAML.load(Faraday.get("#{BASE_URL}/_data/conferences.yml").body, permitted_classes: [Date])
  end

  def conferences_cached #: Array[untyped]
    Rails.cache.fetch("ruby-conferences/_data/conferences.yml", expires_in: 1.day) do
      conferences
    end
  end
end