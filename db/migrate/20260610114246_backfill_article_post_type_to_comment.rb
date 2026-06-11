# frozen_string_literal: true

# Backfills article-attached posts that were saved with the enum default
# :short (0) instead of :comment (2). Before this, the local comment creation
# path never set post_type, so comments dropped out of the `comments` scope
# (where(post_type: :comment)) and stopped rendering in the "최근 댓글" lists.
# The creation path is now fixed; this corrects the rows already written.
class BackfillArticlePostTypeToComment < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE posts
      SET post_type = 2
      WHERE article_id IS NOT NULL AND post_type <> 2
    SQL
  end

  def down
    # Irreversible: the original post_type of each affected row is not recorded,
    # so we cannot restore it. Leaving the corrected data in place is safe and
    # is the intended end state, so down is a no-op rather than a raise.
  end
end
