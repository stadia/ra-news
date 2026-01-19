class ChangeEmbeddingFromArticle < ActiveRecord::Migration[8.0]
  def up
    # 기존 컬럼 삭제
    remove_column :articles, :embedding
    # 새로운 크기로 컬럼 생성 (예: 1536 차원)
    execute "ALTER TABLE articles ADD COLUMN embedding vector(1536);"
  end

  def down
    # 이전 크기로 되돌리기
    remove_column :articles, :embedding
    execute "ALTER TABLE articles ADD COLUMN embedding vector(768);"
  end
end
