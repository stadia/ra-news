---
paths:
  - "db/schema.rb"
  - "db/migrate/**"
---

# Database Tables (28)

_Snapshot — may be stale after migrations. Use `rails_get_schema(table:"name")` for live data._

- **ra_news.active_storage_attachments** (5 cols) — blob_id:bigint, name:string, record_id:bigint, record_type:string | FK: ra_news.active_storage_blob_id→ra_news.active_storage_blobs | Idx: record_type+record_id+name+blob_id(unique)
- **ra_news.active_storage_blobs** (8 cols) — byte_size:bigint, checksum:string, content_type:string, filename:string, key:string, metadata:text, service_name:string | Idx: key(unique)
- **ra_news.active_storage_variant_records** (2 cols) — blob_id:bigint, variation_digest:string | FK: ra_news.active_storage_blob_id→ra_news.active_storage_blobs | Idx: blob_id+variation_digest(unique)
- **ra_news.articles** (33 cols) — body:text, boosters_count:integer(=0), deleted_at:datetime, federails_actor_id:bigint, federated_url:string, grounding_checked_at:datetime, grounding_flagged:boolean(=false), grounding_issues:jsonb, grounding_score:float, host:string, is_posted:boolean(=false), is_related:boolean(=false), is_youtube:boolean(=false), likers_count:integer(=0), origin_url:string(=""), posts_count:integer(=0), published_at:datetime, site_id:bigint, slug:string, social_post_ids:jsonb(={}), summary_body:text, summary_body_ja:text, summary_detail:jsonb, summary_detail_ja:jsonb, summary_key:jsonb, summary_key_ja:jsonb, title:string, title_ja:string, title_ko:string, url:string, user_id:bigint | FK: ra_news.federails_actor_id→ra_news.federails_actors, ra_news.site_id→ra_news.sites, ra_news.user_id→ra_news.users | Idx: deleted_at+published_at+created_at, deleted_at+slug+title_ko+id, is_related+published_at, origin_url(unique), slug(unique), url(unique)
- **ra_news.boosts** (4 cols) — actor_id:bigint, boostable_id:bigint, boostable_type:string | FK: ra_news.federails_actor_id→ra_news.federails_actors | Idx: actor_id+boostable_type+boostable_id(unique), boostable_type+boostable_id
- **ra_news.federails_activities** (15 cols) — action:string, actor_id:bigint, audience:string, bcc:string, bto:string, cc:string, entity_id:bigint, entity_type:string, federated_url:string, instrument:string, result:string, to:string, uuid:string | FK: ra_news.federails_actor_id→ra_news.federails_actors | Idx: entity_type+entity_id, federated_url(unique), uuid(unique)
- **ra_news.federails_actors** (23 cols) — actor_type:string, boostees_count:integer(=0), entity_id:integer, entity_type:string, extensions:json, federated_url:string, followers_url:string, followings_url:string, inbox_url:string, likees_count:integer(=0), local:boolean(=false), name:string, outbox_url:string, private_key:text, profile_url:string, public_key:text, server:string, shared_inbox_url:string, tombstoned_at:datetime, username:string, uuid:string | Idx: entity_type+entity_id(unique), federated_url(unique), uuid(unique)
- **ra_news.federails_blocks** (4 cols) — actor_id:bigint, target_actor_id:bigint | FK: ra_news.federails_actor_id→ra_news.federails_actors, ra_news.federails_actor_id→ra_news.federails_actors | Idx: actor_id+target_actor_id(unique)
- **ra_news.federails_featured_items** (4 cols) — actor_id:bigint, federated_url:string | Idx: actor_id+federated_url(unique)
- **ra_news.federails_featured_tags** (4 cols) — actor_id:bigint, name:string | Idx: actor_id+name(unique)
- **ra_news.federails_followings** (7 cols) — actor_id:bigint, federated_url:string, status:integer(=0), target_actor_id:bigint, uuid:string | FK: ra_news.federails_actor_id→ra_news.federails_actors, ra_news.federails_actor_id→ra_news.federails_actors | Idx: actor_id+target_actor_id(unique), uuid(unique)
- **ra_news.federails_hosts** (8 cols) — domain:string, nodeinfo_url:string, protocols:text(=[]), services:text(={}), software_name:string, software_version:string | Idx: domain(unique)
- **ra_news.friendly_id_slugs** (5 cols) — scope:string, slug:string, sluggable_id:integer, sluggable_type:string | Idx: slug+sluggable_type+scope(unique), slug+sluggable_type, sluggable_type+sluggable_id
- **ra_news.jwt_denylists** (4 cols) — exp:datetime, jti:string | Idx: jti(unique)
- **ra_news.likes** (4 cols) — actor_id:bigint, likeable_id:bigint, likeable_type:string | FK: ra_news.federails_actor_id→ra_news.federails_actors | Idx: actor_id+likeable_type+likeable_id(unique), likeable_type+likeable_id
- **ra_news.notification_channels** (12 cols) — channel_id:string, channel_name:string, deleted_at:datetime, last_verified_at:datetime, metadata:jsonb(={}), name:string, remote_id:string, status:string(=active), type:string, webhook_url:string | Idx: type+remote_id(unique)
  status: active, inactive, error
- **ra_news.notification_deliveries** (12 cols) — article_id:bigint, channel_id:string, channel_name:string, error_message:text, message_id:string, metadata:jsonb(={}), notification_channel_id:bigint, sent_at:datetime, status:string(=failed), type:string | FK: ra_news.article_id→ra_news.articles, ra_news.notification_channel_id→ra_news.notification_channels | Idx: article_id+notification_channel_id+channel_id(unique)
  status: sent, failed
- **ra_news.oauth_accounts** (8 cols) — email:string, email_verified:boolean(=false), provider:string, raw_info:jsonb(={}), uid:string, user_id:bigint | FK: ra_news.user_id→ra_news.users | Idx: provider+uid(unique), user_id+provider(unique)
- **ra_news.pg_search_documents** (5 cols) — content:text, searchable_id:bigint, searchable_type:string | Idx: searchable_type+searchable_id+created_at, searchable_type+searchable_id
- **ra_news.posts** (22 cols) — article_id:bigint, body:text, boosters_count:integer(=0), children_count:integer(=0), deleted_at:datetime, depth:integer(=0), federails_actor_id:bigint, federated_url:string, lft:integer, likers_count:integer(=0), media_attachments:jsonb(=[]), parent_id:bigint, post_type:integer(=0), published_at:datetime, rgt:integer, slug:string, status:integer(=1), title:string, url:string, user_id:bigint | FK: ra_news.article_id→ra_news.articles, ra_news.federails_actor_id→ra_news.federails_actors, ra_news.post_id→ra_news.posts, ra_news.user_id→ra_news.users | Idx: federated_url(unique), parent_id+created_at, post_type+status+created_at, slug(unique), user_id+post_type+status+created_at
  post_type: short, blog, comment
  status: draft, published
- **ra_news.preferences** (4 cols) — name:string, value:jsonb(={}) | Idx: name(unique)
- **ra_news.push_subscriptions** (9 cols) — auth:string, endpoint:text, expiration_time:datetime, last_error_at:datetime, last_sent_at:datetime, p256dh:string, user_id:bigint | FK: ra_news.user_id→ra_news.users | Idx: endpoint(unique)
- **ra_news.refresh_tokens** (6 cols) — expires_at:datetime, revoked_at:datetime, token_digest:string, user_id:bigint | FK: ra_news.user_id→ra_news.users | Idx: token_digest(unique)
- **ra_news.roles** (3 cols) — name:string | Idx: name(unique)
- **ra_news.sites** (11 cols) — base_uri:string, channel:string, client:integer(=0), deleted_at:datetime, email:string, last_checked_at:datetime, name:string, path:string, url:string | Idx: client+id, url(unique)
  client: rss, gmail, youtube, hacker_news, rss_page, reddit
- **ra_news.taggings** (8 cols) — context:string, tag_id:bigint, taggable_id:bigint, taggable_type:string, tagger_id:bigint, tagger_type:string, tenant:string | FK: ra_news.tag_id→ra_news.tags | Idx: tag_id+taggable_id+taggable_type+context+tagger_id+tagger_type(unique), taggable_id+taggable_type+context+tag_id, taggable_id+taggable_type+context, taggable_id+taggable_type+tagger_id+context, taggable_type+taggable_id, tagger_id+tagger_type
- **ra_news.tags** (5 cols) — is_confirmed:boolean(=false), name:string, taggings_count:integer(=0) | Idx: name(unique)
- **ra_news.users** (18 cols) — confirmation_sent_at:datetime, confirmation_token:string, confirmed_at:datetime, email:string, email_verified_at:datetime, encrypted_password:string, likees_count:integer(=0), locale:string, name:string(=""), remember_created_at:datetime, reset_password_sent_at:datetime, reset_password_token:string, roles:string[](=["user"]), signup_host:string, unconfirmed_email:string, username:string | Idx: confirmation_token(unique), email(unique), reset_password_token(unique), username(unique)