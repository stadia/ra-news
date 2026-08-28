# fedipub 0.9.0의 Fedipub::DataEntity는 `belongs_to :fedipub_actor`를 선언하므로
# 앱이 소유한 참조 컬럼도 함께 리네임해야 한다.
# 참고: fedipub MIGRATION_GUIDE.md "From 0.8.0 to 0.9.0" 1번 항목.
class RenameFederailsActorToFedipubActor < ActiveRecord::Migration[8.1]
  TABLES = %i[articles posts].freeze

  def change
    TABLES.each do |table|
      rename_column table, :federails_actor_id, :fedipub_actor_id
    end
  end
end
