# frozen_string_literal: true
# rbs_inline: enabled

# 기사 공개 URL을 IndexNow에 ping한다.
# Article after_commit에서 per-article 캐시 잠금과 함께 wait: 30s로 예약됨.
# 지연 실행 중 기사가 삭제되거나 unconfirmed가 되면 전송을 스킵한다.
# IndexNow는 host 1개당 POST 1개를 요구하므로, 본 잡이 Hosts::INDEX_NOW_HOSTS를
# 순회하며 각 호스트의 정규 URL로 개별 ping한다.
class IndexNowJob < ApplicationJob
  queue_as :default

  #: (Integer article_id) -> void
  def perform(article_id)
    article = Article.kept.find_by(id: article_id)
    return unless article
    return if article.slug.blank? || article.title_ko.blank?

    Hosts::INDEX_NOW_HOSTS.each do |host|
      url = Rails.application.routes.url_helpers.article_url(
        article,
        host: host,
        protocol: "https"
      )
      IndexNowService.new.call(host: host, urls: [ url ])
    end
  ensure
    Rails.cache.delete("index_now:enqueue:#{article_id}")
  end
end
