class AddVectorBody < ActiveRecord::Migration[8.0]
  def up
    enable_extension "vector" unless Rails.env.test?
    execute "ALTER TABLE articles ADD COLUMN embedding vector(768);"
  end

  def down
    remove_column :articles, :embedding, :vector
  end
end
