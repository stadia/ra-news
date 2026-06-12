class JapaneseTempJob < ApplicationJob
  def perform(id: nil, slug: nil)
    if id.present? || slug.present?
      article = Article.find_by(id:)
      article = Article.find_by(slug:) if article.nil?
      ArticleAgentsService.new.send(:run_japanese, article)
      run_similar(article)
      return
    end

    article = Article.kept.confirmed.where(title_ja: nil).order("created_at desc").limit(1).first
    article.title = Articles::Utils.truncate_title(article.title) if article.title.size > 120
    ArticleAgentsService.new.send(:run_japanese, article)
    run_similar(article)
  end

  def run_similar(article)
    similar_articles = Article.kept.confirmed.where.not(id: article.id).nearest_neighbors(:embedding, article.embedding, distance: "cosine").limit(4)
    similar_articles.each { |item|
      next if item.title_ja.present?

      item.title = Articles::Utils.truncate_title(item.title)
      ArticleAgentsService.new.send(:run_japanese, item)
    }
  end
end
