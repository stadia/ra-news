---
applyTo: "**/*"
name: "Rails Project Overview"
description: "Rails version, database, models, routes, gems, architecture patterns"
---

# AlNews — Overview

Rails 8.1.3 | Ruby 4.0.4

- Database: PostgreSQL — 26 tables
- Models: 24
- Routes: 160
- auth: devise, pundit, devise-jwt, jwt
- jobs: solid_queue, mission_control-jobs
- frontend: turbo-rails, stimulus-rails, importmap-rails, tailwindcss-rails, propshaft, phlex-rails
- api: jbuilder, alba, oj
- database: pg, sqlite3, solid_cache, solid_cable
- files: activestorage, image_processing, mini_magick, aws-sdk-s3
- Hotwire (Turbo + Stimulus)
- Service objects pattern (app/services/)
- Query objects (app/queries/)
- Presenters/Decorators
- ViewComponent (app/components/)
- Auth: Devise
- I18n: 2 locales (en, ko)
- Storage: ActiveStorage (2 models with attachments)
- Assets: propshaft, importmap, tailwindcss
- Databases: 3 (primary, cache, queue)
- Components: 120 components, 120 Phlex
- Performance: 11 issues detected
- Services: ArticleAgentsService, ContentService, DiscordDeliveryService, LikeFederationService, MastodonService, OperationService, PushNotificationService, SlackDeliveryService, SocialMediaService, TwitterService
- Jobs: ArticleBatchJob, ArticleJob, ArticleThumbnailJob, DiscardedArticleCleanupJob, DiscordArticleDeliveryJob, GmailArticleJob, HackerNewsSiteJob, RedditSiteJob, ReplyNotificationJob, RssSiteJob, RssSitePageJob, SlackArticleDeliveryJob, SocialDeleteJob, SocialPostJob, YoutubeSiteJob

**Global before_actions:** authenticate_user!

Use MCP tools for detailed data. Start with `detail:"summary"`.