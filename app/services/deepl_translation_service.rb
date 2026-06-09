# frozen_string_literal: true
# rbs_inline: enabled

# 한국어 기사 결과물을 DeepL API로 일본어 번역한다.
# 무료 한도 초과(HTTP 456) 시 Failure(:quota_exceeded)를 반환해
# 호출 측이 ArticleJapaneseAgent로 폴백하도록 한다.
class DeeplTranslationService
  include Dry::Monads[:result]

  QUOTA_EXCEEDED_STATUS = 456
  SOURCE_LANG = "KO"
  TARGET_LANG = "JA"

  Error = Class.new(StandardError)
  QuotaExceeded = Class.new(Error)

  #: (Article article) -> Dry::Monads::Result
  def call(article)
    return Failure(:not_configured) if api_key.blank?

    keys = Array(article.summary_key).map(&:to_s).reject(&:blank?)
    detail = article.summary_detail || {}
    scalars = {
      title_ja: article.title_ko.to_s,
      introduction: detail["introduction"].to_s,
      conclusion: detail["conclusion"].to_s,
      summary_body_ja: article.summary_body.to_s
    }

    inputs = scalars.values + keys
    outputs = translate(inputs)
    return Failure(:deepl_error) if outputs.size != inputs.size

    scalar_out = scalars.keys.zip(outputs.first(scalars.size)).to_h
    Success(
      title_ja: scalar_out[:title_ja].strip,
      summary_key_ja: outputs.last(keys.size).map { |t| t.to_s.strip }.reject(&:blank?),
      summary_detail_ja: {
        "introduction" => scalar_out[:introduction].strip,
        "conclusion" => scalar_out[:conclusion].strip
      },
      summary_body_ja: scalar_out[:summary_body_ja].strip
    )
  rescue QuotaExceeded
    logger.warn "DeepL quota exceeded for article #{article.id}"
    Failure(:quota_exceeded)
  rescue Error => e
    logger.warn "DeepL translation failed for article #{article.id}: #{e.message}"
    Failure(:deepl_error)
  end

  protected

  #: (Array[String] texts) -> Array[String]
  def translate(texts)
    # DeepL은 빈 문자열을 거부할 수 있어 공백으로 치환해 인덱스 정렬을 유지한다.
    payload = texts.map { |text| text.presence || " " }

    response = connection.post(endpoint) do |req|
      req.headers["Authorization"] = "DeepL-Auth-Key #{api_key}"
      req.headers["Content-Type"] = "application/json"
      req.body = { text: payload, source_lang: SOURCE_LANG, target_lang: TARGET_LANG }.to_json
    end

    raise QuotaExceeded if response.status == QUOTA_EXCEEDED_STATUS
    raise Error, "status #{response.status}: #{response.body}" unless response.success?

    Array(JSON.parse(response.body)["translations"]).map { |t| t["text"].to_s }
  rescue Faraday::Error => e
    raise Error, e.message
  end

  private

  #: () -> ActiveSupport::Logger
  def logger
    Rails.logger
  end

  #: () -> Faraday::Connection
  def connection
    @connection ||= Faraday.new { |f| f.options.timeout = 30 }
  end

  #: () -> String
  def endpoint
    host = api_key.to_s.end_with?(":fx") ? "https://api-free.deepl.com" : "https://api.deepl.com"
    "#{host}/v2/translate"
  end

  #: () -> String?
  def api_key
    ENV.fetch("DEEPL_API_KEY", nil)
  end
end
