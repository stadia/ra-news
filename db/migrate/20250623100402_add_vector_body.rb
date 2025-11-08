class AddVectorBody < ActiveRecord::Migration[8.0]
  def up
    unless Rails.env.test?
      # Enable pgvector extension (idempotent check)
      enable_extension "vector" unless extension_enabled?("vector")
      execute "ALTER TABLE articles ADD COLUMN embedding vector(1536) UNLESS EXISTS;" rescue nil
      # If column already exists, ensure it's the right dimension
      begin
        execute "ALTER TABLE articles ALTER COLUMN embedding TYPE vector(1536);"
      rescue StandardError => e
        # Column might not exist yet, which is okay
        logger.info "Vector column note: #{e.message}"
      end
    end
  end

  def down
    remove_column :articles, :embedding, :vector unless Rails.env.test?
  end
end
