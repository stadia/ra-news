# frozen_string_literal: true

# sites.url 을 추가하고 기존 base_uri + path 조합으로 역산해 채운다.
#
# 백필을 애플리케이션 모델(Site) 대신 순수 SQL 로 수행한다. 마이그레이션은
# "그 시점의 스키마"에 고정되어야 하는데, 모델 상수를 참조하면 이후 Site 에
# 추가되는 검증/콜백/enum 이 과거 마이그레이션 재실행(신규 환경의 db:migrate)
# 시점에 함께 로드되어 깨질 수 있다.
class AddUrlToSites < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :url, :string

    reversible do |dir|
      dir.up do
        # [base_uri, path].compact.join 과 동일 — path 가 NULL 이면 base_uri 만 사용
        execute <<~SQL.squish
          UPDATE sites
          SET url = base_uri || COALESCE(path, '')
          WHERE base_uri IS NOT NULL AND base_uri <> ''
        SQL
      end
    end
  end
end
