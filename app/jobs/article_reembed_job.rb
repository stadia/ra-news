# frozen_string_literal: true
# rbs_inline: enabled

# 임베딩 모델 교체 후 기존 기사 벡터를 현재 모델로 재생성하는 잡.
# article_ids 묶음을 받아 in-place 로 embedding 을 덮어쓴다.
# 모델/차원은 Articles::HybridSearch 의 공개 상수를 단일 출처로 사용한다.
class ArticleReembedJob < ApplicationJob
  queue_as :default

  EMBED_MODEL = Articles::HybridSearch::EMBED_MODEL
  EMBED_DIMENSIONS = Articles::HybridSearch::EMBED_DIMENSIONS

  # 임베딩 API rate limit 완화를 위한 호출 간 대기(초).
  THROTTLE = 0.2

  #: (Array[Integer] article_ids) -> void
  def perform(article_ids)
    Article.kept.where(id: article_ids).where.not(body: nil).find_each do |article|
      reembed(article)
      sleep THROTTLE
    rescue StandardError => e
      # 한 건 실패가 배치 전체를 멈추지 않도록 기사별로 격리한다.
      logger.error("ArticleReembedJob: failed for article #{article.id}: #{e.class} - #{e.message}")
    end
  end

  private

  #: (Article article) -> void
  def reembed(article)
    return if article.body.blank?

    vectors = RubyLLM.embed(article.body, model: EMBED_MODEL, dimensions: EMBED_DIMENSIONS).vectors.to_a
    article.update_column(:embedding, vectors) # rubocop:disable Rails/SkipsModelValidations
    logger.info("ArticleReembedJob: re-embedded article #{article.id}")
  end
end
