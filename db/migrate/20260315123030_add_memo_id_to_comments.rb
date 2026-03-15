class AddMemoIdToComments < ActiveRecord::Migration[8.1]
  def change
    # memo_id는 선택적(nullable) - article 또는 memo 중 하나에 속함
    add_reference :comments, :memo, null: true, foreign_key: true
    # article_id도 nullable로 변경하여 memo 댓글 지원
    change_column_null :comments, :article_id, true
  end
end
