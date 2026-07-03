---
paths:
  - "db/schema.rb"
  - "db/migrate/**"
---

# Database Tables (28)

_Snapshot - may be stale after migrations. Use `rails_get_schema(table:"name")` for live data._

- **active_storage_attachments** (6 cols) - name:string, record_id:integer, record_type:string | FK: blob_id→active_storage_blobs | Idx: record_type+record_id+name+blob_id(unique)
- **active_storage_blobs** (9 cols) - byte_size:integer, checksum:string, content_type:string, filename:string, key:string, metadata:text, service_name:string | Idx: key(unique)
- **active_storage_variant_records** (3 cols) - variation_digest:string | FK: blob_id→active_storage_blobs | Idx: blob_id+variation_digest(unique)
- **articles** (31 cols) - body:text, boosters_count:integer(=0), deleted_at:datetime, embedding:halfvec, federated_url:string, host:string, is_posted:boolean(=false), is_related:boolean(=false), is_youtube:boolean(=false), likers_count:integer(=0), origin_url:string(=""), posts_count:integer(=0), published_at:datetime, slug:string, social_post_ids:jsonb(={}), summary_body:text, summary_body_ja:text, summary_detail:jsonb, summary_detail_ja:jsonb, summary_key:jsonb, summary_key_ja:jsonb, title:string, title_ja:string, title_ko:string, url:string | FK: site_id→sites, user_id→users, federails_actor_id→federails_actors | Idx: deleted_at+published_at+created_at, deleted_at+slug+title_ko+id, is_related+published_at, origin_url(unique), site_id+published_at, slug(unique), url(unique)
- **boosts** (5 cols) - boostable_id:integer, boostable_type:string | FK: actor_id→federails_actors | Idx: actor_id+boostable_type+boostable_id(unique), boostable_type+boostable_id
- **federails_activities** (16 cols) - action:string, audience:string, bcc:string, bto:string, cc:string, entity_id:integer, entity_type:string, federated_url:string, instrument:string, result:string, to:string, uuid:string | FK: actor_id→federails_actors | Idx: entity_type+entity_id, federated_url(unique), uuid(unique)
- **federails_actors** (24 cols) - actor_type:string, boostees_count:integer(=0), entity_id:integer, entity_type:string, extensions:json, federated_url:string, followers_url:string, followings_url:string, inbox_url:string, likees_count:integer(=0), local:boolean(=false), name:string, outbox_url:string, private_key:text, profile_url:string, public_key:text, server:string, shared_inbox_url:string, tombstoned_at:datetime, username:string, uuid:string | Idx: entity_type+entity_id(unique), federated_url(unique), uuid(unique)
- **federails_blocks** (5 cols) | FK: target_actor_id→federails_actors, actor_id→federails_actors | Idx: actor_id+target_actor_id(unique)
- **federails_featured_items** (5 cols) - actor_id:integer, federated_url:string | Idx: actor_id+federated_url(unique)
- **federails_featured_tags** (5 cols) - actor_id:integer, name:string | Idx: actor_id+name(unique)
- **federails_followings** (8 cols) - federated_url:string, status:integer(=0), uuid:string | FK: actor_id→federails_actors, target_actor_id→federails_actors | Idx: actor_id+target_actor_id(unique), uuid(unique)
- **federails_hosts** (9 cols) - domain:string, nodeinfo_url:string, protocols:text(=[]), services:text(={}), software_name:string, software_version:string | Idx: domain(unique)
- **friendly_id_slugs** (6 cols) - scope:string, slug:string, sluggable_id:integer, sluggable_type:string | Idx: slug+sluggable_type, slug+sluggable_type+scope(unique), sluggable_type+sluggable_id
- **jwt_denylists** (5 cols) - exp:datetime, jti:string | Idx: jti(unique)
- **likes** (5 cols) - likeable_id:integer, likeable_type:string | FK: actor_id→federails_actors | Idx: actor_id+likeable_type+likeable_id(unique), likeable_type+likeable_id
- **notification_channels** (13 cols) - channel_id:string, channel_name:string, deleted_at:datetime, last_verified_at:datetime, metadata:jsonb(={}), name:string, remote_id:string, status:string(=active), type:string, webhook_url:string | Idx: type+remote_id(unique)
  status: active, inactive, error
- **notification_deliveries** (13 cols) - channel_id:string, channel_name:string, error_message:text, message_id:string, metadata:jsonb(={}), sent_at:datetime, status:string(=failed), type:string | FK: notification_channel_id→notification_channels, article_id→articles | Idx: article_id+notification_channel_id+channel_id(unique)
  status: sent, failed
- **oauth_accounts** (9 cols) - email:string, email_verified:boolean(=false), provider:string, raw_info:jsonb(={}), uid:string | FK: user_id→users | Idx: provider+uid(unique), user_id+provider(unique)
- **pg_search_documents** (7 cols) - content:text, searchable_id:integer, searchable_type:string, tsvector_content_tsearch:tsvector | Idx: searchable_type+searchable_id+created_at, searchable_type+searchable_id
- **posts** (23 cols) - body:text, boosters_count:integer(=0), children_count:integer(=0), depth:integer(=0), federated_url:string, lft:integer, likers_count:integer(=0), media_attachments:jsonb(=[]), rgt:integer, slug:string, title:string, url:string, post_type:integer(=0), status:integer(=1), published_at:datetime, deleted_at:datetime | FK: parent_id→posts, user_id→users, article_id→articles, federails_actor_id→federails_actors | Idx: federated_url(unique), parent_id+created_at, slug(unique), post_type+status+created_at, user_id+post_type+status+created_at
  post_type: short, blog, comment
  status: draft, published
- **preferences** (5 cols) - name:string, value:jsonb(={}) | Idx: name(unique)
- **push_subscriptions** (10 cols) - auth:string, endpoint:text, expiration_time:datetime, last_error_at:datetime, last_sent_at:datetime, p256dh:string | FK: user_id→users | Idx: endpoint(unique)
- **refresh_tokens** (7 cols) - expires_at:datetime, revoked_at:datetime, token_digest:string | FK: user_id→users | Idx: token_digest(unique)
- **roles** (4 cols) - name:string | Idx: name(unique)
- **sites** (12 cols) - base_uri:string, channel:string, client:integer(=0), deleted_at:datetime, email:string, last_checked_at:datetime, name:string, path:string, url:string | Idx: client+id, url(unique)
  client: rss, gmail, youtube, hacker_news, rss_page, reddit
- **taggings** (9 cols) - context:string, taggable_id:integer, taggable_type:string, tagger_id:integer, tagger_type:string, tenant:string | FK: tag_id→tags | Idx: taggable_id+taggable_type+context+tag_id, taggable_type+taggable_id, tagger_id+tagger_type, tag_id+taggable_id+taggable_type+context+tagger_id+tagger_type(unique), taggable_id+taggable_type+tagger_id+context, taggable_id+taggable_type+context
- **tags** (6 cols) - is_confirmed:boolean(=false), name:string, taggings_count:integer(=0) | Idx: name(unique)
- **users** (18 cols) - confirmation_sent_at:datetime, confirmation_token:string, confirmed_at:datetime, email:string, encrypted_password:string, likees_count:integer(=0), locale:string, name:string(=""), remember_created_at:datetime, reset_password_sent_at:datetime, reset_password_token:string, roles:string(={user}), signup_host:string, unconfirmed_email:string, username:string | Idx: confirmation_token(unique), email(unique), reset_password_token(unique), username(unique)