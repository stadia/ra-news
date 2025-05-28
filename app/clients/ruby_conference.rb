# frozen_string_literal: true

# rbs_inline: enabled

class RubyConference < ApplicationClient
    BASE_URI = "https://raw.githubusercontent.com/ruby-conferences/ruby-conferences.github.io/refs/heads/main"

    def initialize #: RubyConference
      @base_uri = BASE_URI
    end

    def conferences #: Array<Hash>
      YAML.load(get("/_data/conferences.yml").body, permitted_classes: [ Date ])
    end

    def conferences_cached #: Array<Hash>
      Rails.cache.fetch("ruby-conferences/_data/conferences.yml", expires_in: 1.day) do
        conferences
      end
    end

    private

    def content_type #: String
      "text/yaml"
    end
end
