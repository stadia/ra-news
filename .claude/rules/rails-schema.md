---
paths:
  - "db/schema.rb"
  - "db/migrate/**"
---

# Database Tables (28)

_Snapshot - may be stale after migrations. Use `rails_get_schema(table:"name")` for live data._

- **active_storage_attachments** (6 cols) - name:string, record_type:string, record_id:integer | FK: blob_id→active_storage_blobs | Idx: record_type+record_id+name+blob_id(unique)
- **active_storage_blobs** (9 cols) - key:string, filename:string, content_type:string, metadata:text, service_name:string, byte_size:integer, checksum:string | Idx: key(unique)
- **active_storage_variant_records** (3 cols) - variation_digest:string | FK: blob_id→active_storage_blobs | Idx: blob_id+variation_digest(unique)
- **articles** (31 cols) - title:string, url:string, summary_key:jsonb, summary_detail:jsonb, title_ko:string, published_at:datetime, deleted_at:datetime, origin_url:string(=""), host:string, slug:string, is_youtube:boolean(=false), is_related:boolean(=false), body:text, embedding:halfvec, is_posted:boolean(=false), summary_body:text, social_post_ids:jsonb(={}), posts_count:integer(=0), federated_url:string, likers_count:integer(=0), title_ja:string, summary_key_ja:jsonb, summary_detail_ja:jsonb, summary_body_ja:text, boosters_count:integer(=0) | FK: site_id→sites, user_id→users, federails_actor_id→federails_actors | Idx: deleted_at+published_at+created_at, deleted_at+slug+title_ko+id, origin_url(unique), is_related+published_at, slug(unique), url(unique)
- **boosts** (5 cols) - boostable_type:string, boostable_id:integer | FK: actor_id→federails_actors | Idx: actor_id+boostable_type+boostable_id(unique), boostable_type+boostable_id
- **federails_activities** (16 cols) - entity_type:string, entity_id:integer, action:string, uuid:string, to:string, cc:string, federated_url:string, bto:string, bcc:string, audience:string, result:string, instrument:string | FK: actor_id→federails_actors | Idx: entity_type+entity_id, federated_url(unique), uuid(unique)
- **federails_actors** (24 cols) - name:string, federated_url:string, username:string, server:string, inbox_url:string, outbox_url:string, followers_url:string, followings_url:string, profile_url:string, entity_id:integer, entity_type:string, uuid:string, public_key:text, private_key:text, extensions:json, local:boolean(=false), actor_type:string, tombstoned_at:datetime, likees_count:integer(=0), shared_inbox_url:string, boostees_count:integer(=0) | Idx: entity_type+entity_id(unique), federated_url(unique), uuid(unique)
- **federails_blocks** (5 cols) | FK: target_actor_id→federails_actors, actor_id→federails_actors | Idx: actor_id+target_actor_id(unique)
- **federails_featured_items** (5 cols) - actor_id:integer, federated_url:string | Idx: actor_id+federated_url(unique)
- **federails_featured_tags** (5 cols) - actor_id:integer, name:string | Idx: actor_id+name(unique)
- **federails_followings** (8 cols) - status:integer(=0), federated_url:string, uuid:string | FK: actor_id→federails_actors, target_actor_id→federails_actors | Idx: actor_id+target_actor_id(unique), uuid(unique)
- **federails_hosts** (9 cols) - domain:string, nodeinfo_url:string, software_name:string, software_version:string, protocols:text(=[]), services:text(={}) | Idx: domain(unique)
- **friendly_id_slugs** (6 cols) - slug:string, sluggable_id:integer, sluggable_type:string, scope:string | Idx: slug+sluggable_type, slug+sluggable_type+scope(unique), sluggable_type+sluggable_id
- **jwt_denylists** (5 cols) - jti:string, exp:datetime | Idx: jti(unique)
- **likes** (5 cols) - likeable_type:string, likeable_id:integer | FK: actor_id→federails_actors | Idx: actor_id+likeable_type+likeable_id(unique), likeable_type+likeable_id
- **notification_channels** (13 cols) - type:string, status:string(=active), last_verified_at:datetime, remote_id:string, name:string, webhook_url:string, channel_id:string, channel_name:string, metadata:jsonb(={}), deleted_at:datetime | Idx: type+remote_id(unique)
  status: active, inactive, error
- **notification_deliveries** (13 cols) - type:string, channel_id:string, channel_name:string, status:string(=failed), sent_at:datetime, error_message:text, message_id:string, metadata:jsonb(={}) | FK: notification_channel_id→notification_channels, article_id→articles | Idx: article_id+notification_channel_id+channel_id(unique)
  status: sent, failed
- **oauth_accounts** (9 cols) - provider:string, uid:string, email:string, email_verified:boolean(=false), raw_info:jsonb(={}) | FK: user_id→users | Idx: provider+uid(unique), user_id+provider(unique)
- **pg_search_documents** (7 cols) - content:text, searchable_type:string, searchable_id:integer, tsvector_content_tsearch:tsvector | Idx: searchable_type+searchable_id+created_at, searchable_type+searchable_id
- **posts** (23 cols) - body:text, federated_url:string, lft:integer, rgt:integer, depth:integer(=0), children_count:integer(=0), likers_count:integer(=0), url:string, title:string, media_attachments:jsonb(=[]), slug:string, boosters_count:integer(=0), post_type:integer(=0), status:integer(=1), published_at:datetime, deleted_at:datetime | FK: parent_id→posts, user_id→users, article_id→articles, federails_actor_id→federails_actors | Idx: federated_url(unique), parent_id+created_at, slug(unique), post_type+status+created_at, user_id+post_type+status+created_at
  post_type: short, blog, comment
  status: draft, published
- **preferences** (5 cols) - name:string, value:jsonb(={}) | Idx: name(unique)
- **push_subscriptions** (10 cols) - endpoint:text, p256dh:string, auth:string, expiration_time:datetime, last_sent_at:datetime, last_error_at:datetime | FK: user_id→users | Idx: endpoint(unique)
- **refresh_tokens** (7 cols) - token_digest:string, expires_at:datetime, revoked_at:datetime | FK: user_id→users | Idx: token_digest(unique)
- **roles** (4 cols) - name:string | Idx: name(unique)
- **sites** (12 cols) - name:string, base_uri:string, client:integer(=0), last_checked_at:datetime, email:string, path:string, channel:string, deleted_at:datetime, url:string | Idx: client+id, url(unique)
  client: rss, gmail, youtube, hacker_news, rss_page, reddit
- **taggings** (9 cols) - taggable_type:string, taggable_id:integer, tagger_type:string, tagger_id:integer, context:string, tenant:string | FK: tag_id→tags | Idx: taggable_id+taggable_type+tagger_id+context, taggable_id+taggable_type+context+tag_id, taggable_type+taggable_id, tagger_id+tagger_type, tag_id+taggable_id+taggable_type+context+tagger_id+tagger_type(unique), taggable_id+taggable_type+context
- **tags** (6 cols) - name:string, taggings_count:integer(=0), is_confirmed:boolean(=false) | Idx: name(unique)
- **users** (18 cols) - email:string, name:string(=""), roles:string(={user}), username:string, likees_count:integer(=0), encrypted_password:string(=""), reset_password_token:string, reset_password_sent_at:datetime, remember_created_at:datetime, confirmation_token:string, confirmed_at:datetime, confirmation_sent_at:datetime, unconfirmed_email:string, locale:string, signup_host:string | Idx: confirmation_token(unique), email(unique), reset_password_token(unique), username(unique)