class OptimizeArticlesIndexForSlugTitle < ActiveRecord::Migration[8.0]
def up
      # 기존 인덱스 확인
      remove_index :articles, name: :index_articles_on_deleted_at_and_id
      remove_index :articles, name: :index_articles_on_title_ko

      # 새로운 복합 인덱스 (정렬 포함)
      add_index :articles,
                [ :deleted_at, :slug, :title_ko, :id ],
                where: "deleted_at IS NULL AND slug IS NOT NULL AND title_ko IS NOT NULL",
                comment: "Optimized for listing articles with slug and title"
    end

    def down
      remove_index :articles, :index_articles_on_deleted_at_and_slug_and_title_ko_and_id
    end
end
