# frozen_string_literal: true

# 과거에 federails_actor_id 가 비워진 채 생성된 기사(약 1,214건)를 발행 봇 actor 로 채운다.
#
# 런타임에는 Article#federails_actor 가 bot_user.federails_actor 로 폴백하도록
# 이미 수정했지만(NoMethodError 방지), federails published 직렬화가 컬럼을 직접
# 참조하는 경로가 있어 데이터 정합성까지 맞춰 둔다. 기사의 actor 는 항상 발행 봇
# actor 이므로(acts_as_federails_data actor_entity_method: :bot_user) 안전하다.
class BackfillArticlesFederailsActor < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    bot_actor_id = select_value(<<~SQL).to_i
      SELECT fa.id
      FROM federails_actors fa
      JOIN users u ON u.id = fa.entity_id AND fa.entity_type = 'User'
      WHERE 'bot' = ANY (u.roles)
      ORDER BY u.id ASC
      LIMIT 1
    SQL

    if bot_actor_id.zero?
      say "발행 봇 actor 를 찾지 못해 백필을 건너뜁니다"
      return
    end

    say_with_time "articles.federails_actor_id 백필 (actor=#{bot_actor_id})" do
      total = 0
      loop do
        # 배치로 나눠 장기 락을 피한다
        affected = exec_update(<<~SQL)
          UPDATE articles
          SET federails_actor_id = #{bot_actor_id}
          WHERE id IN (
            SELECT id FROM articles WHERE federails_actor_id IS NULL LIMIT 1000
          )
        SQL
        total += affected
        break if affected.zero?
      end
      total
    end
  end

  def down
    # 되돌릴 수 없음: 백필 이전에 어떤 행이 NULL 이었는지 알 수 없어
    # 임의로 NULL 로 되돌리면 정상 데이터까지 훼손된다.
    raise ActiveRecord::IrreversibleMigration
  end
end
