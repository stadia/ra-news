# frozen_string_literal: true
# rbs_inline: enabled

class RubyConference < ApplicationClient
  URL = "https://raw.githubusercontent.com/ruby-conferences/ruby-conferences.github.io/refs/heads/main"

  def initialize #: RubyConference
    super(url: URL)
  end

  def conferences #: Array[untyped]
    YAML.load(get("/_data/conferences.yml").body, permitted_classes: [Date])
  end

  def conferences_cached #: Array[untyped]
    Rails.cache.fetch("ruby-conferences/_data/conferences.yml", expires_in: 1.day) do
      conferences
    end
  end

  private

  def content_type #: String
    "text/yaml"
  end
end