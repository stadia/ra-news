# ActiveRecord Models (15)

Check this file first for associations, scopes, constants, and validations.
If you need more detail (callbacks, methods, business logic), use `rails_get_model_details(model:"Name")` or Read the file directly.

- ActsAsTaggableOn::Tag (table: tags) — 1 assocs, 3 validations
  methods: count, taggings, validates_name_uniqueness?
- Article (table: articles) — 9 assocs, 6 validations
  scopes: {name: "related", body: "kept.where(is_related: true)"}, {name: "unrelated", body: "where(is_related: false)"}, {name: "confirmed", body: "where(\"slug IS NOT NULL AND title_ko IS NOT NULL\")"}, {name: "without_toast", body: "select(column_names - %w[body summary_body embedding])"}, {name: "for_admin_index", body: "select(:id, :title_ko, :slug, :host, :is_related, :published_at, :created_at, :updated_at)"}
  methods: to_activitypub_object, generate_metadata, youtube_id, update_slug, update_published_at, user_name, base_content, should_federate?, likes_count, add_custom_context, all_tags_list, all_tags_list_on, all_tags_on, base_tags, cached_owned_tag_list_on, cached_tag_list_on, comments, create_or_update_pg_search_document, custom_contexts, discard
- Comment (table: comments) — 5 assocs, 5 validations
  methods: to_activitypub_object, content, author_name, author_host, federation_actor_entity, should_federate?, reply, acts_as_nested_set_options, acts_as_nested_set_options?, add_scope_conditions_to_options, after_move_to, ancestors, arel_table, article, change_descendants_depth!, child?, children, compute_level, counter_cache_column_name, decendants_to_destroy_in_order
- Federails::Actor (table: federails_actors) — 8 assocs, 14 validations
  methods: acct_uri, activities, activities_as_entity, actor_type, at_address, distant?, entity, entity_configuration, federated_url, followed_by?, followers, followers_url, following_followers, following_follows, followings_url, follows, follows?, host, inbox_url, key_id
- Like (table: likes) — 2 assocs, 0 validations
  methods: liked_ids_for, publish_federated_like, publish_federated_unlike, likeable, liker
- Post (table: posts) — 4 assocs, 2 validations
  methods: federation_actor_entity, should_federate?, to_activitypub_object, likes_count, acts_as_nested_set_options, acts_as_nested_set_options?, add_scope_conditions_to_options, after_move_to, ancestors, arel_table, change_descendants_depth!, child?, children, compute_level, counter_cache_column_name, decendants_to_destroy_in_order, depth_column_name, descendants, destroy_descendants, destroy_or_delete_descendants
- Preference (table: preferences) — 0 assocs, 0 validations
  methods: clear_cache
  PROTECTED_KEYS: name, value
- PushSubscription (table: push_subscriptions) — 1 assocs, 6 validations
  methods: user
- Role (table: roles) — 0 assocs, 2 validations
  scopes: {name: "named", body: "where(name: role_name.to_s)"}
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
  scopes: {name: "confirmed", body: "where(is_confirmed: true)"}, {name: "unconfirmed", body: "where(is_confirmed: false)"}
  methods: count, taggings, validates_name_uniqueness?
- User (table: users) — 4 assocs, 11 validations
  scopes: {name: "admins", body: "with_role(:admin)"}
  methods: admin?, full_name, has_role?, roles, accept_follow, after_remembered, apply_to_attribute_or_variable, articles, clear_reset_password_token, clear_reset_password_token?, current_password, devise_modules, devise_modules?, devise_respond_to_and_will_save_change_to_attribute?, devise_saved_change_to_email?, devise_saved_change_to_encrypted_password?, devise_unconfirmed_email_will_change!, devise_will_save_change_to_email?, downcase_keys, extend_remember_period