# frozen_string_literal: true
# rbs_inline: enabled

# Inbound ActivityPub parsing for Post: turns a remote Note hash into local
# attributes, resolving the reply target (article comment, post reply, or
# federated parent) and extracting body/attachments/hashtags.
#
# Symmetric to the outbound serialization in Posts::Federation. Kept out of Post
# itself so the model stays focused on persistence, enums, scopes, and callbacks.
module Posts::FederationIngest
  extend ActiveSupport::Concern

  class_methods do
    #: (Hash[String, untyped]) -> Hash[Symbol, untyped]
    def from_activitypub_object(hash)
      in_reply_to = hash["inReplyTo"].to_s
      attachments = Array.wrap(hash["attachment"]).select { |a| a.is_a?(Hash) && (a["type"] == "Document" || a["type"] == "Image") }

      object = {
        federated_url: hash["id"],
        url: hash["url"],
        title: hash["summary"].presence,
        body: extract_body_from_activitypub_object(hash, attachments:)
      }

      object.merge!(reply_attributes(in_reply_to)) if in_reply_to.present?

      # Mastodon 이미지 첨부 파싱
      object[:media_attachments] = attachments.map do |a|
        { "url" => a["url"], "mediaType" => a["mediaType"], "name" => a["name"] }.compact
      end

      # Mastodon 해시태그 파싱
      hashtags = Array.wrap(hash["tag"]).select { |t| t.is_a?(Hash) && t["type"] == "Hashtag" }
      object[:tag_list] = hashtags.map { |t| t["name"].to_s.delete_prefix("#") }.uniq.join(", ") if hashtags.any?

      object
    end

    private

    # Resolves the reply target (article comment, post reply, or federated
    # parent) from an inReplyTo URL into attributes for from_activitypub_object.
    # Inbound replies to an article are typed :comment so they stay in the
    # `comments` scope instead of defaulting to :short.
    #: (String) -> Hash[Symbol, untyped]
    def reply_attributes(in_reply_to)
      attrs = reply_target_attributes(in_reply_to)
      attrs[:post_type] = :comment if attrs[:article_id].present?
      attrs
    end

    #: (String) -> Hash[Symbol, untyped]
    def reply_target_attributes(in_reply_to)
      # Numeric-id branches only for local hosts: a remote UUID like
      # /articles/019f... would otherwise capture leading digits as a bogus
      # local id → FK violation.
      if local_reply_target?(in_reply_to) && (article_id = in_reply_to[%r{/articles/(\d+)}, 1])
        { article_id: article_id }
      elsif local_reply_target?(in_reply_to) && (post_id = in_reply_to[%r{/posts/(\d+)}, 1])
        { parent_id: post_id, article_id: Post.where(id: post_id).pick(:article_id) }
      elsif (parent = Post.find_by(federated_url: in_reply_to))
        { parent_id: parent.id, article_id: parent.article_id }
      else
        # Unresolved inReplyTo: stored standalone — log so orphans are visible.
        logger.debug { "reply_target_attributes: unresolved inReplyTo #{in_reply_to.inspect}; storing reply without parent/article" }
        {}
      end
    end

    # Exact host match, not substring: a URL merely embedding a local host
    # (ruby-news.dev.attacker.example) must not count as local. The app serves
    # both locale hosts, so Hosts.local_host? is authoritative; the configured
    # routing host is a fallback for envs served elsewhere (test on example.com).
    #: (String) -> bool
    def local_reply_target?(in_reply_to)
      host = URI.parse(in_reply_to).host
      return false if host.blank?
      return true if Hosts.local_host?(host)

      configured_host = Rails.application.routes.default_url_options[:host]
      return host == configured_host if configured_host.present?

      # Blank routing host is a misconfiguration; log so local replies aren't
      # silently reclassified as remote and orphaned.
      logger.error { "local_reply_target? cannot classify #{in_reply_to.inspect}: #{host.inspect} is not a known app host and default_url_options[:host] is blank" }
      false
    rescue URI::InvalidURIError
      false
    end

    #: (Hash[String, untyped], attachments: Array[Hash[String, untyped]]) -> String
    def extract_body_from_activitypub_object(hash, attachments:)
      localized_content = hash["contentMap"]
        .then { |content_map| content_map.is_a?(Hash) ? content_map.values : [] }
        .filter_map { |value| value.to_s.squish.presence }
        .first

      body = localized_content || hash["content"].to_s.squish.presence || hash["summary"].to_s.squish.presence
      return body if body.present?

      attachment_names = attachments.filter_map { |attachment| attachment["name"].to_s.squish.presence }
      attachment_names.join(" · ").presence || I18n.t("posts.remote_attachment_only_body")
    end

    #: (Hash[String, untyped]) -> bool
    def handle_federated_object?(hash)
      in_reply_to = hash["inReplyTo"].to_s

      # inReplyTo가 없으면 원문 → 수락
      return true if in_reply_to.blank?

      # inReplyTo가 로컬 post 또는 article을 가리키면 수락
      if local_reply_target?(in_reply_to)
        return true if in_reply_to.include?("/posts/") || in_reply_to.include?("/articles/")
      end

      # inReplyTo가 기존 post의 federated_url이면 수락
      Post.exists?(federated_url: in_reply_to)
    end
  end
end
