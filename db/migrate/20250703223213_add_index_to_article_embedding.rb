class AddIndexToArticleEmbedding < ActiveRecord::Migration[8.0]
  def change
    add_index :articles, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  end
end
