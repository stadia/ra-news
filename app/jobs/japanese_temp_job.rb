# rbs_inline: enabled

class JapaneseTempJob < ApplicationJob
  def perform(id: nil, slug: nil)
    if id.present? || slug.present?
      article = Article.find_by(id:)
      article = Article.find_by(slug:) if article.nil?
      ArticleAgentsService.new.send(:run_japanese, article)
      run_similar(article)
      return
    end

    # 번역 완료 신호는 summary_key_ja (title_ja 는 일본어 원문 제목으로 미리 채워질 수 있음)
    article = Article.kept.confirmed.where(summary_key_ja: nil).order("created_at desc").limit(1).first
    return if article.nil?

    article.discard! and return if article.title.nil?

    article.title = Articles::Utils.truncate_title(article.title) if article.title.size > 120
    ArticleAgentsService.new.send(:run_japanese, article)
    run_similar(article)
  end

  def run_similar(article)
    similar_articles = Article.kept.confirmed.where.not(id: article.id).nearest_neighbors(:embedding, article.embedding, distance: "cosine").limit(4)
    similar_articles.each { |item|
      next if item.summary_key_ja.present?

      item.title = Articles::Utils.truncate_title(item.title) if item.title.present? && item.title.size > 120
      ArticleAgentsService.new.send(:run_japanese, item)
    }
  end
end
