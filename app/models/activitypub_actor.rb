# frozen_string_literal: true

# rbs_inline: enabled

class ActivitypubActor < ApplicationRecord
  include Discard::Model

  belongs_to :site, optional: true
  
  validates :username, presence: true, uniqueness: { scope: :domain }
  validates :domain, presence: true
  validates :private_key, :public_key, presence: true

  before_validation :generate_keypair, on: :create
  before_validation :set_defaults, on: :create

  def actor_url #: String
    "https://#{domain}/activitypub/actors/#{username}"
  end

  def public_key_url #: String
    "#{actor_url}#main-key"
  end

  def outbox_url #: String
    "#{actor_url}/outbox"
  end

  def inbox_url #: String
    "#{actor_url}/inbox"
  end

  def to_activitypub #: Hash[String, untyped]
    {
      "@context": [
        "https://www.w3.org/ns/activitystreams",
        "https://w3id.org/security/v1"
      ],
      "type": "Service",
      "id": actor_url,
      "preferredUsername": username,
      "name": display_name || username,
      "summary": bio || "RA-News 뉴스 집계 서비스",
      "url": site&.base_uri || actor_url,
      "inbox": inbox_url,
      "outbox": outbox_url,
      "publicKey": {
        "id": public_key_url,
        "owner": actor_url,
        "publicKeyPem": public_key
      }
    }
  end

  def create_article_activity(article) #: (Article) -> Hash[String, untyped]
    {
      "@context": "https://www.w3.org/ns/activitystreams",
      "type": "Create",
      "id": "#{actor_url}/activities/create/#{article.id}",
      "actor": actor_url,
      "published": Time.current.utc.iso8601,
      "object": {
        "type": "Article",
        "id": Rails.application.routes.url_helpers.article_url(article, host: domain),
        "name": article.title_ko || article.title,
        "content": format_article_content(article),
        "url": article.url,
        "published": article.published_at&.utc&.iso8601,
        "attributedTo": actor_url,
        "tag": article.tag_list.map { |tag| 
          {
            "type": "Hashtag",
            "name": "##{tag}",
            "href": Rails.application.routes.url_helpers.articles_url(tag: tag, host: domain)
          }
        }
      }
    }
  end

  private

  def generate_keypair #: void
    return if private_key.present? && public_key.present?

    rsa_key = OpenSSL::PKey::RSA.new(2048)
    self.private_key = rsa_key.to_pem
    self.public_key = rsa_key.public_key.to_pem
  end

  def set_defaults #: void
    self.domain ||= Rails.application.config.hosts.first || "localhost:3000"
    self.display_name ||= site&.name || username
    self.bio ||= site&.description if site
  end

  def format_article_content(article) #: (Article) -> String
    content = article.summary_detail.presence || article.summary_key.presence || article.body.presence
    return "" unless content

    # Add original URL reference
    content += "\n\n원문: #{article.url}" if article.url.present?
    
    # Convert to HTML if needed and truncate for ActivityPub
    if content.length > 500
      content[0..497] + "..."
    else
      content
    end
  end
end