# frozen_string_literal: true

class AddGroundingToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :grounding_score, :float
    add_column :articles, :grounding_flagged, :boolean, default: false, null: false
    add_column :articles, :grounding_checked_at, :datetime
    add_column :articles, :grounding_issues, :jsonb

    add_index :articles, :grounding_flagged,
              where: "grounding_flagged = true",
              name: "index_articles_on_grounding_flagged"
  end
end
