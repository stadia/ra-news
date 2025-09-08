class AddVectorBody < ActiveRecord::Migration[8.0]
  def up
    unless Rails.env.test?
      enable_extension "vector"
      execute "ALTER TABLE articles ADD COLUMN embedding vector(768);"
    end
  end

  def down
    remove_column :articles, :embedding, :vector unless Rails.env.test?
  end
end
