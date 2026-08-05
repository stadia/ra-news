# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

# IndexNow API로 URL 리스트를 전송한다.
# 호스트별 keyLocation(https://<host>/<key>.txt)를 포함해 POST.
# 성공/실패를 Dry::Monads::Result로 반환한다(비재시도 정책 — raise하지 않고 Failure로 전달).
# 호출 측은 result.success? / result.failure로 받되, 로그는 이 서비스가 남긴다.
class IndexNowService < OperationService
  ENDPOINT = "https://api.indexnow.org/IndexNow"

  #: (host: String, urls: Array[String]) -> Dry::Monads::Result
  def call(host:, urls:)
    step validate(host, urls)
    step ping(host, urls)
  end

  protected

  # Dry::Operation의 call에서 return Failure(...)를 직접 반환하면 Success(Failure(...))로 감싸지므로
  # guard clause는 반드시 step으로 호출되는 별도 메서드에 위치시킨다.
  #: (String host, Array[String] urls) -> Dry::Monads::Result
  def validate(host, urls)
    return Failure(:blank_urls) if urls.blank?
    return Failure(:not_configured) if Hosts::INDEX_NOW_KEY.blank?

    Success(host)
  end

  #: (String host, Array[String] urls) -> Dry::Monads::Result
  def ping(host, urls)
    key = Hosts::INDEX_NOW_KEY
    payload = {
      host: host,
      key: key,
      keyLocation: "https://#{host}/#{key}.txt",
      urlList: urls
    }

    response = Faraday.post(
      ENDPOINT,
      payload.to_json,
      { "Content-Type" => "application/json; charset=utf-8" }
    ) do |req|
      req.options.open_timeout = 5
      req.options.timeout = 10
    end

    if response.status.between?(200, 299)
      logger.info("IndexNow ping success: host=#{host} urls=#{urls.size}")
      Success(host)
    else
      logger.error("IndexNow ping failed: host=#{host} status=#{response.status} body=#{response.body}")
      Failure(:http_error)
    end
  rescue StandardError => e
    logger.error("IndexNow ping error: host=#{host} #{e.class} - #{e.message}")
    Failure(:network_error)
  end
end
