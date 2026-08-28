# This migration comes from fedipub (originally 20260309022820)
# Superseded by db/migrate/20260330052834_init_schema.rb, which already creates this schema.
# 비워 두는 이유는 fedipub MIGRATION_GUIDE.md의 "If your app squashed its migration history" 참고.
class AddFederatedUrlToFederailsActivities < ActiveRecord::Migration[7.2]
  def change; end
end
