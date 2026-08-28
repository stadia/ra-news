# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

module Profiles
  module PolymorphicActivity
    class << self
      #: (Array[[String, Integer]]) -> Array[Article | Post]
      def resolve(type_id_pairs)
        return [] if type_id_pairs.blank?

        article_ids = type_id_pairs.select { |type, _| type == "Article" }.map(&:last)
        post_ids    = type_id_pairs.select { |type, _| type == "Post" }.map(&:last)

        articles_by_id = Article.kept.where(id: article_ids)
                                .includes(:user, :site, :tags).index_by(&:id)
        posts_by_id = Post.where(id: post_ids)
                          .includes(:user, :fedipub_actor, :article, :tags).index_by(&:id)

        type_id_pairs.map { |type, id|
          case type
          when "Article" then articles_by_id[id]
          when "Post"    then posts_by_id[id]
          end
        }.compact
      end
    end
  end
end
