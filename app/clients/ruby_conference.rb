# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

module RubyConference
  module_function

  BASE_URL = "https://raw.githubusercontent.com/ruby-conferences/ruby-conferences.github.io/refs/heads/main"

  #: () -> Array[untyped]
  def conferences
    response = Faraday.get("#{BASE_URL}/_data/conferences.yml") do |req|
      req.options.open_timeout = HttpTimeouts::OPEN
      req.options.timeout = HttpTimeouts::REQUEST
    end
    # Faraday는 4xx/5xx에 예외를 던지지 않는다. 에러 본문을 YAML.load하면 Array 계약이
    # 깨지므로(Psych 오류/예상 밖 값), 실패 시 로깅 후 빈 배열로 정규화한다.
    unless response.success?
      Rails.logger.warn("RubyConference: 컨퍼런스 데이터 조회 실패 (status=#{response.status})")
      return []
    end
    YAML.load(response.body, permitted_classes: [ Date ]) || []
  end

  #: () -> Array[untyped]
  def conferences_cached
    Rails.cache.fetch("ruby-conferences/_data/conferences.yml", expires_in: 1.day) do
      conferences
    end
  end
end
