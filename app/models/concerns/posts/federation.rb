# typed: true
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
    if (parent_local = parent)
      custom["inReplyTo"] = parent_local.federated_url || parent_local.public_url
    elsif (article_local = article)
      custom["inReplyTo"] = article_local.federated_url || Rails.application.routes.url_helpers.article_url(article_local)
    end

    if tag_list.any?
      custom["tag"] = tag_list.map do |name|
        { "type" => "Hashtag", "name" => "##{name}", "href" => Rails.application.routes.url_helpers.tag_url(keyword: name) }
      end
    end

    if media_attachments.any?
      custom["attachment"] = media_attachments
    end

    content = body
    name = nil

    if blog?
      content = blog_federation_content
      name = title
      custom["url"] = public_url
    end

    Fedipub::DataTransformer::Note.to_federation(self, content: content, name: name, custom: custom)
  end

  # Remote timelines only get the summary, so the original URL rides along in
  # the content itself - most clients render `content` but hide `url`.
  # blog_summary comes out of FullSanitizer, so its text is already entity-encoded.
  #: () -> String
  def blog_federation_content
    url = ERB::Util.html_escape(public_url)
    "<p>#{blog_summary}</p><p><a href=\"#{url}\">#{url}</a></p>"
  end

  # Public, human-readable URL for this post. Blog posts live under the account
  # namespace (/@user/blog/:slug); everything else at /posts/:slug.
  #: () -> String
  def public_url
    if blog? && (u = user)
      Rails.application.routes.url_helpers.user_profile_blog_post_url(username: u.username, slug: self)
    else
      Rails.application.routes.url_helpers.post_url(self)
    end
  end
end
