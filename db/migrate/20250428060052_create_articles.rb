class CreateArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :articles do |t|
      t.string :title
      t.string :url
      t.references :user, null: true

      t.timestamps
    end
  end
end
