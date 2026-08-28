# This migration comes from fedipub (originally 20241002094501)
# Superseded by db/migrate/20260330052834_init_schema.rb, which already creates this schema.
# 비워 두는 이유는 fedipub MIGRATION_GUIDE.md의 "If your app squashed its migration history" 참고.
class AddKeypairToActors < ActiveRecord::Migration[7.0]
  def change; end
end
