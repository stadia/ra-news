# ActivityPub Integration

RA-News now supports ActivityPub federation to automatically publish articles to Mastodon and other ActivityPub-compatible services.

## Features

- **Automatic Publishing**: New articles are automatically published to ActivityPub after AI processing
- **Site-based Actors**: Each Site in RA-News gets its own ActivityPub actor
- **WebFinger Support**: Enables discovery of actors by other ActivityPub services
- **Korean Localization**: ActivityPub content respects Korean language preferences

## Architecture

### Components

1. **ActivitypubActor Model**: Represents ActivityPub actors linked to Sites
2. **ActivitypubController**: Handles actor profiles and outbox endpoints
3. **WebfingerController**: Enables actor discovery via WebFinger protocol
4. **ActivitypubPublishJob**: Background job for publishing articles

### Integration Points

- Integrated with existing `ArticleJob` pipeline
- Uses Solid Queue for background processing
- Follows existing error handling patterns with Honeybadger

## Configuration

### Environment Variables

```bash
# Production
ACTIVITYPUB_DOMAIN=your-domain.com

# Development (optional, defaults to localhost:3000)
ACTIVITYPUB_DOMAIN=localhost:3000
```

### Rails Configuration

Configuration is handled in `config/initializers/activitypub.rb`:

```ruby
Rails.application.config.activitypub_enabled = true
Rails.application.config.activitypub_domain = "your-domain.com"
```

## ActivityPub Endpoints

| Endpoint | Purpose | Example |
|----------|---------|---------|
| `/.well-known/webfinger` | Actor discovery | `/.well-known/webfinger?resource=acct:username@domain.com` |
| `/activitypub/actors/:username` | Actor profile | `/activitypub/actors/ruby-news` |
| `/activitypub/actors/:username/outbox` | Published activities | `/activitypub/actors/ruby-news/outbox` |
| `/activitypub/actors/:username/inbox` | Incoming activities | `/activitypub/actors/ruby-news/inbox` |

## Usage

### Automatic Operation

ActivityPub integration works automatically:

1. When a new Article is created and processed by `ArticleJob`
2. `ActivitypubPublishJob` runs after AI summarization
3. Creates or finds an ActivityPub actor for the article's Site
4. Publishes the article as an ActivityPub "Create" activity
5. Makes the activity available in the actor's outbox

### Manual Actor Creation

```ruby
# Create actor for a site
site = Site.find_by(name: "Ruby News")
actor = ActivitypubActor.create!(
  username: "ruby-news",
  domain: "your-domain.com",
  site: site,
  display_name: "Ruby News",
  bio: "Latest Ruby programming news and updates"
)
```

### Publishing an Article

```ruby
# Manually trigger ActivityPub publishing
article = Article.find(123)
ActivitypubPublishJob.perform_later(article.id)
```

## Federation

### Current Status

- ✅ Actor profiles and outboxes are publicly accessible
- ✅ WebFinger discovery works
- ✅ Activities are properly formatted according to ActivityStreams 2.0
- ⏳ Direct federation to follower inboxes (planned)
- ⏳ HTTP Signature authentication (planned)

### Following RA-News Actors

Other ActivityPub users can follow RA-News actors by searching for:
```
@username@your-domain.com
```

For example, if you have a "Ruby News" site:
```
@ruby-news@your-domain.com
```

## Database Schema

```sql
CREATE TABLE activitypub_actors (
  id bigint PRIMARY KEY,
  username varchar NOT NULL,
  domain varchar NOT NULL,
  display_name varchar,
  bio text,
  private_key text NOT NULL,
  public_key text NOT NULL,
  site_id bigint REFERENCES sites(id),
  deleted_at timestamp,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL
);

CREATE UNIQUE INDEX index_activitypub_actors_on_username_and_domain 
ON activitypub_actors (username, domain);
```

## Security Considerations

- Private keys are automatically generated and stored securely
- Public keys are exposed via actor profiles for signature verification
- All ActivityPub endpoints use HTTPS in production
- Soft deletion support via `discard` gem

## Troubleshooting

### Actor Not Found

If WebFinger lookup fails:
1. Check that the actor exists: `ActivitypubActor.find_by(username: "username", domain: "domain")`
2. Verify domain configuration matches request host
3. Check that routes are properly configured

### Publishing Failures

Check the job queue for failed `ActivitypubPublishJob` jobs:
1. Visit `/jobs` (Mission Control)
2. Look for failed ActivityPub jobs
3. Check logs for error details

### Development Testing

Test WebFinger in development:
```bash
curl "http://localhost:3000/.well-known/webfinger?resource=acct:username@localhost:3000"
```

Test actor profile:
```bash
curl -H "Accept: application/activity+json" "http://localhost:3000/activitypub/actors/username"
```

## Future Enhancements

1. **Full Federation**: Direct delivery to follower inboxes
2. **HTTP Signatures**: Cryptographic authentication of requests
3. **Follower Management**: Track and manage followers
4. **Activity Types**: Support for Update, Delete activities
5. **Moderation Tools**: Content filtering and user blocking