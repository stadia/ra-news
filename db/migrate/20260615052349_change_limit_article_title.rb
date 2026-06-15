class ChangeLimitArticleTitle < ActiveRecord::Migration[8.1]
  def up
    disable_parallel_scan

    # `title`을 varchar(200)로 좁히기 전에, 초과하는 기존 레코드(주로 GitHub OG title)를
    # 안전하게 잘라둔다. 197자 + "..."로 setter(truncate_title)의 출력 형태와 맞춘다.
    execute(<<~SQL.squish)
      UPDATE articles
      SET title = LEFT(title, 197) || '...'
      WHERE title IS NOT NULL AND LENGTH(title) > 200
    SQL

    change_column :articles, :title,    :string, limit: 200
    change_column :articles, :title_ko, :string, limit: 200
    change_column :articles, :title_ja, :string, limit: 200
  end

  def down
    disable_parallel_scan

    change_column :articles, :title,    :string, limit: nil
    change_column :articles, :title_ko, :string, limit: 100
    change_column :articles, :title_ja, :string, limit: 150
  end

  private

  # articles 테이블은 halfvec3072 embedding 컬럼이 있어, varchar 길이 검증 시
  # parallel scan이 큰 동적 공유 메모리 세그먼트를 요청하다 실패할 수 있다.
  # 트랜잭션 범위에서 parallel 워커를 꺼서 회피한다.
  def disable_parallel_scan
    execute "SET LOCAL max_parallel_workers_per_gather = 0"
    execute "SET LOCAL max_parallel_maintenance_workers = 0"
  end
end
