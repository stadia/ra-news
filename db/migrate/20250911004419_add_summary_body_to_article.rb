class AddSummaryBodyToArticle < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :summary_body, :text, comment: '원문 상세 요약'
    Article.kept.confirmed.find_each do |article|
      article.summary_body = article.summary_detail['body']
      article.save!
    end
  end
end
