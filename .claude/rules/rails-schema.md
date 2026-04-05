# Database Tables (17)

_Snapshot — may be stale after migrations. Use `rails_get_schema(table:"name")` for live data._

- **active_storage_variant_records** (3 cols) — blob_id:bigint, variation_digest:string, active_storage_blobs:foreign_key
- **articles** (22 cols) — title:string, url:string, summary_key:jsonb, summary_detail:jsonb, title_ko:string, published_at:datetime, deleted_at:datetime, origin_url:string(=""), host:string, slug:string, is_youtube:boolean(=false), is_related:boolean(=false), body:text, is_posted:boolean(=false), social_post_ids:jsonb, federated_url:string, likers_count:integer(=0) | Idx: url(unique), origin_url(unique), slug(unique), slug(unique), slug(unique), deleted_at+published_at+created_at, deleted_at+id, site_id+published_at, is_related+published_at
- **federails_activities** (11 cols) — entity_id:bigint, action:string, actor_id:bigint, to:string, cc:string, federated_url:string, bto:string, bcc:string, audience:string | Idx: federated_url(unique)
- **federails_actors** (19 cols) — name:string, federated_url:string, username:string, server:string, inbox_url:string, outbox_url:string, followers_url:string, followings_url:string, profile_url:string, entity_id:integer, entity_type:string, extensions:json, local:boolean(=false), actor_type:string, tombstoned_at:datetime, likees_count:integer(=0), shared_inbox_url:string | Idx: entity_type+entity_id(unique)
- **federails_blocks** (4 cols) — actor_id:bigint, target_actor_id:bigint | Idx: actor_id+target_actor_id(unique)
- **federails_featured_items** (4 cols) — actor_id:bigint, federated_url:string | Idx: actor_id+federated_url(unique)
- **federails_featured_tags** (4 cols) — actor_id:bigint, name:string | Idx: actor_id+name(unique)
- **federails_followings** (6 cols) — actor_id:bigint, target_actor_id:bigint, status:integer(=0), federated_url:string | Idx: actor_id+target_actor_id(unique)
- **federails_hosts** (10 cols) — domain:string, nodeinfo_url:string, software_name:string, software_version:string, protocols:jsonb, services:jsonb, protocols:text, services:text
- **friendly_id_slugs** (5 cols) — slug:string, sluggable_id:integer, sluggable_type:string, scope:string | Idx: sluggable_type+sluggable_id, slug+sluggable_type, slug+sluggable_type+scope(unique)
- **likes** (5 cols) — liker_type:string, liker_id:bigint, likeable_type:string, likeable_id:bigint | Idx: liker_type+liker_id, likeable_type+likeable_id, liker_type+liker_id+likeable_type+likeable_id
- **posts** (16 cols) — body:text, federated_url:string, parent_id:bigint, lft:integer, rgt:integer, depth:integer(=0), children_count:integer(=0), likers_count:integer(=0), url:string, title:string, media_attachments:jsonb | FK: article_id→articles | Idx: parent_id+created_at, federated_url(unique)
- **push_subscriptions** (9 cols) — endpoint:text, p256dh:string, auth:string, expiration_time:datetime, last_sent_at:datetime, last_error_at:datetime | Idx: endpoint(unique)
- **roles** (3 cols) — name:string | Idx: name(unique)
- **sessions** (5 cols) — ip_address:string, user_agent:string
- **sites** (10 cols) — name:string, base_uri:string, client:integer, last_checked_at:datetime, email:string, path:string, channel:string, deleted_at:datetime | Idx: client+last_checked_at
  client: rss, gmail, youtube, hacker_news, rss_page, reddit
- **users** (7 cols) — email_address:string, name:string, roles:json, username:string, likees_count:integer(=0) | Idx: email_address(unique), email_address(unique), username(unique), email(unique), reset_password_token(unique)