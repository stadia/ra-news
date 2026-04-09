---
paths:
  - "app/models/**/*.rb"
---

# ActiveRecord Models (14)

_Quick reference — use `rails_get_model_details(model:"Name")` for live data with resolved concerns and callbacks._

- ActsAsTaggableOn::Tag (table: tags) — 1 assocs, 3 validations
  methods: count, taggings, validates_name_uniqueness?
- Article (table: articles) — 9 assocs, 6 validations
  concerns: FederailsLikeable
  scopes: full_text_search_for, related, unrelated, confirmed, without_toast, for_admin_index
  methods: to_activitypub_object, generate_metadata, youtube_id, update_slug, user_name, base_content, should_federate?, likes_count, add_custom_context, all_tags_list, all_tags_list_on, all_tags_on, apply_like, apply_undo_like, apply_unlike, base_tags, cached_owned_tag_list_on, cached_tag_list_on, create_or_update_pg_search_document, current_federails_activity_actor
- Federails::Actor (table: federails_actors) — 10 assocs, 14 validations
  methods: acct_uri, activities, activities_as_entity, actor_type, at_address, distant?, entity, entity_configuration, feature, featured_items, featured_tags, federated_url, followed_by?, followers, followers_url, following_followers, following_follows, followings_url, follows, follows?
- Like (table: likes) — 2 assocs, 0 validations
  methods: likeable, liker
- Post (table: posts) — 9 assocs, 2 validations
  concerns: FederailsLikeable, HtmlSanitizable
  scopes: comments, standalone
  methods: federation_actor_entity, should_federate?, to_activitypub_object, likes_count, comment?, reply, author_name, author_host, acts_as_nested_set_options, acts_as_nested_set_options?, add_custom_context, add_scope_conditions_to_options, after_move_to, all_tags_list, all_tags_list_on, all_tags_on, ancestors, apply_like, apply_undo_like, apply_unlike
- Preference (table: preferences) — 0 assocs, 0 validations
  methods: clear_cache
  PROTECTED_KEYS: name, value
- PushSubscription (table: push_subscriptions) — 1 assocs, 6 validations
  methods: user
- Role (table: roles) — 0 assocs, 2 validations
  scopes: named
- Site (table: sites) — 1 assocs, 1 validations
  methods: init_client, articles, discard, discard!, discard_column, discard_column?, discarded?, gmail!, gmail?, hacker_news!, hacker_news?, kept?, reddit!, reddit?, rss!, rss?, rss_page!, rss_page?, undiscard, undiscard!
  client: rss, gmail, youtube, hacker_news, rss_page, reddit
- Socialization::ActiveRecordStores::Follow (table: follows) — 2 assocs, 0 validations
  methods: followable, follower
- Socialization::ActiveRecordStores::Like (table: likes) — 2 assocs, 0 validations
  methods: likeable, liker
- Socialization::ActiveRecordStores::Mention (table: mentions) — 2 assocs, 0 validations
  methods: mentionable, mentioner
- Tag (table: tags) — 1 assocs, 3 validations
  scopes: confirmed, unconfirmed
  methods: count, taggings, validates_name_uniqueness?
- User (table: users) — 4 assocs, 11 validations
  scopes: with_role, admins
  methods: admin?, full_name, has_role?, accept_follow, after_confirmation, articles, confirm, confirmation_period_expired?, confirmed?, devise_saved_change_to_email?, devise_saved_change_to_encrypted_password?, devise_unconfirmed_email_will_change!, devise_will_save_change_to_email?, downcase_keys, extend_remember_period, federails_actor, generate_confirmation_token, generate_confirmation_token!, like!