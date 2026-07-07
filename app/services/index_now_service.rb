# frozen_string_literal: true
# rbs_inline: enabled

# IndexNow API로 URL 리스트를 전송한다.
# 호스트별 keyLocation(https://<host>/<key>.txt)를 포함해 POST.
# 성공/실패 모두 로그만 남기고 raise하지 않는다(비재시도 정책).
class IndexNowService
  ENDPOINT = "https://api.indexnow.org/IndexNow"

  #: (host: String, urls: Array[String]) -> void
  def call(host:, urls:)
    return if urls.blank?

    key = Hosts::INDEX_NOW_KEY
    return if key.blank?

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
    )

    if response.status.to_i.between?(200, 299)
      Rails.logger.info("IndexNow ping success: host=#{host} urls=#{urls.size}")
    else
      Rails.logger.error("IndexNow ping failed: host=#{host} status=#{response.status} body=#{response.body}")
    end
  rescue StandardError => e
    Rails.logger.error("IndexNow ping error: host=#{host} #{e.class} - #{e.message}")
  end
end