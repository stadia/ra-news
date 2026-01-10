class AddSocialPostIdsToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :social_post_ids, :jsonb, default: {}
  end
end
