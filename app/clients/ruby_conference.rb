# frozen_string_literal: true
# rbs_inline: enabled

module RubyConference
  module_function

  BASE_URL = "https://raw.githubusercontent.com/ruby-conferences/ruby-conferences.github.io/refs/heads/main"
  OPEN_TIMEOUT = 5 #: Integer
  REQUEST_TIMEOUT = 10 #: Integer

  def conferences #: Array[untyped]
    response = Faraday.get("#{BASE_URL}/_data/conferences.yml") do |req|
      req.options.open_timeout = OPEN_TIMEOUT
      req.options.timeout = REQUEST_TIMEOUT
    end
    YAML.load(response.body, permitted_classes: [ Date ])
  end

  def conferences_cached #: Array[untyped]
    Rails.cache.fetch("ruby-conferences/_data/conferences.yml", expires_in: 1.day) do
      conferences
    end
  end
end
