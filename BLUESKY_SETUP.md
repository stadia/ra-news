# Bluesky AT Protocol Integration Setup

This document describes how to configure the Bluesky AT Protocol integration for automatic posting of Ruby-related articles.

## Overview

RA-News now supports automatic posting to Bluesky (and other AT Protocol services) when new Ruby-related articles are processed. This integration runs alongside the existing Twitter integration.

## Environment Variables Required

Add these environment variables to your deployment configuration:

```bash
# Bluesky AT Protocol Configuration
BLUESKY_HANDLE=your-handle.bsky.social
BLUESKY_APP_PASSWORD=your-app-password
```

### How to obtain these values:

1. **BLUESKY_HANDLE**: Your Bluesky handle (e.g., `johndoe.bsky.social`)

2. **BLUESKY_APP_PASSWORD**: Generate an app-specific password in your Bluesky settings:
   - Go to Settings → App Passwords
   - Create a new app password with a descriptive name (e.g., "RA-News Bot")
   - Copy the generated password (you won't be able to see it again)

## Features

- **Automatic Posting**: New Ruby-related articles are automatically posted to Bluesky after AI processing
- **Korean Language Support**: Properly handles Korean content with language tags (`ko`, `en`)
- **Character Optimization**: 300-character limit (vs Twitter's 280) with smart truncation
- **Error Handling**: Comprehensive error handling with Honeybadger integration
- **Rate Limiting**: Respects AT Protocol rate limits

## Post Format

Posts follow this format:
```
{Korean Title or English Title}
{Summary Key Point}
{Article URL}
```

## Implementation Details

- **Client**: `BlueskyClient` extends `ApplicationClient` for consistent error handling
- **Job**: `BlueskyPostJob` runs in background queue after article processing
- **Trigger**: Automatically triggered after `ArticleJob` completes successfully
- **Dependencies**: Uses `atproto` gem for AT Protocol communication

## Testing

To test the integration:

1. Set environment variables in your development environment
2. Create a test article that matches posting criteria (`is_related: true`, has `title_ko`, has `slug`)
3. Monitor logs for `BlueskyPostJob` execution
4. Check your Bluesky account for the posted content

## Troubleshooting

### Common Issues:

1. **Authentication Failed (401)**: Check that `BLUESKY_APP_PASSWORD` is correct and not expired
2. **Handle Not Found (404)**: Verify `BLUESKY_HANDLE` format and account exists
3. **Rate Limited (429)**: AT Protocol rate limiting in effect, job will retry
4. **Missing Environment Variables**: Job will log error and skip posting

### Logs to Check:

```bash
# Development
tail -f log/development.log | grep BlueskyPostJob

# Production (via Kamal)
kamal app logs --grep "BlueskyPostJob"
```

## Admin Configuration

The integration uses environment variables (like Twitter integration) rather than database configuration for security and deployment simplicity. Admin users can monitor posting activity through:

- **Mission Control Jobs**: `/jobs` - Monitor background job processing
- **Application Logs**: Check for `BlueskyPostJob` entries
- **Honeybadger**: Error notifications for failed posts

## Future Extensions

The AT Protocol integration is designed to support other AT Protocol services beyond Bluesky:

- Additional AT Protocol servers (custom PDS instances)
- Extended post formats (threads, media uploads)
- User-facing posting controls
- Cross-posting coordination

---

For technical details, see:
- `app/clients/bluesky_client.rb` - AT Protocol client implementation
- `app/jobs/bluesky_post_job.rb` - Background posting job
- `app/jobs/article_job.rb` - Integration trigger point