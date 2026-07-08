# frozen_string_literal: true
# rbs_inline: enabled

# 기사 공개 URL을 IndexNow에 ping한다.
# Article after_commit에서 per-(article,host) 캐시 잠금과 함께 wait: 30s로 예약됨.
# 지연 실행 중 기사가 삭제되거나 unconfirmed가 되면 전송을 스킵한다.
class IndexNowJob < ApplicationJob
  queue_as :default

  #: (Integer article_id, String host) -> void
  def perform(article_id, host)
    article = Article.kept.find_by(id: article_id)
    return unless article
    return if article.slug.blank? || article.title_ko.blank?

    url = Rails.application.routes.url_helpers.article_url(
      article,
      host: host,
      protocol: "https"
    )
    IndexNowService.new.call(host: host, urls: [ url ])
  ensure
    Rails.cache.delete("index_now:enqueue:#{host}:#{article_id}")
  end
end
