class JapaneseTempJob < ApplicationJob
  def perform(id: nil, slug: nil)
    if id.present? || slug.present?
      article = Article.find_by(id:)
      article = Article.find_by(slug:) if article.nil?
      ArticleAgentsService.new.send(:run_japanese, article)
      return
    end

    Article.kept.confirmed.where(title_ja: nil).order("created_at desc").limit(2).each do |article|
      ArticleAgentsService.new.send(:run_japanese, article)
      sleep 5
    end
  end
end
