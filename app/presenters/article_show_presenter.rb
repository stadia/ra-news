# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

# 기사 상세(show) 화면의 표시 판단을 모아둔다.
# display_summary_* 는 로케일 폴백에 따라 Hash/Array/nil 이 섞여 들어오므로,
# 뷰가 타입 분기를 하지 않도록 여기서 정규화한다.
class ArticleShowPresenter
  #: (Article article) -> void
  def initialize(article)
    @article = article
  end

  attr_reader :article

  #: () -> bool
  def hero_thumbnail?
    article.thumbnail.attached?
  end

  # 요약 핵심 항목. Array 가 아니면 렌더하지 않는다.
  #: () -> Array[untyped]
  def summary_key_items
    items = article.display_summary_key
    items.is_a?(Array) ? items : []
  end

  #: () -> bool
  def summary_key_items?
    summary_key_items.any?
  end

  # 상세 요약은 Hash 일 때만 본문/서론/결론을 렌더한다.
  #: () -> bool
  def summary_detail?
    article.display_summary_detail.is_a?(Hash)
  end

  #: () -> String?
  def introduction
    summary_detail_value("introduction")
  end

  #: () -> String?
  def conclusion
    summary_detail_value("conclusion")
  end

  #: () -> String?
  def summary_body
    return nil unless summary_detail?

    article.display_summary_body.presence
  end

  #: () -> String?
  def published_at_iso
    article.published_at&.iso8601
  end

  #: (?Symbol format) -> String?
  def published_at_label(format = :short)
    published_at = article.published_at
    return nil if published_at.nil?

    I18n.l(published_at, format:)
  end

  private

  #: (String key) -> String?
  def summary_detail_value(key)
    return nil unless summary_detail?

    article.display_summary_detail[key].presence
  end
end
