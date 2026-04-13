# Discord Notification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Discord notification support via incoming webhooks, unified with Slack under an STI-based `notification_channels` / `notification_deliveries` architecture.

**Architecture:** New STI tables replace `slack_workspaces` and `slack_article_deliveries`. Existing Slack code is adapted to use `SlackChannel`/`SlackDelivery`. Discord code uses `DiscordChannel`/`DiscordDelivery`. Both share the same tables and base class. Discord uses `discordrb-webhooks` for posting and Faraday for OAuth2.

**Tech Stack:** Rails 8.1.3, Ruby 4.0.2, PostgreSQL, discordrb-webhooks, Faraday, Minitest, fixtures

---

## File Structure

### New Files

| File | Purpose |
|------|---------|
| `db/migrate/TIMESTAMP_create_notification_tables.rb` | Creates both new tables |
| `db/migrate/TIMESTAMP_migrate_slack_to_notification_tables.rb` | Data copy from old tables |
| `db/migrate/TIMESTAMP_drop_slack_tables.rb` | Final cleanup |
| `app/models/notification_channel.rb` | STI base for channels |
| `app/models/slack_channel.rb` | Slack channel (STI subclass) |
| `app/models/discord_channel.rb` | Discord channel (STI subclass) |
| `app/models/notification_delivery.rb` | STI base for deliveries |
| `app/models/slack_delivery.rb` | Slack delivery (STI subclass) |
| `app/models/discord_delivery.rb` | Discord delivery (STI subclass) |
| `app/models/discord_config.rb` | Discord credentials (Preference) |
| `app/clients/discord_client.rb` | OAuth (Faraday) + webhook posting (discordrb-webhooks) |
| `app/presenters/discord_article_presenter.rb` | Article → Discord Embed params |
| `app/controllers/discord_controller.rb` | OAuth install/callback/channel picker |
| `app/views/discord/channels.html.erb` | Channel picker view |
| `app/services/discord_article_notifier_service.rb` | Enqueue delivery jobs |
| `app/jobs/discord_article_delivery_job.rb` | Post message, record delivery |
| `test/fixtures/notification_channels.yml` | Channel fixtures |
| `test/fixtures/notification_deliveries.yml` | Delivery fixtures |
| `test/models/notification_channel_test.rb` | STI model tests |
| `test/models/notification_delivery_test.rb` | STI model tests |
| `test/clients/discord_client_test.rb` | Client tests |
| `test/presenters/discord_article_presenter_test.rb` | Presenter tests |
| `test/controllers/discord_controller_test.rb` | Controller tests |
| `test/services/discord_article_notifier_service_test.rb` | Service tests |
| `test/jobs/discord_article_delivery_job_test.rb` | Job tests |

### Modified Files

| File | Change |
|------|--------|
| `Gemfile` | Add `discordrb-webhooks` |
| `app/models/article.rb` | Add `notification_deliveries` association, remove `slack_article_deliveries` |
| `app/clients/slack_client.rb` | Accept `SlackChannel` instead of `SlackWorkspace`, use `webhook_url` |
| `app/controllers/slack_controller.rb` | Use `SlackChannel` instead of `SlackWorkspace` |
| `app/jobs/slack_article_delivery_job.rb` | Use `SlackChannel`/`SlackDelivery` |
| `app/services/slack_article_notifier_service.rb` | Use `SlackChannel.delivery_ready` |
| `app/jobs/social_post_job.rb` | Add `DiscordArticleNotifierService` call |
| `config/routes.rb` | Add Discord routes |

### Deleted Files (final task)

| File | Reason |
|------|--------|
| `app/models/slack_workspace.rb` | Replaced by `SlackChannel` |
| `app/models/slack_article_delivery.rb` | Replaced by `SlackDelivery` |
| `test/fixtures/slack_workspaces.yml` | Replaced by `notification_channels.yml` |
| `test/fixtures/slack_article_deliveries.yml` | Replaced by `notification_deliveries.yml` |
| `test/models/article_slack_notification_test.rb` | Updated for new models |

---

## Task 1: Add discordrb-webhooks gem

**Files:**
- Modify: `Gemfile`

- [ ] **Step 1: Add gem**

```bash
bundle add discordrb-webhooks
```

- [ ] **Step 2: Verify installation**

Run: `bundle show discordrb-webhooks`
Expected: gem path displayed

- [ ] **Step 3: Commit**

```bash
git add Gemfile Gemfile.lock
git commit -m "chore: add discordrb-webhooks gem for Discord webhook posting"
```

---

## Task 2: Create notification tables migration

**Files:**
- Create: `db/migrate/TIMESTAMP_create_notification_tables.rb`

- [ ] **Step 1: Generate migration**

```bash
rails generate migration CreateNotificationTables
```

- [ ] **Step 2: Write migration**

```ruby
# frozen_string_literal: true

class CreateNotificationTables < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_channels do |t|
      t.string :type, null: false
      t.string :status, null: false, default: "active"
      t.datetime :last_verified_at
      t.string :remote_id, null: false
      t.string :name, null: false
      t.string :webhook_url, null: false
      t.string :channel_id, null: false
      t.string :channel_name, null: false
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :notification_channels, [ :type, :remote_id ], unique: true

    create_table :notification_deliveries do |t|
      t.string :type, null: false
      t.references :article, foreign_key: true
      t.references :notification_channel, foreign_key: true
      t.string :channel_id, null: false
      t.string :channel_name, null: false
      t.string :status, null: false, default: "failed"
      t.datetime :sent_at
      t.text :error_message
      t.string :message_id
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :notification_deliveries,
              [ :article_id, :notification_channel_id, :channel_id ],
              unique: true,
              name: "idx_notification_deliveries_uniqueness"
  end
end
```

- [ ] **Step 3: Run migration**

```bash
rails db:migrate
```

Expected: `== CreateNotificationTables: migrated`

- [ ] **Step 4: Commit**

```bash
git add db/migrate/
git commit -m "db: create notification_channels and notification_deliveries tables"
```

---

## Task 3: Create STI models + update Article model

**Files:**
- Create: `app/models/notification_channel.rb`
- Create: `app/models/slack_channel.rb`
- Create: `app/models/discord_channel.rb`
- Create: `app/models/notification_delivery.rb`
- Create: `app/models/slack_delivery.rb`
- Create: `app/models/discord_delivery.rb`
- Create: `test/models/notification_channel_test.rb`
- Create: `test/models/notification_delivery_test.rb`
- Modify: `app/models/article.rb`

- [ ] **Step 1: Write failing test for NotificationChannel**

```ruby
# test/models/notification_channel_test.rb
# frozen_string_literal: true

require "test_helper"

class NotificationChannelTest < ActiveSupport::TestCase
  test "validates presence of required fields" do
    channel = NotificationChannel.new
    assert_not channel.valid?
    [ :remote_id, :name, :webhook_url, :channel_id, :channel_name ].each do |attr|
      assert_includes channel.errors[attr], "can't be blank"
    end
  end

  test "validates remote_id uniqueness scoped to type" do
    existing = notification_channels(:acme_slack)
    duplicate = NotificationChannel.new(
      type: "SlackChannel",
      remote_id: existing.remote_id,
      name: "Dup",
      webhook_url: "https://example.com/hook",
      channel_id: "C123",
      channel_name: "test"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:remote_id], "has already been taken"
  end

  test "delivery_ready scope returns active channels with webhook" do
    ready = NotificationChannel.delivery_ready
    assert ready.all? { |c| c.active? && c.webhook_url.present? && c.channel_id.present? && c.channel_name.present? }
  end

  test "default status is active" do
    channel = NotificationChannel.new(
      remote_id: "R_NEW", name: "New", webhook_url: "https://hook",
      channel_id: "C_NEW", channel_name: "new"
    )
    assert_predicate channel, :active?
  end
end
```

- [ ] **Step 2: Write failing test for NotificationDelivery**

```ruby
# test/models/notification_delivery_test.rb
# frozen_string_literal: true

require "test_helper"

class NotificationDeliveryTest < ActiveSupport::TestCase
  test "validates presence of channel_id and channel_name" do
    delivery = NotificationDelivery.new(
      article: articles(:ruby_article),
      notification_channel: notification_channels(:acme_slack)
    )
    assert_not delivery.valid?
    assert_includes delivery.errors[:channel_id], "can't be blank"
    assert_includes delivery.errors[:channel_name], "can't be blank"
  end

  test "default status is failed" do
    delivery = NotificationDelivery.create!(
      article: articles(:ruby_article),
      notification_channel: notification_channels(:acme_slack),
      channel_id: "C_DEFAULT",
      channel_name: "test"
    )
    assert_predicate delivery, :failed?
  end

  test "validates article uniqueness scoped to channel and channel_id" do
    existing = notification_deliveries(:existing_slack_delivery)
    duplicate = NotificationDelivery.new(
      article: existing.article,
      notification_channel: existing.notification_channel,
      channel_id: existing.channel_id,
      channel_name: "dup"
    )
    assert_not duplicate.valid?
  end
end
```

- [ ] **Step 3: Create fixtures**

```yaml
# test/fixtures/notification_channels.yml
acme_slack:
  type: SlackChannel
  remote_id: T123ACME
  name: Acme Workspace
  webhook_url: https://hooks.slack.com/services/T123ACME/B123/ACME
  channel_id: CNEWS1
  channel_name: ruby-news
  status: active
  last_verified_at: <%= 1.hour.ago %>

globex_slack:
  type: SlackChannel
  remote_id: T456GLOBEX
  name: Globex Workspace
  webhook_url: https://hooks.slack.com/services/T456GLOBEX/B456/GLOBEX
  channel_id: CNEWS2
  channel_name: team-ruby
  status: active
  last_verified_at: <%= 2.hours.ago %>

acme_discord:
  type: DiscordChannel
  remote_id: D789ACME
  name: Acme Discord
  webhook_url: https://discord.com/api/webhooks/123/abc
  channel_id: DCNEWS1
  channel_name: al-news
  status: active
  last_verified_at: <%= 30.minutes.ago %>
```

```yaml
# test/fixtures/notification_deliveries.yml
existing_slack_delivery:
  type: SlackDelivery
  article: ruby_article
  notification_channel: acme_slack
  channel_id: CDELIVERED
  channel_name: delivered
  status: sent
  sent_at: <%= 30.minutes.ago %>
```

- [ ] **Step 4: Run tests to verify they fail**

```bash
rails test test/models/notification_channel_test.rb test/models/notification_delivery_test.rb
```

Expected: FAIL — `NotificationChannel` and `NotificationDelivery` not defined yet

- [ ] **Step 5: Implement NotificationChannel**

```ruby
# app/models/notification_channel.rb
# frozen_string_literal: true
# rbs_inline: enabled

class NotificationChannel < ApplicationRecord
  has_many :notification_deliveries, dependent: :destroy

  enum :status, {
    active: "active",
    inactive: "inactive",
    error: "error"
  }, default: :active, validate: true

  validates :remote_id, :name, :webhook_url, :channel_id, :channel_name, presence: true
  validates :remote_id, uniqueness: { scope: :type }

  scope :active, -> { where(status: :active) }
  scope :delivery_ready, -> {
    active.where.not(webhook_url: [ nil, "" ], channel_id: [ nil, "" ], channel_name: [ nil, "" ])
  }
end
```

- [ ] **Step 6: Implement SlackChannel**

```ruby
# app/models/slack_channel.rb
# frozen_string_literal: true
# rbs_inline: enabled

class SlackChannel < NotificationChannel
end
```

- [ ] **Step 7: Implement DiscordChannel**

```ruby
# app/models/discord_channel.rb
# frozen_string_literal: true
# rbs_inline: enabled

class DiscordChannel < NotificationChannel
end
```

- [ ] **Step 8: Implement NotificationDelivery**

```ruby
# app/models/notification_delivery.rb
# frozen_string_literal: true
# rbs_inline: enabled

class NotificationDelivery < ApplicationRecord
  belongs_to :article
  belongs_to :notification_channel

  enum :status, {
    sent: "sent",
    failed: "failed"
  }, default: :failed, validate: true

  validates :channel_id, :channel_name, presence: true
  validates :article_id, uniqueness: { scope: [ :notification_channel_id, :channel_id ] }
end
```

- [ ] **Step 9: Implement SlackDelivery**

```ruby
# app/models/slack_delivery.rb
# frozen_string_literal: true
# rbs_inline: enabled

class SlackDelivery < NotificationDelivery
end
```

- [ ] **Step 10: Implement DiscordDelivery**

```ruby
# app/models/discord_delivery.rb
# frozen_string_literal: true
# rbs_inline: enabled

class DiscordDelivery < NotificationDelivery
end
```

- [ ] **Step 11: Update Article model association**

In `app/models/article.rb`, replace:
```ruby
has_many :slack_article_deliveries, dependent: :destroy
```
with:
```ruby
has_many :notification_deliveries, dependent: :destroy
```

- [ ] **Step 12: Run tests to verify they pass**

```bash
rails test test/models/notification_channel_test.rb test/models/notification_delivery_test.rb
```

Expected: PASS (all tests green)

- [ ] **Step 13: Validate**

```bash
rails validate files=app/models/notification_channel.rb,app/models/notification_delivery.rb,app/models/slack_channel.rb,app/models/discord_channel.rb,app/models/slack_delivery.rb,app/models/discord_delivery.rb level=rails
```

- [ ] **Step 14: Commit**

```bash
git add app/models/notification_channel.rb app/models/notification_delivery.rb \
  app/models/slack_channel.rb app/models/slack_delivery.rb \
  app/models/discord_channel.rb app/models/discord_delivery.rb \
  app/models/article.rb \
  test/models/notification_channel_test.rb test/models/notification_delivery_test.rb \
  test/fixtures/notification_channels.yml test/fixtures/notification_deliveries.yml
git commit -m "feat: add STI notification_channels and notification_deliveries models"
```

---

## Task 4: Data migration (copy Slack data to new tables)

**Files:**
- Create: `db/migrate/TIMESTAMP_migrate_slack_to_notification_tables.rb`

- [ ] **Step 1: Generate migration**

```bash
rails generate migration MigrateSlackToNotificationTables
```

- [ ] **Step 2: Write data migration**

```ruby
# frozen_string_literal: true

class MigrateSlackToNotificationTables < ActiveRecord::Migration[8.1]
  def up
    # Migrate slack_workspaces → notification_channels (SlackChannel)
    execute <<~SQL
      INSERT INTO notification_channels (type, status, last_verified_at, remote_id, name, webhook_url, channel_id, channel_name, metadata, created_at, updated_at)
      SELECT 'SlackChannel', status, last_verified_at, team_id, team_name, incoming_webhook_url, channel_id, channel_name, '{}', created_at, updated_at
      FROM slack_workspaces
      ON CONFLICT DO NOTHING
    SQL

    # Migrate slack_article_deliveries → notification_deliveries (SlackDelivery)
    execute <<~SQL
      INSERT INTO notification_deliveries (type, article_id, notification_channel_id, channel_id, channel_name, status, sent_at, error_message, message_id, metadata, created_at, updated_at)
      SELECT 'SlackDelivery', sad.article_id, nc.id, sad.channel_id, sad.channel_name, sad.status, sad.sent_at, sad.error_message, sad.slack_message_ts, '{}', sad.created_at, sad.updated_at
      FROM slack_article_deliveries sad
      JOIN notification_channels nc ON nc.remote_id = (
        SELECT team_id FROM slack_workspaces WHERE id = sad.slack_workspace_id
      )
      ON CONFLICT DO NOTHING
    SQL
  end

  def down
    execute "DELETE FROM notification_deliveries WHERE type = 'SlackDelivery'"
    execute "DELETE FROM notification_channels WHERE type = 'SlackChannel'"
  end
end
```

- [ ] **Step 3: Run migration**

```bash
rails db:migrate
```

- [ ] **Step 4: Verify data copy**

```bash
rails runner 'puts "Channels: #{NotificationChannel.count}"; puts "Deliveries: #{NotificationDelivery.count}"'
```

Expected: Channel and delivery counts match old table counts

- [ ] **Step 5: Commit**

```bash
git add db/migrate/
git commit -m "db: migrate slack_workspaces and slack_article_deliveries to unified tables"
```

---

## Task 5: Migrate existing Slack code to new models

This is the cut-over task. After this, all Slack code uses the new unified models.

**Files:**
- Modify: `app/clients/slack_client.rb`
- Modify: `app/controllers/slack_controller.rb`
- Modify: `app/jobs/slack_article_delivery_job.rb`
- Modify: `app/services/slack_article_notifier_service.rb`
- Modify: `test/controllers/slack_controller_test.rb`
- Modify: `test/services/slack_client_test.rb`
- Modify: `test/services/slack_article_notifier_service_test.rb`
- Modify: `test/jobs/slack_article_delivery_job_test.rb`

- [ ] **Step 1: Update SlackClient**

In `app/clients/slack_client.rb`, change constructor to accept `SlackChannel`:

```ruby
# app/clients/slack_client.rb
# frozen_string_literal: true
# rbs_inline: enabled

class SlackClient
  class ApiError < StandardError; end

  AUTHORIZE_URL = "https://slack.com/oauth/v2/authorize" #: String

  # ── Instance methods ────────────────────────────────────

  #: (SlackChannel channel) -> void
  def initialize(channel)
    @channel = channel
  end

  #: (text: String, blocks: Array[untyped]) -> Hash[String, String]
  def post_message(text:, blocks:)
    response = webhook_client.post do |request|
      request.body = {
        text:,
        blocks:
      }
    end

    unless response.success?
      raise ApiError, "Slack webhook 전송에 실패했습니다. HTTP #{response.status}"
    end

    {}
  rescue Faraday::Error => e
    raise_api_error(e)
  end

  private

  attr_reader :channel #: SlackChannel

  # @rbs @webhook_client: Faraday::Connection?

  #: () -> Faraday::Connection
  def webhook_client
    @webhook_client ||= Faraday.new(url: channel.webhook_url) do |faraday|
      faraday.request :json
      faraday.response :raise_error
      faraday.adapter Faraday.default_adapter
    end
  end

  #: (Exception error) -> bot
  def raise_api_error(error)
    raise ApiError, "#{error.class}: #{error.message}"
  end

  class << self
    # ── OAuth (class methods) ──────────────────────────────

    #: (redirect_uri: String, state: String) -> String
    def authorize_url(redirect_uri:, state:)
      query = {
        client_id: SlackConfig.client_id,
        scope: SlackConfig.install_scope,
        redirect_uri:,
        state:
      }.to_query

      "#{AUTHORIZE_URL}?#{query}"
    end

    #: (String code, redirect_uri: String) -> ActiveSupport::HashWithIndifferentAccess
    def exchange_code(code, redirect_uri:)
      response = oauth_client.oauth_v2_access(
        client_id: SlackConfig.client_id,
        client_secret: SlackConfig.client_secret,
        code:,
        redirect_uri:
      )

      response.to_h.with_indifferent_access
    rescue Slack::Web::Api::Errors::SlackError => e
      raise ApiError, e.message
    rescue Faraday::Error => e
      raise ApiError, "#{e.class}: #{e.message}"
    end

    #: (?String? token) -> Slack::Web::Client
    def oauth_client(token = nil)
      Slack::Web::Client.new(
        token:,
        open_timeout: 3,
        timeout: 5
      )
    end
  end
end
```

Key changes: `@workspace` → `@channel`, `workspace.incoming_webhook_url` → `channel.webhook_url`. Removed `list_channels` instance method (unused in webhook-only flow).

- [ ] **Step 2: Update SlackController**

In `app/controllers/slack_controller.rb`, change `SlackWorkspace` to `SlackChannel`:

```ruby
# app/controllers/slack_controller.rb
# frozen_string_literal: true
# rbs_inline: enabled

class SlackController < ApplicationController
  protect_from_forgery except: :events
  skip_before_action :authenticate_user!, only: :events
  before_action :verify_slack_signature, only: :events

  def install
    unless SlackConfig.configured?
      redirect_to edit_user_registration_path, alert: "Slack 연동이 아직 설정되지 않았습니다. 관리자에게 문의해 주세요."
      return
    end

    state = SecureRandom.hex(16)
    session[:slack_oauth_state] = state

    redirect_to SlackClient.authorize_url(
      redirect_uri: slack_oauth_callback_url,
      state:
    ), allow_other_host: true
  end

  def callback
    stored_state = session.delete(:slack_oauth_state)
    incoming_state = params[:state]

    if stored_state.blank? || incoming_state.blank? || !ActiveSupport::SecurityUtils.secure_compare(stored_state, incoming_state)
      redirect_to edit_user_registration_path, alert: "Slack 인증 상태가 일치하지 않습니다."
      return
    end

    oauth = SlackClient.exchange_code(params[:code], redirect_uri: slack_oauth_callback_url)
    team = oauth.fetch("team")
    incoming_webhook = oauth.fetch("incoming_webhook")

    SlackChannel.transaction do
      channel = SlackChannel.find_or_initialize_by(remote_id: team.fetch("id"))
      channel.assign_attributes(
        name: team.fetch("name"),
        webhook_url: incoming_webhook.fetch("url"),
        channel_id: incoming_webhook.fetch("channel_id"),
        channel_name: incoming_webhook.fetch("channel"),
        status: :active,
        last_verified_at: Time.current
      )
      channel.save!
    end

    redirect_to edit_user_registration_path, notice: "Slack 워크스페이스가 연결되었습니다."
  rescue KeyError, SlackClient::ApiError, ActiveRecord::RecordInvalid => e
    redirect_to edit_user_registration_path, alert: "Slack 연결에 실패했습니다: #{e.message}"
  end

  def events
    if params[:type] == "url_verification"
      render json: { challenge: params[:challenge] }
    else
      head :ok
    end
  end

  private

  def verify_slack_signature
    timestamp = request.headers["X-Slack-Request-Timestamp"]
    signature = request.headers["X-Slack-Signature"]
    signing_secret = SlackConfig.signing_secret

    return head :unauthorized if timestamp.blank? || signature.blank?
    return head :unauthorized if signing_secret.blank?
    return head :unauthorized if (Time.zone.now.to_i - timestamp.to_i).abs > 300

    sig_basestring = "v0:#{timestamp}:#{request.raw_post}"
    my_signature = "v0=" + OpenSSL::HMAC.hexdigest("SHA256", signing_secret, sig_basestring)

    head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(my_signature, signature)
  end
end
```

Key changes: `SlackWorkspace` → `SlackChannel`, `team_id` → `remote_id`, `team_name` → `name`, `incoming_webhook_url` → `webhook_url`, removed `bot_access_token`/`bot_user_id` assignment.

- [ ] **Step 3: Update SlackArticleDeliveryJob**

In `app/jobs/slack_article_delivery_job.rb`, change to use `SlackChannel`/`SlackDelivery`:

```ruby
# app/jobs/slack_article_delivery_job.rb
# frozen_string_literal: true
# rbs_inline: enabled

class SlackArticleDeliveryJob < ApplicationJob
  queue_as :default

  #: (Integer article_id, Integer channel_id) -> void
  def perform(article_id, channel_id)
    article = Article.find_by(id: article_id)
    channel = SlackChannel.find_by(id: channel_id)
    return unless article && channel&.webhook_url.present? && channel.channel_id.present? && channel.channel_name.present?

    delivery = find_or_create_delivery(article, channel)
    message = SlackArticlePresenter.new(article)

    delivery.with_lock do
      return if delivery.sent?

      response = SlackClient.new(channel).post_message(
        text: message.text,
        blocks: message.blocks
      )

      persist_delivery_success(delivery, channel.channel_name, response["ts"])
    end
  rescue SlackClient::ApiError => e
    delivery&.with_lock do
      delivery.reload
      return if delivery.sent?

      delivery.update!(channel_name: channel.channel_name, status: :failed, error_message: e.message)
    end
  end

  private

  #: (SlackDelivery delivery, String channel_name, String message_ts) -> void
  def persist_delivery_success(delivery, channel_name, message_ts)
    delivery.update!(
      channel_name:,
      status: :sent,
      sent_at: Time.current,
      error_message: nil,
      message_id: message_ts
    )
  end

  #: (Article article, SlackChannel channel) -> SlackDelivery
  def find_or_create_delivery(article, channel)
    existing_delivery = SlackDelivery.find_by(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id
    )
    return existing_delivery if existing_delivery

    SlackDelivery.create!(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id,
      channel_name: channel.channel_name,
      status: :failed
    )
  rescue ActiveRecord::RecordNotUnique
    SlackDelivery.find_by!(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id
    )
  end
end
```

Key changes: `SlackWorkspace` → `SlackChannel`, `SlackArticleDelivery` → `SlackDelivery`, `workspace_id` → `channel_id`, `slack_workspace` → `notification_channel`, `slack_message_ts` → `message_id`.

- [ ] **Step 4: Update SlackArticleNotifierService**

In `app/services/slack_article_notifier_service.rb`:

```ruby
# app/services/slack_article_notifier_service.rb
# frozen_string_literal: true
# rbs_inline: enabled

class SlackArticleNotifierService < OperationService
  #: (Article article) -> Dry::Monads::Result
  def call(article)
    return Failure(:deleted) unless article.deleted_at.nil?
    return Failure(:not_confirmed) unless article.slug.present? && article.title_ko.present?

    delivery_jobs = SlackChannel.delivery_ready.order(:id).to_a.map do |channel|
      SlackArticleDeliveryJob.new(article.id, channel.id)
    end

    return nil if delivery_jobs.empty?

    ActiveJob.perform_all_later(delivery_jobs)

    true
  end
end
```

Key changes: `SlackWorkspace` → `SlackChannel`, `workspace` → `channel`.

- [ ] **Step 5: Update test fixtures**

Update `test/services/slack_client_test.rb` to use `notification_channels(:acme_slack)`:

```ruby
# test/services/slack_client_test.rb
# frozen_string_literal: true

require "test_helper"

class SlackClientTest < ActiveSupport::TestCase
  test "incoming webhook으로 메시지를 전송한다" do
    channel = notification_channels(:acme_slack)
    client = SlackClient.new(channel)
    response = Struct.new(:success?, :status).new(true, 200)
    webhook_client = Struct.new(:calls, :response) do
      def post
        request = Struct.new(:body).new
        yield request
        calls << request.body
        response
      end
    end.new([], response)

    client.stub(:webhook_client, webhook_client) do
      assert_equal({}, client.post_message(text: "hello", blocks: []))
    end

    assert_equal [ { text: "hello", blocks: [] } ], webhook_client.calls
  end

  test "Faraday 오류를 ApiError로 래핑한다" do
    channel = notification_channels(:acme_slack)
    client = SlackClient.new(channel)

    error = assert_raises(SlackClient::ApiError) do
      client.stub(:webhook_client, Struct.new(:exception) {
        def post
          raise exception
        end
      }.new(Faraday::TimeoutError.new("execution expired"))) do
        client.post_message(text: "hello", blocks: [])
      end
    end

    assert_includes error.message, "execution expired"
  end
end
```

Update `test/services/slack_article_notifier_service_test.rb`:

```ruby
# test/services/slack_article_notifier_service_test.rb
# frozen_string_literal: true

require "test_helper"

class SlackArticleNotifierServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @article = articles(:ruby_article)
    SlackDelivery.where(article: @article).delete_all
  end

  test "channel 기준으로 기사 알림 잡을 enqueue한다" do
    slack_channels = SlackChannel.delivery_ready.order(:id)
    assert_enqueued_jobs slack_channels.count, only: SlackArticleDeliveryJob do
      SlackArticleNotifierService.new.call(@article)
    end

    enqueued = enqueued_jobs.select { |j| j[:job] == SlackArticleDeliveryJob }
    channel_ids = enqueued.map { |j| j[:args][1] }.sort

    assert_equal slack_channels.pluck(:id), channel_ids
  end

  test "같은 기사에 대해 두 번 호출해도 각 channel마다 잡이 enqueue된다" do
    slack_channels = SlackChannel.delivery_ready
    assert_enqueued_jobs slack_channels.count * 2, only: SlackArticleDeliveryJob do
      service = SlackArticleNotifierService.new
      service.call(@article)
      service.call(@article)
    end
  end

  test "confirmed 되지 않은 기사는 발송하지 않는다" do
    article = articles(:site_only_article)

    assert_no_enqueued_jobs only: SlackArticleDeliveryJob do
      SlackArticleNotifierService.new.call(article)
    end
  end
end
```

Update `test/controllers/slack_controller_test.rb` — change `SlackWorkspace.find_by!(team_id: ...)` to `SlackChannel.find_by!(remote_id: ...)`, remove `bot_access_token`/`bot_user_id` assertions:

```ruby
# test/controllers/slack_controller_test.rb
# frozen_string_literal: true

require "test_helper"
require "uri"

class SlackControllerTest < ActionDispatch::IntegrationTest
  test "POST events rejects when signing secret is blank" do
    SlackConfig.stub(:signing_secret, "") do
      post slack_events_path,
        params: { type: "url_verification", challenge: "challenge-token" },
        headers: {
          "X-Slack-Request-Timestamp" => Time.now.to_i.to_s,
          "X-Slack-Signature" => "v0=test"
        }
    end

    assert_response :unauthorized
  end

  test "GET install redirects to slack authorize url" do
    sign_in_as(users(:john))

    SlackConfig.stub(:configured?, true) do
      SlackConfig.stub(:client_id, "client-123") do
        get slack_install_path
      end
    end

    assert_response :redirect
    assert_includes response.location, "https://slack.com/oauth/v2/authorize"
    assert_includes response.location, "client_id=client-123"
  end

  test "GET install redirects with alert when not configured" do
    sign_in_as(users(:john))

    SlackConfig.stub(:configured?, false) do
      get slack_install_path
    end

    assert_redirected_to edit_user_registration_path
    assert_equal "Slack 연동이 아직 설정되지 않았습니다. 관리자에게 문의해 주세요.", flash[:alert]
  end

  test "GET callback rejects when state param is missing" do
    sign_in_as(users(:john))

    SlackConfig.stub(:configured?, true) { get slack_install_path }

    get slack_oauth_callback_path, params: { code: "oauth-code" }

    assert_redirected_to edit_user_registration_path
    assert_equal "Slack 인증 상태가 일치하지 않습니다.", flash[:alert]
  end

  test "GET callback rejects when session state is missing" do
    sign_in_as(users(:john))

    get slack_oauth_callback_path, params: { code: "oauth-code", state: "some-state" }

    assert_redirected_to edit_user_registration_path
    assert_equal "Slack 인증 상태가 일치하지 않습니다.", flash[:alert]
  end

  test "GET callback rejects when both state values are empty" do
    sign_in_as(users(:john))

    get slack_oauth_callback_path, params: { code: "oauth-code", state: "" }

    assert_redirected_to edit_user_registration_path
    assert_equal "Slack 인증 상태가 일치하지 않습니다.", flash[:alert]
  end

  test "GET callback stores channel webhook configuration and redirects to account page" do
    sign_in_as(users(:john))

    SlackConfig.stub(:configured?, true) { get slack_install_path }
    state = URI.decode_www_form(URI.parse(response.location).query).to_h.fetch("state")

    oauth_response = {
      "team" => { "id" => "TCALLBACK", "name" => "Callback Team" },
      "access_token" => "xoxb-callback",
      "bot_user_id" => "UBOTCALLBACK",
      "incoming_webhook" => {
        "url" => "https://hooks.slack.com/services/TCALLBACK/B123/abc",
        "channel" => "hada-news",
        "channel_id" => "CCALLBACK"
      }
    }

    SlackClient.stub(:exchange_code, oauth_response) do
      get slack_oauth_callback_path, params: { code: "oauth-code", state: state }
    end

    assert_redirected_to edit_user_registration_path

    channel = SlackChannel.find_by!(remote_id: "TCALLBACK")

    assert_equal "Callback Team", channel.name
    assert_equal "https://hooks.slack.com/services/TCALLBACK/B123/abc", channel.webhook_url
    assert_equal "CCALLBACK", channel.channel_id
    assert_equal "hada-news", channel.channel_name
  end

  test "POST events accepts url verification without login when signature is valid" do
    timestamp = Time.now.to_i.to_s
    payload = { type: "url_verification", challenge: "challenge-token" }
    raw_body = payload.to_json
    signature = "v0=" + OpenSSL::HMAC.hexdigest("SHA256", "signing-secret", "v0:#{timestamp}:#{raw_body}")

    SlackConfig.stub(:signing_secret, "signing-secret") do
      post slack_events_path,
        params: raw_body,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "X-Slack-Request-Timestamp" => timestamp,
          "X-Slack-Signature" => signature
        }
    end

    assert_response :success
    assert_equal "challenge-token", response.parsed_body["challenge"]
  end
end
```

Update `test/jobs/slack_article_delivery_job_test.rb` — change `SlackWorkspace` → `SlackChannel`, `SlackArticleDelivery` → `SlackDelivery`:

```ruby
# test/jobs/slack_article_delivery_job_test.rb
# frozen_string_literal: true

require "test_helper"

class SlackArticleDeliveryJobTest < ActiveJob::TestCase
  test "전송 기록 저장에 실패하면 예외를 발생시켜 재시도 가능 상태로 남긴다" do
    article = articles(:ruby_article)
    channel = notification_channels(:acme_slack)
    delivery = SlackDelivery.create!(
      article:,
      notification_channel: channel,
      channel_id: "CFAILED1",
      channel_name: "ruby-news",
      status: :failed
    )

    SlackClient.stub(:new, Struct.new(:response) {
      def post_message(text:, blocks:)
        response
      end
    }.new({ "ts" => "123.456" })) do
      job = SlackArticleDeliveryJob.new
      job.stub(:persist_delivery_success, ->(_d, _c, _t) { delivery.errors.add(:base, "test"); raise ActiveRecord::RecordInvalid, delivery }) do
        error = assert_raises(ActiveRecord::RecordInvalid) do
          job.perform(article.id, channel.id)
        end

        assert_equal delivery.id, error.record.id
      end
    end
  end

  test "전송 실패 처리 중 이미 sent 상태면 failed로 되돌리지 않는다" do
    article = articles(:ruby_article)
    channel = notification_channels(:acme_slack)
    delivery = Class.new do
      attr_reader :update_called

      def initialize
        @sent = false
        @update_called = false
      end

      def with_lock
        yield
      end

      def sent?
        @sent
      end

      def reload
        @sent = true
      end

      def update!(**)
        @update_called = true
      end
    end.new

    SlackClient.stub(:new, Struct.new(:error) {
      def post_message(text:, blocks:)
        raise error
      end
    }.new(SlackClient::ApiError.new("timeout"))) do
      job = SlackArticleDeliveryJob.new
      job.stub(:find_or_create_delivery, delivery) do
        job.perform(article.id, channel.id)
      end
    end

    assert_predicate delivery, :sent?
    refute delivery.update_called
  end

  test "신규 delivery의 기본 상태는 failed다" do
    delivery = SlackDelivery.create!(
      article: articles(:ruby_article),
      notification_channel: notification_channels(:acme_slack),
      channel_id: "CDEFAULT1",
      channel_name: "ruby-news"
    )

    assert_predicate delivery, :failed?
  end
end
```

- [ ] **Step 6: Run all Slack tests**

```bash
rails test test/controllers/slack_controller_test.rb test/services/slack_client_test.rb test/services/slack_article_notifier_service_test.rb test/jobs/slack_article_delivery_job.rb test/presenters/slack_article_presenter_test.rb
```

Expected: All tests pass

- [ ] **Step 7: Commit**

```bash
git add app/clients/slack_client.rb app/controllers/slack_controller.rb \
  app/jobs/slack_article_delivery_job.rb app/services/slack_article_notifier_service.rb \
  test/controllers/slack_controller_test.rb test/services/slack_client_test.rb \
  test/services/slack_article_notifier_service_test.rb test/jobs/slack_article_delivery_job_test.rb
git commit -m "refactor: migrate Slack code to use unified notification models"
```

---

## Task 6: DiscordConfig + DiscordClient

**Files:**
- Create: `app/models/discord_config.rb`
- Create: `app/clients/discord_client.rb`
- Create: `test/clients/discord_client_test.rb`

- [ ] **Step 1: Write failing test for DiscordClient**

```ruby
# test/clients/discord_client_test.rb
# frozen_string_literal: true

require "test_helper"

class DiscordClientTest < ActiveSupport::TestCase
  test "post_embed이 discordrb-webhooks를 통해 embed을 전송한다" do
    channel = notification_channels(:acme_discord)
    client = DiscordClient.new(channel)

    embed_params = {
      title: "테스트 기사",
      url: "https://alnews.app/articles/test",
      description: "테스트 설명",
      color: 3447003,
      footer_text: "AlNews",
      timestamp: Time.current
    }

    mock_response = { "id" => "123456789" }
    webhook_client = Minitest::Mock.new
    webhook_client.expect(:execute, mock_response) { |wait:| wait == true }

    Discordrb::Webhooks::Client.stub(:new, webhook_client) do
      result = client.post_embed(embed_params)
      assert_equal "123456789", result
    end

    webhook_client.verify
  end

  test "API 오류를 ApiError로 래핑한다" do
    channel = notification_channels(:acme_discord)
    client = DiscordClient.new(channel)

    Discordrb::Webhooks::Client.stub(:new, ->(_url:) {
      Struct.new(:run) do
        def execute(wait: false, &block)
          raise Discordrb::Errors::Code.new(401, "Unauthorized")
        end
      end.new
    }) do
      error = assert_raises(DiscordClient::ApiError) do
        client.post_embed({ title: "test" })
      end

      assert_includes error.message, "401"
    end
  end

  test "authorize_url이 올바른 Discord OAuth URL을 반환한다" do
    DiscordConfig.stub(:client_id, "dc-test-id") do
      url = DiscordClient.authorize_url(redirect_uri: "http://localhost:3000/discord/oauth/callback", state: "test-state")
      parsed = URI.parse(url)

      assert_equal "discord.com", parsed.host
      params = URI.decode_www_form(parsed.query).to_h
      assert_equal "dc-test-id", params["client_id"]
      assert_equal "bot webhook.incoming", params["scope"]
      assert_equal "536870912", params["permissions"]
      assert_equal "test-state", params["state"]
    end
  end

  test "exchange_code가 OAuth 토큰을 교환한다" do
    mock_response = Struct.new(:success?, :body, :status).new(
      true,
      { access_token: "bot-token", guild: { id: "G123", name: "Test Guild" } }.to_json,
      200
    )
    mock_faraday = Struct.new(:response) do
      def post
        Struct.new(:req).new
        response
      end
    end.new(mock_response)

    DiscordConfig.stub(:client_id, "dc-id") do
      DiscordConfig.stub(:client_secret, "dc-secret") do
        Faraday.stub(:post, mock_faraday) do
          result = DiscordClient.exchange_code("test-code", redirect_uri: "http://localhost/callback")
          assert_equal "bot-token", result[:access_token]
          assert_equal "G123", result[:guild][:id]
        end
      end
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
rails test test/clients/discord_client_test.rb
```

Expected: FAIL — `DiscordClient` not defined

- [ ] **Step 3: Implement DiscordConfig**

```ruby
# app/models/discord_config.rb
# frozen_string_literal: true
# rbs_inline: enabled

class DiscordConfig
  PREFERENCE_KEY = "discord_oauth" #: String

  class << self
    #: () -> String?
    def client_id
      preference&.client_id
    end

    #: () -> String?
    def client_secret
      preference&.client_secret
    end

    #: () -> bool
    def configured?
      client_id.present? && client_secret.present?
    end

    private

    #: () -> Preference?
    def preference
      Preference.get_object(PREFERENCE_KEY)
    end
  end
end
```

- [ ] **Step 4: Implement DiscordClient**

```ruby
# app/clients/discord_client.rb
# frozen_string_literal: true
# rbs_inline: enabled

class DiscordClient
  class ApiError < StandardError; end

  AUTHORIZE_URL = "https://discord.com/api/oauth2/authorize" #: String
  TOKEN_URL = "https://discord.com/api/oauth2/token" #: String
  API_BASE = "https://discord.com/api/v10" #: String

  #: (DiscordChannel channel) -> void
  def initialize(channel)
    @channel = channel
  end

  #: (Hash embed_params) -> String?
  def post_embed(embed_params)
    webhook = Discordrb::Webhooks::Client.new(url: @channel.webhook_url)
    response = webhook.execute(wait: true) do |builder|
      builder.add_embed do |embed|
        embed.title = embed_params[:title]
        embed.url = embed_params[:url]
        embed.description = embed_params[:description]
        embed.colour = embed_params[:color] if embed_params[:color]
        if embed_params[:image_url].present?
          embed.image = Discordrb::Webhooks::EmbedImage.new(url: embed_params[:image_url])
        end
        if embed_params[:footer_text].present?
          embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: embed_params[:footer_text])
        end
        embed.timestamp = embed_params[:timestamp] if embed_params[:timestamp]
      end
    end
    response.is_a?(Hash) ? response["id"] : nil
  rescue Discordrb::Errors::Code => e
    raise ApiError, "Discord API 오류: #{e.code} #{e.message}"
  rescue StandardError => e
    raise ApiError, "#{e.class}: #{e.message}"
  end

  class << self
    #: (redirect_uri: String, state: String) -> String
    def authorize_url(redirect_uri:, state:)
      query = {
        client_id: DiscordConfig.client_id,
        scope: "bot webhook.incoming",
        permissions: 536870912,
        redirect_uri:,
        response_type: "code",
        state:
      }.to_query

      "#{AUTHORIZE_URL}?#{query}"
    end

    #: (String code, redirect_uri: String) -> ActiveSupport::HashWithIndifferentAccess
    def exchange_code(code, redirect_uri:)
      response = Faraday.post(TOKEN_URL) do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form(
          client_id: DiscordConfig.client_id,
          client_secret: DiscordConfig.client_secret,
          grant_type: "authorization_code",
          code:,
          redirect_uri:
        )
      end

      unless response.success?
        raise ApiError, "Discord OAuth 토큰 교환에 실패했습니다. HTTP #{response.status}"
      end

      JSON.parse(response.body).with_indifferent_access
    rescue Faraday::Error => e
      raise ApiError, "#{e.class}: #{e.message}"
    end

    #: (String bot_token, String guild_id) -> Array[Hash]
    def list_channels(bot_token, guild_id)
      response = Faraday.get("#{API_BASE}/guilds/#{guild_id}/channels") do |req|
        req.headers["Authorization"] = "Bot #{bot_token}"
      end

      unless response.success?
        raise ApiError, "Discord 채널 목록 조회에 실패했습니다. HTTP #{response.status}"
      end

      JSON.parse(response.body).select { |c| c["type"] == 0 }
    rescue Faraday::Error => e
      raise ApiError, "#{e.class}: #{e.message}"
    end

    #: (String bot_token, String channel_id, ?name: String) -> Hash[Symbol, String]
    def create_webhook(bot_token, channel_id, name: "AlNews")
      response = Faraday.post("#{API_BASE}/channels/#{channel_id}/webhooks") do |req|
        req.headers["Authorization"] = "Bot #{bot_token}"
        req.headers["Content-Type"] = "application/json"
        req.body = { name: }.to_json
      end

      unless response.success?
        raise ApiError, "Discord 웹훅 생성에 실패했습니다. HTTP #{response.status}"
      end

      webhook = JSON.parse(response.body).with_indifferent_access
      {
        id: webhook[:id],
        token: webhook[:token],
        url: "https://discord.com/api/webhooks/#{webhook[:id]}/#{webhook[:token]}"
      }
    rescue Faraday::Error => e
      raise ApiError, "#{e.class}: #{e.message}"
    end
  end
end
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
rails test test/clients/discord_client_test.rb
```

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/models/discord_config.rb app/clients/discord_client.rb test/clients/discord_client_test.rb
git commit -m "feat: add DiscordConfig and DiscordClient with OAuth and webhook support"
```

---

## Task 7: DiscordArticlePresenter

**Files:**
- Create: `app/presenters/discord_article_presenter.rb`
- Create: `test/presenters/discord_article_presenter_test.rb`

- [ ] **Step 1: Write failing test**

```ruby
# test/presenters/discord_article_presenter_test.rb
# frozen_string_literal: true

require "test_helper"

class DiscordArticlePresenterTest < ActiveSupport::TestCase
  test "embed_params가 올바른 Discord embed 형식을 반환한다" do
    article = articles(:ruby_article)
    presenter = DiscordArticlePresenter.new(article)

    params = presenter.embed_params

    assert_equal article.title_ko, params[:title]
    assert_match %r{/articles/}, params[:url]
    assert_equal 3447003, params[:color]
    assert_equal "AlNews", params[:footer_text]
    assert_equal article.created_at, params[:timestamp]
  end

  test "description이 200자로 잘린다" do
    article = articles(:ruby_article)
    article.summary_key = "a" * 300
    presenter = DiscordArticlePresenter.new(article)

    assert_equal 200, presenter.embed_params[:description].length
  end

  test "summary_key가 배열이면 첫 번째 값을 사용한다" do
    article = articles(:site_only_article)
    article.summary_key = [ "첫 번째 요약", "두 번째 요약" ]
    presenter = DiscordArticlePresenter.new(article)

    assert_equal "첫 번째 요약", presenter.embed_params[:description]
  end

  test "title_ko가 없으면 title을 사용한다" do
    article = articles(:site_only_article)
    article.title_ko = nil
    presenter = DiscordArticlePresenter.new(article)

    assert_equal article.title, params[:title]
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

```bash
rails test test/presenters/discord_article_presenter_test.rb
```

- [ ] **Step 3: Implement DiscordArticlePresenter**

```ruby
# app/presenters/discord_article_presenter.rb
# frozen_string_literal: true
# rbs_inline: enabled

class DiscordArticlePresenter
  include Rails.application.routes.url_helpers

  #: (Article article) -> void
  def initialize(article)
    @article = article
  end

  #: () -> Hash[Symbol, untyped]
  def embed_params
    {
      title: title,
      url: article_url(@article),
      description: summary&.truncate(200),
      color: 3447003,
      image_url: nil,
      footer_text: "AlNews",
      timestamp: @article.created_at
    }
  end

  private

  attr_reader :article #: Article

  #: () -> String
  def title
    article.title_ko.presence || article.title.to_s
  end

  #: () -> String?
  def summary
    value = article.summary_key
    summary_text = value.is_a?(Array) ? value.first : value
    summary_text.presence || article.base_content[:summary]
  end
end
```

- [ ] **Step 4: Fix test (title_ko nil case)**

The last test case had a bug. Fix:

```ruby
test "title_ko가 없으면 title을 사용한다" do
  article = articles(:site_only_article)
  article.title_ko = nil
  presenter = DiscordArticlePresenter.new(article)

  assert_equal article.title, presenter.embed_params[:title]
end
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
rails test test/presenters/discord_article_presenter_test.rb
```

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add app/presenters/discord_article_presenter.rb test/presenters/discord_article_presenter_test.rb
git commit -m "feat: add DiscordArticlePresenter for Discord Embed format"
```

---

## Task 8: DiscordController + routes + channel picker view

**Files:**
- Create: `app/controllers/discord_controller.rb`
- Create: `app/views/discord/channels.html.erb`
- Modify: `config/routes.rb`
- Create: `test/controllers/discord_controller_test.rb`

- [ ] **Step 1: Write failing test**

```ruby
# test/controllers/discord_controller_test.rb
# frozen_string_literal: true

require "test_helper"
require "uri"

class DiscordControllerTest < ActionDispatch::IntegrationTest
  test "GET install redirects with alert when not configured" do
    sign_in_as(users(:john))

    DiscordConfig.stub(:configured?, false) do
      get discord_install_path
    end

    assert_redirected_to edit_user_registration_path
    assert_equal "Discord 연동이 아직 설정되지 않았습니다. 관리자에게 문의해 주세요.", flash[:alert]
  end

  test "GET install redirects to Discord authorize url" do
    sign_in_as(users(:john))

    DiscordConfig.stub(:configured?, true) do
      DiscordConfig.stub(:client_id, "dc-123") do
        get discord_install_path
      end
    end

    assert_response :redirect
    assert_includes response.location, "discord.com/api/oauth2/authorize"
    assert_includes response.location, "client_id=dc-123"
  end

  test "GET callback rejects when state is invalid" do
    sign_in_as(users(:john))

    get discord_oauth_callback_path, params: { code: "oauth-code", state: "wrong" }

    assert_redirected_to edit_user_registration_path
    assert_equal "Discord 인증 상태가 일치하지 않습니다.", flash[:alert]
  end

  test "GET callback stores guild info in session and redirects to channels" do
    sign_in_as(users(:john))

    DiscordConfig.stub(:configured?, true) { get discord_install_path }
    state = URI.decode_www_form(URI.parse(response.location).query).to_h.fetch("state")

    oauth_response = {
      "access_token" => "bot-token-123",
      "guild" => { "id" => "G_SETUP", "name" => "Setup Guild" }
    }

    DiscordClient.stub(:exchange_code, oauth_response) do
      get discord_oauth_callback_path, params: { code: "code", state: state }
    end

    assert_redirected_to discord_channels_path
  end

  test "GET channels redirects when session is empty" do
    sign_in_as(users(:john))

    get discord_channels_path

    assert_redirected_to edit_user_registration_path
    assert_equal "Discord 설정 정보가 없습니다. 다시 시도해 주세요.", flash[:alert]
  end

  test "POST setup creates DiscordChannel and redirects" do
    sign_in_as(users(:john))

    # Simulate callback storing session data
    DiscordConfig.stub(:configured?, true) { get discord_install_path }
    state = URI.decode_www_form(URI.parse(response.location).query).to_h.fetch("state")

    oauth_response = { "access_token" => "bot-token", "guild" => { "id" => "G_SETUP", "name" => "Setup Guild" } }
    DiscordClient.stub(:exchange_code, oauth_response) do
      get discord_oauth_callback_path, params: { code: "code", state: state }
    end

    webhook_result = { id: "WH123", token: "whtoken", url: "https://discord.com/api/webhooks/WH123/whtoken" }
    channels_list = [ { "id" => "C_PICK", "name" => "al-news", "type" => 0 } ]

    DiscordClient.stub(:create_webhook, webhook_result) do
      DiscordClient.stub(:list_channels, channels_list) do
        post discord_setup_path, params: { channel_id: "C_PICK" }
      end
    end

    assert_redirected_to edit_user_registration_path
    assert_equal "Discord 서버가 연결되었습니다.", flash[:notice]

    channel = DiscordChannel.find_by!(remote_id: "G_SETUP")
    assert_equal "Setup Guild", channel.name
    assert_equal "https://discord.com/api/webhooks/WH123/whtoken", channel.webhook_url
    assert_equal "C_PICK", channel.channel_id
    assert_equal "al-news", channel.channel_name
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

```bash
rails test test/controllers/discord_controller_test.rb
```

Expected: FAIL — `DiscordController` not defined

- [ ] **Step 3: Implement DiscordController**

```ruby
# app/controllers/discord_controller.rb
# frozen_string_literal: true
# rbs_inline: enabled

class DiscordController < ApplicationController
  def install
    unless DiscordConfig.configured?
      redirect_to edit_user_registration_path, alert: "Discord 연동이 아직 설정되지 않았습니다. 관리자에게 문의해 주세요."
      return
    end

    state = SecureRandom.hex(16)
    session[:discord_oauth_state] = state

    redirect_to DiscordClient.authorize_url(
      redirect_uri: discord_oauth_callback_url,
      state:
    ), allow_other_host: true
  end

  def callback
    stored_state = session.delete(:discord_oauth_state)
    incoming_state = params[:state]

    if stored_state.blank? || incoming_state.blank? || !ActiveSupport::SecurityUtils.secure_compare(stored_state, incoming_state)
      redirect_to edit_user_registration_path, alert: "Discord 인증 상태가 일치하지 않습니다."
      return
    end

    oauth = DiscordClient.exchange_code(params[:code], redirect_uri: discord_oauth_callback_url)
    guild = oauth[:guild]

    session[:discord_guild_id] = guild[:id]
    session[:discord_guild_name] = guild[:name]
    session[:discord_bot_token] = oauth[:access_token]

    redirect_to discord_channels_path
  rescue DiscordClient::ApiError => e
    redirect_to edit_user_registration_path, alert: "Discord 연결에 실패했습니다: #{e.message}"
  end

  def channels
    bot_token = session[:discord_bot_token]
    guild_id = session[:discord_guild_id]

    if bot_token.blank? || guild_id.blank?
      redirect_to edit_user_registration_path, alert: "Discord 설정 정보가 없습니다. 다시 시도해 주세요."
      return
    end

    @channels = DiscordClient.list_channels(bot_token, guild_id)
    @guild_name = session[:discord_guild_name]
  rescue DiscordClient::ApiError => e
    redirect_to edit_user_registration_path, alert: "Discord 채널 목록 조회에 실패했습니다: #{e.message}"
  end

  def setup
    bot_token = session[:discord_bot_token]
    guild_id = session[:discord_guild_id]
    guild_name = session[:discord_guild_name]
    channel_id = params[:channel_id]

    if bot_token.blank? || guild_id.blank? || channel_id.blank?
      redirect_to edit_user_registration_path, alert: "Discord 설정 정보가 없습니다. 다시 시도해 주세요."
      return
    end

    webhook = DiscordClient.create_webhook(bot_token, channel_id)

    channels_list = DiscordClient.list_channels(bot_token, guild_id)
    channel_info = channels_list.find { |c| c["id"] == channel_id }
    channel_name = channel_info&.dig("name") || "unknown"

    DiscordChannel.transaction do
      channel = DiscordChannel.find_or_initialize_by(remote_id: guild_id)
      channel.assign_attributes(
        name: guild_name,
        webhook_url: webhook[:url],
        channel_id: channel_id,
        channel_name: channel_name,
        status: :active,
        last_verified_at: Time.current
      )
      channel.save!
    end

    session.delete(:discord_guild_id)
    session.delete(:discord_guild_name)
    session.delete(:discord_bot_token)

    redirect_to edit_user_registration_path, notice: "Discord 서버가 연결되었습니다."
  rescue DiscordClient::ApiError, ActiveRecord::RecordInvalid => e
    redirect_to edit_user_registration_path, alert: "Discord 연결에 실패했습니다: #{e.message}"
  end
end
```

- [ ] **Step 4: Create channel picker view**

```erb
<%# app/views/discord/channels.html.erb %>
<%= turbo_frame_tag "discord_setup" do %>
  <div class="max-w-md mx-auto mt-8 p-6 bg-white rounded-lg shadow">
    <h1 class="text-xl font-bold mb-4"><%= @guild_name %> — 채널 선택</h1>
    <p class="text-gray-600 mb-4">AlNews 알림을 받을 채널을 선택하세요.</p>

    <%= form_with url: discord_setup_path, method: :post, class: "space-y-2" do |form| %>
      <% @channels.each do |channel| %>
        <label class="flex items-center gap-3 p-3 rounded border hover:bg-gray-50 cursor-pointer">
          <%= form.radio_button :channel_id, channel["id"], required: true %>
          <span class="font-medium">#<%= channel["name"] %></span>
        </label>
      <% end %>

      <div class="pt-4">
        <%= form.submit "연결", class: "w-full bg-indigo-600 text-white py-2 px-4 rounded hover:bg-indigo-700" %>
      </div>
    <% end %>
  </div>
<% end %>
```

- [ ] **Step 5: Add Discord routes**

In `config/routes.rb`, add before the Slack routes:

```ruby
# Discord
get  "/discord/install",        to: "discord#install",   as: :discord_install
get  "/discord/oauth/callback", to: "discord#callback",  as: :discord_oauth_callback
get  "/discord/channels",       to: "discord#channels",  as: :discord_channels
post "/discord/setup",          to: "discord#setup",     as: :discord_setup
```

- [ ] **Step 6: Run tests**

```bash
rails test test/controllers/discord_controller_test.rb
```

Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add app/controllers/discord_controller.rb app/views/discord/channels.html.erb \
  config/routes.rb test/controllers/discord_controller_test.rb
git commit -m "feat: add DiscordController with OAuth flow and channel picker"
```

---

## Task 9: DiscordArticleNotifierService + DiscordArticleDeliveryJob

**Files:**
- Create: `app/services/discord_article_notifier_service.rb`
- Create: `app/jobs/discord_article_delivery_job.rb`
- Create: `test/services/discord_article_notifier_service_test.rb`
- Create: `test/jobs/discord_article_delivery_job_test.rb`

- [ ] **Step 1: Write failing test for notifier service**

```ruby
# test/services/discord_article_notifier_service_test.rb
# frozen_string_literal: true

require "test_helper"

class DiscordArticleNotifierServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @article = articles(:ruby_article)
    DiscordDelivery.where(article: @article).delete_all
  end

  test "channel 기준으로 Discord delivery 잡을 enqueue한다" do
    discord_channels = DiscordChannel.delivery_ready
    assert_enqueued_jobs discord_channels.count, only: DiscordArticleDeliveryJob do
      DiscordArticleNotifierService.new.call(@article)
    end

    enqueued = enqueued_jobs.select { |j| j[:job] == DiscordArticleDeliveryJob }
    channel_ids = enqueued.map { |j| j[:args][1] }.sort

    assert_equal discord_channels.order(:id).pluck(:id), channel_ids
  end

  test "confirmed 되지 않은 기사는 발송하지 않는다" do
    article = articles(:site_only_article)

    assert_no_enqueued_jobs only: DiscordArticleDeliveryJob do
      DiscordArticleNotifierService.new.call(article)
    end
  end
end
```

- [ ] **Step 2: Write failing test for delivery job**

```ruby
# test/jobs/discord_article_delivery_job_test.rb
# frozen_string_literal: true

require "test_helper"

class DiscordArticleDeliveryJobTest < ActiveJob::TestCase
  test "신규 delivery의 기본 상태는 failed다" do
    delivery = DiscordDelivery.create!(
      article: articles(:ruby_article),
      notification_channel: notification_channels(:acme_discord),
      channel_id: "DCDEFAULT1",
      channel_name: "al-news"
    )

    assert_predicate delivery, :failed?
  end

  test "전송 실패 처리 중 이미 sent 상태면 failed로 되돌리지 않는다" do
    article = articles(:ruby_article)
    channel = notification_channels(:acme_discord)
    delivery = Class.new do
      attr_reader :update_called

      def initialize
        @sent = false
        @update_called = false
      end

      def with_lock
        yield
      end

      def sent?
        @sent
      end

      def reload
        @sent = true
      end

      def update!(**)
        @update_called = true
      end
    end.new

    DiscordClient.stub(:new, Struct.new(:error) {
      def post_embed(params)
        raise error
      end
    }.new(DiscordClient::ApiError.new("timeout"))) do
      job = DiscordArticleDeliveryJob.new
      job.stub(:find_or_create_delivery, delivery) do
        job.perform(article.id, channel.id)
      end
    end

    assert_predicate delivery, :sent?
    refute delivery.update_called
  end
end
```

- [ ] **Step 3: Run tests to verify they fail**

```bash
rails test test/services/discord_article_notifier_service_test.rb test/jobs/discord_article_delivery_job_test.rb
```

Expected: FAIL

- [ ] **Step 4: Implement DiscordArticleNotifierService**

```ruby
# app/services/discord_article_notifier_service.rb
# frozen_string_literal: true
# rbs_inline: enabled

class DiscordArticleNotifierService < OperationService
  #: (Article article) -> Dry::Monads::Result
  def call(article)
    return Failure(:deleted) unless article.deleted_at.nil?
    return Failure(:not_confirmed) unless article.slug.present? && article.title_ko.present?

    delivery_jobs = DiscordChannel.delivery_ready.order(:id).to_a.map do |channel|
      DiscordArticleDeliveryJob.new(article.id, channel.id)
    end

    return nil if delivery_jobs.empty?

    ActiveJob.perform_all_later(delivery_jobs)

    true
  end
end
```

- [ ] **Step 5: Implement DiscordArticleDeliveryJob**

```ruby
# app/jobs/discord_article_delivery_job.rb
# frozen_string_literal: true
# rbs_inline: enabled

class DiscordArticleDeliveryJob < ApplicationJob
  queue_as :default

  #: (Integer article_id, Integer channel_id) -> void
  def perform(article_id, channel_id)
    article = Article.find_by(id: article_id)
    channel = DiscordChannel.find_by(id: channel_id)
    return unless article && channel&.webhook_url.present? && channel.channel_id.present? && channel.channel_name.present?

    delivery = find_or_create_delivery(article, channel)
    presenter = DiscordArticlePresenter.new(article)

    delivery.with_lock do
      return if delivery.sent?

      message_id = DiscordClient.new(channel).post_embed(presenter.embed_params)

      persist_delivery_success(delivery, channel.channel_name, message_id)
    end
  rescue DiscordClient::ApiError => e
    delivery&.with_lock do
      delivery.reload
      return if delivery.sent?

      delivery.update!(channel_name: channel.channel_name, status: :failed, error_message: e.message)
    end
  end

  private

  #: (DiscordDelivery delivery, String channel_name, String? message_id) -> void
  def persist_delivery_success(delivery, channel_name, message_id)
    delivery.update!(
      channel_name:,
      status: :sent,
      sent_at: Time.current,
      error_message: nil,
      message_id:
    )
  end

  #: (Article article, DiscordChannel channel) -> DiscordDelivery
  def find_or_create_delivery(article, channel)
    existing_delivery = DiscordDelivery.find_by(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id
    )
    return existing_delivery if existing_delivery

    DiscordDelivery.create!(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id,
      channel_name: channel.channel_name,
      status: :failed
    )
  rescue ActiveRecord::RecordNotUnique
    DiscordDelivery.find_by!(
      article:,
      notification_channel: channel,
      channel_id: channel.channel_id
    )
  end
end
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
rails test test/services/discord_article_notifier_service_test.rb test/jobs/discord_article_delivery_job_test.rb
```

Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add app/services/discord_article_notifier_service.rb app/jobs/discord_article_delivery_job.rb \
  test/services/discord_article_notifier_service_test.rb test/jobs/discord_article_delivery_job_test.rb
git commit -m "feat: add DiscordArticleNotifierService and DiscordArticleDeliveryJob"
```

---

## Task 10: SocialPostJob integration

**Files:**
- Modify: `app/jobs/social_post_job.rb`

- [ ] **Step 1: Add Discord notifier to SocialPostJob**

In `app/jobs/social_post_job.rb`, add `DiscordArticleNotifierService` after `SlackArticleNotifierService`:

```ruby
# Current line 28:
SlackArticleNotifierService.new.call(article)

# Add after it:
DiscordArticleNotifierService.new.call(article)
```

- [ ] **Step 2: Run existing tests to ensure no regression**

```bash
rails test
```

Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add app/jobs/social_post_job.rb
git commit -m "feat: integrate Discord notification into SocialPostJob pipeline"
```

---

## Task 11: Drop old tables + cleanup

**Files:**
- Create: `db/migrate/TIMESTAMP_drop_slack_tables.rb`
- Delete: `app/models/slack_workspace.rb`
- Delete: `app/models/slack_article_delivery.rb`
- Delete: `test/fixtures/slack_workspaces.yml`
- Delete: `test/fixtures/slack_article_deliveries.yml`
- Delete: `test/models/article_slack_notification_test.rb`

- [ ] **Step 1: Generate migration**

```bash
rails generate migration DropSlackTables
```

- [ ] **Step 2: Write migration**

```ruby
# frozen_string_literal: true

class DropSlackTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :slack_article_deliveries
    drop_table :slack_workspaces
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

- [ ] **Step 3: Delete old model files**

```bash
rm app/models/slack_workspace.rb app/models/slack_article_delivery.rb
```

- [ ] **Step 4: Delete old fixture files**

```bash
rm test/fixtures/slack_workspaces.yml test/fixtures/slack_article_deliveries.yml
```

- [ ] **Step 5: Remove old notification test (references non-existent SlackArticleNotificationJob)**

```bash
rm test/models/article_slack_notification_test.rb
```

- [ ] **Step 6: Run migration**

```bash
rails db:migrate
```

- [ ] **Step 7: Run full test suite**

```bash
rails test
```

Expected: All tests pass

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "chore: drop old slack_workspaces and slack_article_deliveries tables"
```

---

## Task 12: Final validation + full test run

- [ ] **Step 1: Validate all changed files**

```bash
rails validate files=app/models/notification_channel.rb,app/models/notification_delivery.rb,app/models/slack_channel.rb,app/models/discord_channel.rb,app/models/slack_delivery.rb,app/models/discord_delivery.rb,app/models/discord_config.rb,app/clients/discord_client.rb,app/presenters/discord_article_presenter.rb,app/controllers/discord_controller.rb,app/services/discord_article_notifier_service.rb,app/jobs/discord_article_delivery_job.rb,app/jobs/social_post_job.rb level=rails
```

- [ ] **Step 2: Run full test suite**

```bash
rails test
```

Expected: All tests pass, 0 failures

- [ ] **Step 3: Run security scan on new files**

```bash
rails security_scan files=app/controllers/discord_controller.rb,app/clients/discord_client.rb confidence=high
```

Expected: 0 warnings

- [ ] **Step 4: Final commit (if any fixes needed)**

```bash
git add -A
git commit -m "chore: final validation and cleanup for Discord notification feature"
```
