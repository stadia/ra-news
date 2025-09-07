class AddIsPostedToArticle < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :is_posted, :boolean, default: false, comment: '소셜에 게시되었는지 여부를 나타냅니다.'
  end
end
