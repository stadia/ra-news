# Discord Notification + Unified Notification Model Design

Date: 2026-04-13

## Goal

Add Discord notification support using the same incoming webhook pattern as Slack, while migrating existing Slack models into a unified `notification_channels` / `notification_deliveries` STI architecture.

## Context

AlNews already sends articles to Twitter, Mastodon, and Slack via `SocialPostJob`. Slack uses an OAuth2 + incoming webhook flow (`SlackWorkspace` → `SlackArticleDelivery`). We want to add Discord as a fourth channel and unify the data model so future platforms require minimal new infrastructure.

## Dependencies

| Gem                  | Purpose                                      |
| -------------------- | -------------------------------------------- |
| `discordrb-webhooks` | Discord webhook message posting (Embed support) |

Notes:
- `discordrb-webhooks` is the lightweight subset of `discordrb` — no opus-ruby, websocket-client-simple, or ffi dependencies.
- OAuth2 code exchange uses existing `faraday` gem (already in project). Only 2 HTTP calls needed (token exchange + webhook creation).
- Full `discordrb` gem is NOT needed since we only post via incoming webhooks, not via Gateway/Bot events.

## Schema

### `notification_channels` (replaces `slack_workspaces`)

| Column           | Type       | Notes                                    |
| ---------------- | ---------- | ---------------------------------------- |
| id               | bigint     | PK                                       |
| type             | string     | STI: `SlackChannel` / `DiscordChannel`   |
| status           | string     | `active` / `inactive` / `error`          |
| last_verified_at | datetime   |                                          |
| remote_id        | string     | Slack `team_id` / Discord `guild_id`     |
| name             | string     | Slack `team_name` / Discord `guild_name` |
| webhook_url      | string     | Incoming webhook URL                     |
| channel_id       | string     | Target channel ID                        |
| channel_name     | string     | Target channel name                      |
| metadata         | jsonb      | Platform-specific extras, default `{}`   |
| created_at       | datetime   |                                          |
| updated_at       | datetime   |                                          |

Validations: `remote_id` uniqueness, presence of `remote_id`, `name`, `webhook_url`, `channel_id`, `channel_name`.

Scopes: `active`, `delivery_ready` (active + webhook_url present).

### `notification_deliveries` (replaces `slack_article_deliveries`)

| Column                  | Type       | Notes                                |
| ----------------------- | ---------- | ------------------------------------ |
| id                      | bigint     | PK                                   |
| type                    | string     | STI: `SlackDelivery` / `DiscordDelivery` |
| article_id              | bigint     | FK → articles                        |
| notification_channel_id | bigint     | FK → notification_channels           |
| channel_id              | string     | Channel ID at send time              |
| channel_name            | string     | Channel name at send time            |
| status                  | string     | `sent` / `failed`                    |
| sent_at                 | datetime   |                                      |
| error_message           | text       |                                      |
| message_id              | string     | Slack `ts` / Discord `message_id`    |
| metadata                | jsonb      | Platform-specific extras             |
| created_at              | datetime   |                                      |
| updated_at              | datetime   |                                      |

Validations: article presence, channel presence, channel_id/channel_name presence, status inclusion, article scoped uniqueness to channel.

## STI Classes

### NotificationChannel (base)

Common scopes: `active`, `delivery_ready`.

### SlackChannel < NotificationChannel

No extra fields. Uses `webhook_url` to post Slack Block Kit messages.

### DiscordChannel < NotificationChannel

No extra fields. Uses `webhook_url` (Discord webhook format: `https://discord.com/api/webhooks/{id}/{token}`) with `discordrb-webhooks` gem to post Discord Embed messages.

### NotificationDelivery (base)

Common status enum: `sent`, `failed`.

### SlackDelivery < NotificationDelivery

`message_id` stores Slack message `ts`.

### DiscordDelivery < NotificationDelivery

`message_id` stores Discord message ID.

## OAuth2 Flow

### Discord OAuth2 (new)

1. User clicks "Add to Discord" in settings.
2. Redirect to Discord OAuth2 authorize URL:
   - `scope=bot webhook.incoming`
   - `permissions=536870912` (MANAGE_WEBHOOKS)
3. User selects server and authorizes.
4. Callback receives `code`, exchanges for Bot access token.
5. Bot token calls `POST /channels/{channel_id}/webhooks` to create a webhook named "AlNews".
6. Response provides `webhook.id` + `webhook.token` → construct `webhook_url`.
7. Create `DiscordChannel` record with all fields.

### Slack OAuth2 (existing, adapted)

Same flow as current but creates `SlackChannel` instead of `SlackWorkspace`.

## Architecture

### New Files

| File                                            | Purpose                           |
| ----------------------------------------------- | --------------------------------- |
| `app/models/notification_channel.rb`            | STI base                          |
| `app/models/slack_channel.rb`                   | STI subclass                      |
| `app/models/discord_channel.rb`                 | STI subclass                      |
| `app/models/notification_delivery.rb`           | STI base                          |
| `app/models/slack_delivery.rb`                  | STI subclass                      |
| `app/models/discord_delivery.rb`                | STI subclass                      |
| `app/models/discord_config.rb`                  | Discord credentials (Preference)  |
| `app/clients/discord_client.rb`                 | OAuth (Faraday) + webhook posting (discordrb-webhooks) |
| `app/controllers/discord_controller.rb`         | install / callback actions        |
| `app/presenters/discord_article_presenter.rb`   | Discord Embed format              |
| `app/services/discord_article_notifier_service.rb` |Notifier (NotifierService pattern) |
| `app/jobs/discord_article_delivery_job.rb`      | Delivery job per channel          |

### Modified Files

| File                              | Change                                       |
| --------------------------------- | -------------------------------------------- |
| `app/controllers/slack_controller.rb` | Use `SlackChannel` instead of `SlackWorkspace` |
| `app/jobs/slack_article_delivery_job.rb` | Use `SlackDelivery` instead of `SlackArticleDelivery` |
| `app/services/slack_article_notifier_service.rb` | Use `SlackChannel.delivery_ready` |
| `app/jobs/social_post_job.rb`     | Add `DiscordArticleNotifierService.new.call(article)` |
| `config/routes.rb`                | Add Discord routes                           |

### Deleted Files (after migration)

| File                              | Reason                        |
| --------------------------------- | ----------------------------- |
| `app/models/slack_workspace.rb`   | Replaced by `SlackChannel`    |
| `app/models/slack_article_delivery.rb` | Replaced by `SlackDelivery`   |

## Discord Message Format

Discord Embed payload posted via `discordrb-webhooks`:

```ruby
# DiscordClient uses discordrb-webhooks internally
client = Discordrb::Webhook.new(url: webhook_url)
client.execute do |builder|
  builder.add_embed do |embed|
    embed.title = article.title
    embed.url = article_url(article)
    embed.description = article.content&.truncate(200)
    embed.colour = 3447003  # AlNews blue
    embed.image = Discordrb::Webhooks::EmbedImage.new(url: article.image_url) if article.image_url
    embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "AlNews")
    embed.timestamp = article.created_at
  end
end
```

The `DiscordArticlePresenter` converts an Article into embed parameters (hash), and `DiscordClient` applies them via `discordrb-webhooks`.

## Migration Strategy

### Phase 1: Create new tables

```ruby
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

add_index :notification_channels, [:type, :remote_id], unique: true

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

add_index :notification_deliveries, [:article_id, :notification_channel_id, :channel_id],
          unique: true, name: "idx_notification_deliveries_uniqueness"
```

### Phase 2: Data migration

```sql
INSERT INTO notification_channels (type, status, last_verified_at, remote_id, name, webhook_url, channel_id, channel_name, created_at, updated_at)
SELECT 'SlackChannel', status, last_verified_at, team_id, team_name, incoming_webhook_url, channel_id, channel_name, created_at, updated_at
FROM slack_workspaces;

INSERT INTO notification_deliveries (type, article_id, notification_channel_id, channel_id, channel_name, status, sent_at, error_message, message_id, created_at, updated_at)
SELECT 'SlackDelivery', sad.article_id, nc.id, sad.channel_id, sad.channel_name, sad.status, sad.sent_at, sad.error_message, sad.slack_message_ts, sad.created_at, sad.updated_at
FROM slack_article_deliveries sad
JOIN notification_channels nc ON nc.remote_id = (SELECT team_id FROM slack_workspaces WHERE id = sad.slack_workspace_id);
```

### Phase 3: Drop old tables

After all code references are updated, drop `slack_workspaces` and `slack_article_deliveries`.

## Routes

```ruby
# Discord (new)
get  "/discord/install",        to: "discord#install",   as: :discord_install
get  "/discord/oauth/callback", to: "discord#callback",  as: :discord_oauth_callback
get  "/discord/channels",       to: "discord#channels",  as: :discord_channels
post "/discord/setup",          to: "discord#setup",     as: :discord_setup

# Slack (existing, unchanged paths)
get  "/slack/install",          to: "slack#install",      as: :slack_install
get  "/slack/oauth/callback",   to: "slack#callback",     as: :slack_oauth_callback
post "/slack/events",           to: "slack#events",        as: :slack_events
```

## SocialPostJob Integration

```ruby
# In SocialPostJob#perform
scope.find_each do |article|
  TwitterService.new.call(article)
  MastodonService.new.call(article)
  SlackArticleNotifierService.new.call(article)
  DiscordArticleNotifierService.new.call(article)
  article.update(is_posted: true)
  sleep 2
end
```

## Error Handling

- `DiscordClient::ApiError` wraps all Discord API errors (HTTP errors, rate limits from Faraday OAuth calls and discordrb-webhooks exceptions).
- `DiscordArticleDeliveryJob` catches `DiscordClient::ApiError`, marks delivery as failed with error message.
- Channel status set to `error` on persistent failures (e.g., invalid webhook).
- `discordrb-webhooks` raises `Discordrb::Errors::Code` on API errors — caught and re-wrapped in `DiscordClient::ApiError`.
- Same pattern as existing `SlackArticleDeliveryJob`.

## Testing

- `DiscordClient` unit tests (stub Faraday responses).
- `DiscordController` tests (OAuth flow stubs).
- `DiscordArticleDeliveryJob` tests (delivery creation, idempotency, error handling).
- `DiscordArticlePresenter` tests (embed format).
- `DiscordArticleNotifierService` tests (channel selection, job scheduling).
- Migration tests to verify data integrity.
