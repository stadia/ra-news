class InitSchema < ActiveRecord::Migration[8.1]
  def up
    # These are extensions that must be enabled in order to support this database
    enable_extension "fuzzystrmatch"
    enable_extension "pg_bigm"
    enable_extension "pg_catalog.plpgsql"
    enable_extension "textsearch_ko"
    enable_extension "vector"
    create_table "articles" do |t|
      t.text "body", comment: "The main content of the article"
      t.datetime "created_at", null: false
      t.datetime "deleted_at"
      t.vector "embedding", limit: 1536
      t.bigint "federails_actor_id"
      t.string "federated_url"
      t.string "host"
      t.boolean "is_posted", default: false, comment: "소셜에 게시되었는지 여부를 나타냅니다."
      t.boolean "is_related", default: false, null: false
      t.boolean "is_youtube", default: false, null: false
      t.integer "likers_count", default: 0, null: false
      t.string "origin_url", default: "", null: false
      t.integer "posts_count", default: 0, null: false
      t.datetime "published_at"
      t.bigint "site_id", default: 0, null: false
      t.string "slug"
      t.jsonb "social_post_ids", default: {}
      t.text "summary_body", comment: "원문 상세 요약"
      t.jsonb "summary_detail"
      t.jsonb "summary_key"
      t.string "title"
      t.string "title_ko"
      t.datetime "updated_at", null: false
      t.string "url"
      t.bigint "user_id"
      t.index [ "created_at" ], name: "index_articles_on_created_at"
      t.index [ "deleted_at", "published_at", "created_at" ], name: "index_articles_on_deleted_at_and_published_at_and_created_at", where: "(deleted_at IS NULL)"
      t.index [ "deleted_at", "slug", "title_ko", "id" ], name: "index_articles_on_deleted_at_and_slug_and_title_ko_and_id", where: "((deleted_at IS NULL) AND (slug IS NOT NULL) AND (title_ko IS NOT NULL))", comment: "Optimized for listing articles with slug and title"
      t.index [ "federails_actor_id" ], name: "index_articles_on_federails_actor_id"
      t.index [ "is_related", "published_at" ], name: "index_articles_on_is_related_and_published_at"
      t.index [ "origin_url" ], name: "index_articles_on_origin_url", unique: true
      t.index [ "published_at" ], name: "index_articles_on_published_at"
      t.index [ "site_id", "published_at" ], name: "index_articles_on_site_id_and_published_at"
      t.index [ "site_id" ], name: "index_articles_on_site_id"
      t.index [ "slug" ], name: "index_articles_on_slug", unique: true, where: "(deleted_at IS NULL)"
      t.index [ "url" ], name: "index_articles_on_url", unique: true
      t.index [ "user_id" ], name: "index_articles_on_user_id"
    end
    create_table "federails_activities" do |t|
      t.string "action", null: false
      t.bigint "actor_id", null: false
      t.string "audience"
      t.string "bcc"
      t.string "bto"
      t.string "cc"
      t.datetime "created_at", null: false
      t.bigint "entity_id", null: false
      t.string "entity_type", null: false
      t.string "federated_url"
      t.string "to"
      t.datetime "updated_at", null: false
      t.string "uuid"
      t.index [ "actor_id" ], name: "index_federails_activities_on_actor_id"
      t.index [ "entity_type", "entity_id" ], name: "index_federails_activities_on_entity"
      t.index [ "federated_url" ], name: "index_federails_activities_on_federated_url", unique: true
      t.index [ "uuid" ], name: "index_federails_activities_on_uuid", unique: true
    end
    create_table "federails_actors" do |t|
      t.string "actor_type"
      t.datetime "created_at", null: false
      t.integer "entity_id"
      t.string "entity_type"
      t.json "extensions"
      t.string "federated_url"
      t.string "followers_url"
      t.string "followings_url"
      t.string "inbox_url"
      t.integer "likees_count", default: 0, null: false
      t.boolean "local", default: false, null: false
      t.string "name"
      t.string "outbox_url"
      t.text "private_key"
      t.string "profile_url"
      t.text "public_key"
      t.string "server"
      t.datetime "tombstoned_at"
      t.datetime "updated_at", null: false
      t.string "username"
      t.string "uuid"
      t.index [ "entity_type", "entity_id" ], name: "index_federails_actors_on_entity", unique: true
      t.index [ "federated_url" ], name: "index_federails_actors_on_federated_url", unique: true
      t.index [ "uuid" ], name: "index_federails_actors_on_uuid", unique: true
    end
    create_table "federails_blocks" do |t|
      t.bigint "actor_id", null: false
      t.datetime "created_at", null: false
      t.bigint "target_actor_id", null: false
      t.datetime "updated_at", null: false
      t.index [ "actor_id", "target_actor_id" ], name: "index_federails_blocks_on_actor_id_and_target_actor_id", unique: true
      t.index [ "actor_id" ], name: "index_federails_blocks_on_actor_id"
      t.index [ "target_actor_id" ], name: "index_federails_blocks_on_target_actor_id"
    end
    create_table "federails_followings" do |t|
      t.bigint "actor_id", null: false
      t.datetime "created_at", null: false
      t.string "federated_url"
      t.integer "status", default: 0
      t.bigint "target_actor_id", null: false
      t.datetime "updated_at", null: false
      t.string "uuid"
      t.index [ "actor_id", "target_actor_id" ], name: "index_federails_followings_on_actor_id_and_target_actor_id", unique: true
      t.index [ "actor_id" ], name: "index_federails_followings_on_actor_id"
      t.index [ "target_actor_id" ], name: "index_federails_followings_on_target_actor_id"
      t.index [ "uuid" ], name: "index_federails_followings_on_uuid", unique: true
    end
    create_table "federails_hosts" do |t|
      t.datetime "created_at", null: false
      t.string "domain", null: false
      t.string "nodeinfo_url"
      t.text "protocols", default: "[]"
      t.text "services", default: "{}"
      t.string "software_name"
      t.string "software_version"
      t.datetime "updated_at", null: false
      t.index [ "domain" ], name: "index_federails_hosts_on_domain", unique: true
    end
    create_table "friendly_id_slugs" do |t|
      t.datetime "created_at"
      t.string "scope"
      t.string "slug", null: false
      t.integer "sluggable_id", null: false
      t.string "sluggable_type", limit: 50
      t.index [ "slug", "sluggable_type", "scope" ], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
      t.index [ "slug", "sluggable_type" ], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
      t.index [ "sluggable_type", "sluggable_id" ], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
    end
    create_table "likes" do |t|
      t.datetime "created_at", null: false
      t.bigint "likeable_id", null: false
      t.string "likeable_type", null: false
      t.bigint "liker_id", null: false
      t.string "liker_type", null: false
      t.index [ "likeable_type", "likeable_id" ], name: "index_likes_on_likeable"
      t.index [ "liker_type", "liker_id", "likeable_type", "likeable_id" ], name: "index_likes_on_liker_and_likeable", unique: true
      t.index [ "liker_type", "liker_id" ], name: "index_likes_on_liker"
    end
    create_table "pg_search_documents" do |t|
      t.text "content"
      t.datetime "created_at", null: false
      t.bigint "searchable_id"
      t.string "searchable_type"
      t.tsvector "tsvector_content_tsearch"
      t.datetime "updated_at", null: false
      t.index [ "searchable_type", "searchable_id", "created_at" ], name: "idx_on_searchable_type_searchable_id_created_at_0108fa1d12"
      t.index [ "searchable_type", "searchable_id" ], name: "index_pg_search_documents_on_searchable"
      t.index [ "tsvector_content_tsearch" ], name: "index_pg_search_documents_on_tsvector_content_tsearch", using: :gin
    end
    create_table "posts" do |t|
      t.bigint "article_id"
      t.text "body", null: false
      t.integer "children_count", default: 0, null: false
      t.datetime "created_at", null: false
      t.integer "depth", default: 0, null: false
      t.bigint "federails_actor_id"
      t.string "federated_url"
      t.integer "lft", null: false
      t.integer "likers_count", default: 0, null: false
      t.jsonb "media_attachments", default: [], null: false
      t.bigint "parent_id"
      t.integer "rgt", null: false
      t.string "title", limit: 255
      t.datetime "updated_at", null: false
      t.string "url", limit: 255
      t.bigint "user_id"
      t.index [ "article_id" ], name: "index_posts_on_article_id"
      t.index [ "federails_actor_id" ], name: "index_posts_on_federails_actor_id"
      t.index [ "federated_url" ], name: "index_posts_on_federated_url", unique: true
      t.index [ "lft" ], name: "index_posts_on_lft"
      t.index [ "parent_id", "created_at" ], name: "index_posts_on_parent_id_and_created_at"
      t.index [ "parent_id" ], name: "index_posts_on_parent_id"
      t.index [ "rgt" ], name: "index_posts_on_rgt"
      t.index [ "user_id" ], name: "index_posts_on_user_id"
    end
    create_table "preferences" do |t|
      t.datetime "created_at", null: false
      t.string "name"
      t.datetime "updated_at", null: false
      t.jsonb "value", default: {}
    end
    create_table "push_subscriptions" do |t|
      t.string "auth", null: false
      t.datetime "created_at", null: false
      t.text "endpoint", null: false
      t.datetime "expiration_time"
      t.datetime "last_error_at"
      t.datetime "last_sent_at"
      t.string "p256dh", null: false
      t.datetime "updated_at", null: false
      t.bigint "user_id", null: false
      t.index [ "endpoint" ], name: "index_push_subscriptions_on_endpoint", unique: true
      t.index [ "user_id" ], name: "index_push_subscriptions_on_user_id"
    end
    create_table "roles" do |t|
      t.datetime "created_at", null: false
      t.string "name", null: false
      t.datetime "updated_at", null: false
    end
    create_table "sites" do |t|
      t.string "base_uri"
      t.string "channel"
      t.integer "client", default: 0, null: false
      t.datetime "created_at", null: false
      t.datetime "deleted_at"
      t.string "email"
      t.datetime "last_checked_at"
      t.string "name", null: false
      t.string "path"
      t.datetime "updated_at", null: false
    end
    create_table "taggings" do |t|
      t.string "context", limit: 128
      t.datetime "created_at", precision: nil
      t.bigint "tag_id"
      t.bigint "taggable_id"
      t.string "taggable_type"
      t.bigint "tagger_id"
      t.string "tagger_type"
      t.string "tenant", limit: 128
      t.index [ "tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type" ], name: "taggings_idx", unique: true
      t.index [ "tag_id" ], name: "index_taggings_on_tag_id"
      t.index [ "taggable_id", "taggable_type", "context" ], name: "taggings_taggable_context_idx"
      t.index [ "taggable_id", "taggable_type", "tagger_id", "context" ], name: "taggings_idy"
      t.index [ "taggable_id" ], name: "index_taggings_on_taggable_id"
      t.index [ "taggable_type", "taggable_id" ], name: "index_taggings_on_taggable_type_and_taggable_id"
      t.index [ "taggable_type" ], name: "index_taggings_on_taggable_type"
      t.index [ "tagger_id", "tagger_type" ], name: "index_taggings_on_tagger_id_and_tagger_type"
      t.index [ "tagger_id" ], name: "index_taggings_on_tagger_id"
      t.index [ "tenant" ], name: "index_taggings_on_tenant"
    end
    create_table "tags" do |t|
      t.datetime "created_at", null: false
      t.boolean "is_confirmed", default: false, null: false
      t.string "name"
      t.integer "taggings_count", default: 0
      t.datetime "updated_at", null: false
      t.index [ "name" ], name: "index_tags_on_name", unique: true
    end
    create_table "users" do |t|
      t.datetime "created_at", null: false
      t.string "email", null: false
      t.string "encrypted_password", null: false
      t.integer "likees_count", default: 0, null: false
      t.string "name", default: "", null: false
      t.datetime "remember_created_at"
      t.datetime "reset_password_sent_at"
      t.string "reset_password_token"
      t.string "roles", default: [ "user" ], array: true
      t.datetime "updated_at", null: false
      t.string "username", limit: 30
      t.index [ "email" ], name: "index_users_on_email", unique: true
      t.index [ "reset_password_token" ], name: "index_users_on_reset_password_token", unique: true
      t.index [ "username" ], name: "index_users_on_username", unique: true
    end
    add_foreign_key "federails_activities", "federails_actors", column: "actor_id"
    add_foreign_key "federails_blocks", "federails_actors", column: "actor_id"
    add_foreign_key "federails_blocks", "federails_actors", column: "target_actor_id"
    add_foreign_key "federails_followings", "federails_actors", column: "actor_id"
    add_foreign_key "federails_followings", "federails_actors", column: "target_actor_id"
    add_foreign_key "posts", "articles"
    add_foreign_key "push_subscriptions", "users"
    add_foreign_key "taggings", "tags"
    create_trigger("pg_search_documents_before_insert_update_row_tr", compatibility: 1).
        on("pg_search_documents").
        before(:insert, :update) do
      "new.tsvector_content_tsearch := to_tsvector('korean', coalesce(new.content,''));"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "The initial migration is not revertable"
  end
end
