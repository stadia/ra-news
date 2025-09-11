class AddSummaryBodyToArticle < ActiveRecord::Migration[8.0]
  def up
    add_column :articles, :summary_body, :text, comment: '원문 상세 요약'
    Article.kept.confirmed.find_each do |article|
      body_content = article.summary_detail['body']
      body_content = body_content.gsub(/\\\\/, "\x00TEMP_BACKSLASH\x00") # 임시로 \\\\ 보호
      body_content = body_content.gsub(/\\n/, "\n")   # \\n을 실제 줄바꿈으로
      body_content = body_content.gsub(/\\r\\n/, "\n") # \\r\\n을 줄바꿈으로
      body_content = body_content.gsub(/\\r/, "")     # \\r 제거
      body_content = body_content.gsub(/\\t/, "  ")   # \\t를 스페이스 2개로
      body_content = body_content.gsub(/\\"/, '"')    # \\" 를 " 로
      body_content = body_content.gsub(/\x00TEMP_BACKSLASH\x00/, "\\") # 임시 보호한 \\ 복원

      article.update(summary_body: body_content)
    end
  end

  def down
    remove_column :articles, :summary_body
  end
end
