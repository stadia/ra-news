# Database Tables (20)

_Snapshot — may be stale after migrations. Use `rails_get_schema(table:"name")` for live data._

- **articles** (25 cols) — body:text, deleted_at:datetime, embedding:vector, federated_url:string, host:string, is_posted:boolean(=false), is_related:boolean(=false), is_youtube:boolean(=false), likers_count:integer(=0), origin_url:string(=""), posts_count:integer(=0), published_at:datetime, slug:string, social_post_ids:jsonb(={}), summary_body:text, summary_detail:jsonb, summary_key:jsonb, title:string, title_ko:string, url:string | Idx: deleted_at+published_at+created_at, deleted_at+slug+title_ko+id, is_related+published_at, origin_url(unique), slug(unique), url(unique)
- **federails_activities** (13 cols) — action:string, audience:string, bcc:string, bto:string, cc:string, entity_id:bigint, entity_type:string, federated_url:string, to:string, uuid:string | FK: actor_id→federails_actors | Idx: entity_type+entity_id, federated_url(unique), uuid(unique)
- **federails_actors** (22 cols) — actor_type:string, entity_id:integer, entity_type:string, extensions:json, federated_url:string, followers_url:string, followings_url:string, inbox_url:string, likees_count:integer(=0), local:boolean(=false), name:string, outbox_url:string, private_key:text, profile_url:string, public_key:text, server:string, shared_inbox_url:string, tombstoned_at:datetime, username:string, uuid:string | Idx: entity_type+entity_id(unique), federated_url(unique), uuid(unique)
- **federails_blocks** (4 cols) | FK: actor_id→federails_actors, target_actor_id→federails_actors | Idx: actor_id+target_actor_id(unique)
- **federails_featured_items** (4 cols) — actor_id:bigint, federated_url:string | Idx: actor_id+federated_url(unique)
- **federails_featured_tags** (4 cols) — actor_id:bigint, name:string | Idx: actor_id+name(unique)
- **federails_followings** (7 cols) — federated_url:string, status:integer(=0), uuid:string | FK: actor_id→federails_actors, target_actor_id→federails_actors | Idx: actor_id+target_actor_id(unique), uuid(unique)
- **federails_hosts** (8 cols) — domain:string, nodeinfo_url:string, protocols:text(=[]), services:text(={}), software_name:string, software_version:string | Idx: domain(unique)
- **friendly_id_slugs** (5 cols) — scope:string, slug:string, sluggable_id:integer, sluggable_type:string | Idx: slug+sluggable_type+scope(unique), slug+sluggable_type, sluggable_type+sluggable_id
- **likes** (5 cols) — likeable_id:bigint, likeable_type:string, liker_id:bigint, liker_type:string | Idx: likeable_type+likeable_id, liker_type+liker_id+likeable_type+likeable_id(unique), liker_type+liker_id
- **pg_search_documents** (6 cols) — content:text, searchable_id:bigint, searchable_type:string, tsvector_content_tsearch:tsvector | Idx: searchable_type+searchable_id+created_at, searchable_type+searchable_id
- **posts** (16 cols) — body:text, children_count:integer(=0), depth:integer(=0), federated_url:string, lft:integer, likers_count:integer(=0), media_attachments:jsonb(=[]), parent_id:bigint, rgt:integer, title:string, url:string | FK: article_id→articles | Idx: federated_url(unique), parent_id+created_at
- **preferences** (4 cols) — name:string, value:jsonb(={})
- **push_subscriptions** (9 cols) — auth:string, endpoint:text, expiration_time:datetime, last_error_at:datetime, last_sent_at:datetime, p256dh:string | FK: user_id→users | Idx: endpoint(unique)
- **roles** (3 cols) — name:string
- **sites** (10 cols) — base_uri:string, channel:string, client:integer(=0), deleted_at:datetime, email:string, last_checked_at:datetime, name:string, path:string | Idx: client+last_checked_at
  client: rss, gmail, youtube, hacker_news, rss_page, reddit
- **taggings** (8 cols) — context:string, taggable_id:bigint, taggable_type:string, tagger_id:bigint, tagger_type:string, tenant:string | FK: tag_id→tags | Idx: tag_id+taggable_id+taggable_type+context+tagger_id+tagger_type(unique), taggable_id+taggable_type+context, taggable_id+taggable_type+tagger_id+context, taggable_type+taggable_id, tagger_id+tagger_type
- **tags** (5 cols) — is_confirmed:boolean(=false), name:string, taggings_count:integer(=0) | Idx: name(unique)
- **user_roles** (4 cols) | Idx: user_id+role_id(unique)
- **users** (11 cols) — email:string, encrypted_password:string, likees_count:integer(=0), name:string(=""), remember_created_at:datetime, reset_password_sent_at:datetime, reset_password_token:string, roles:string[](=["user"]), username:string | Idx: email(unique), reset_password_token(unique), username(unique)