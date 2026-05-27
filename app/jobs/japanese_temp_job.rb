class JapaneseTempJob < ApplicationJob
  def perform
    Article.kept.confirmed.where(title_ja: nil).order("created_at desc").limit(2).each do |article|
      ArticleAgentsService.new.send(:run_japanese, article)
      sleep 5
    end
  end
end
