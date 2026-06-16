---
paths:
  - "app/models/**/*.rb"
---

# ActiveRecord Models (21)

_Quick reference - use `rails_get_model_details(model:"Name")` for live data with resolved concerns and callbacks._

- ActsAsTaggableOn::Tag (table: tags) - 1 assocs, 3 validations
  methods: count, taggings, validates_name_uniqueness?
- Article (table: articles) - 13 assocs, 7 validations
  concerns: FederailsBoostable, FederailsLikeable
  scopes: full_text_search_for, related, unrelated, confirmed, without_toast, for_admin_index
  methods: to_markdown, generate_metadata, youtube_id, update_slug, user_name, base_content, should_federate?, likes_count, boosts_count, add_custom_context, all_tags_list, all_tags_list_on, all_tags_on, announce!, apply_remote_boost, apply_remote_like, apply_remote_unboost, apply_remote_unlike, available_in?, base_tags
- Boost (table: boosts) - 2 assocs, 2 validations
  methods: actor, boostable
- DiscordChannel (table: notification_channels) - 1 assocs, 3 validations
  methods: active!, active?, discard, discard!, discard_column, discard_column?, discarded?, error!, error?, inactive!, inactive?, kept?, notification_deliveries, undiscard, undiscard!, undiscarded?
  status: active, inactive, error
- DiscordDelivery (table: notification_deliveries) - 2 assocs, 5 validations
  methods: article, failed!, failed?, notification_channel, sent!, sent?
  status: sent, failed
- Federails::Actor (table: federails_actors) - 14 assocs, 14 validations
  methods: accepted_followers, accepted_following_followers, accepted_following_follows, accepted_follows, acct_uri, activities, activities_as_entity, actor_type, announce!, at_address, dislike!, distant?, entity, entity_configuration, feature, featured_items, featured_tags, federated_url, followed_by?, followers
- JwtDenylist (table: jwt_denylists) - 0 assocs, 0 validations
- Like (table: likes) - 2 assocs, 2 validations
  methods: actor, likeable
- NotificationChannel (table: notification_channels) - 1 assocs, 3 validations
  scopes: active, delivery_ready
  methods: active!, active?, discard, discard!, discard_column, discard_column?, discarded?, error!, error?, inactive!, inactive?, kept?, notification_deliveries, undiscard, undiscard!, undiscarded?
  status: active, inactive, error
- NotificationDelivery (table: notification_deliveries) - 2 assocs, 5 validations
  methods: article, failed!, failed?, notification_channel, sent!, sent?
  status: sent, failed
- OauthAccount (table: oauth_accounts) - 1 assocs, 5 validations
  methods: user
- Post (table: posts) - 10 assocs, 5 validations
  concerns: FederailsBoostable, FederailsLikeable, HtmlSanitizable
  scopes: comments, standalone, visible, published_blog
  methods: federation_actor_entity, should_federate?, to_activitypub_object, likes_count, boosts_count, reply, federation_reply_recipients, author_name, author_host, acts_as_nested_set_options, acts_as_nested_set_options?, add_custom_context, add_scope_conditions_to_options, after_move_to, all_tags_list, all_tags_list_on, all_tags_on, ancestors, announce!, apply_remote_boost
  post_type: short, blog, comment
  status: draft, published
- Preference (table: preferences) - 0 assocs, 2 validations
  methods: clear_cache
- PushSubscription (table: push_subscriptions) - 1 assocs, 6 validations
  methods: user
- RefreshToken (table: refresh_tokens) - 1 assocs, 1 validations
  scopes: active
  methods: revoke!, user
- Role (table: roles) - 0 assocs, 2 validations
  scopes: named
- Site (table: sites) - 1 assocs, 2 validations
  methods: init_client, articles, discard, discard!, discard_column, discard_column?, discarded?, gmail!, gmail?, hacker_news!, hacker_news?, kept?, reddit!, reddit?, rss!, rss?, rss_page!, rss_page?, undiscard, undiscard!
  client: rss, gmail, youtube, hacker_news, rss_page, reddit
- SlackChannel (table: notification_channels) - 1 assocs, 3 validations
  methods: active!, active?, discard, discard!, discard_column, discard_column?, discarded?, error!, error?, inactive!, inactive?, kept?, notification_deliveries, undiscard, undiscard!, undiscarded?
  status: active, inactive, error
- SlackDelivery (table: notification_deliveries) - 2 assocs, 5 validations
  methods: article, failed!, failed?, notification_channel, sent!, sent?
  status: sent, failed
- Tag (table: tags) - 1 assocs, 3 validations
  scopes: confirmed, unconfirmed
  methods: count, taggings, validates_name_uniqueness?
- User (table: users) - 8 assocs, 13 validations
  scopes: with_role, admins
  methods: admin?, full_name, has_role?, accept_follow, avatar_attached?, avatar_url, remove_avatar!, sync_federails_actor_extensions, to_activitypub_object, like!, unlike!, likes?, boost!, unboost!, boosts?, after_confirmation, articles, avatar, avatar_attachment, avatar_blob
  SUPPORTED_LOCALES: ko, ja, en
  SUPPORTED_SIGNUP_HOSTS: ruby-news.dev, ruby-news.jp