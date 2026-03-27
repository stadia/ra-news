class AddMediaAttachmentsToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :media_attachments, :jsonb, default: [], null: false
  end
end
