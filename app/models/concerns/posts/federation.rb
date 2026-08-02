# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

# ActivityPub serialization for Post: builds the outgoing Note object and the
# canonical public URL advertised to remote servers.
#
# Kept out of Post itself so the model stays focused; the enums, scopes, and
# federation callbacks remain on Post.
module Posts::Federation
  extend ActiveSupport::Concern

  #: () -> Hash[String, untyped]
  def to_activitypub_object
    custom = {}
    if parent.present?
      custom["inReplyTo"] = parent.federated_url || parent.public_url
    elsif article.present?
      custom["inReplyTo"] = article.federated_url || Rails.application.routes.url_helpers.article_url(article)
    end

    if tag_list.any?
      custom["tag"] = tag_list.map do |name|
        { "type" => "Hashtag", "name" => "##{name}", "href" => "#{Rails.application.routes.default_url_options[:host]}/tags/#{name}" }
      end
    end

    if media_attachments.any?
      custom["attachment"] = media_attachments
    end

    content = body
    name = nil

    if blog?
      content = blog_summary
      name = title
      custom["url"] = public_url
    end

    Federails::DataTransformer::Note.to_federation(self, content: content, name: name, custom: custom)
  end

  # Public, human-readable URL for this post. Blog posts live under the account
  # namespace (/@user/blog/:slug); everything else at /posts/:slug.
  #: () -> String
  def public_url
    if blog? && user
      Rails.application.routes.url_helpers.user_profile_blog_post_url(username: user.username, slug: self)
    else
      Rails.application.routes.url_helpers.post_url(self)
    end
  end
end
