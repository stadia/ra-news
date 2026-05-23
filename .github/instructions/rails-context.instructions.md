---
applyTo: "**/*"
name: "Rails Project Overview"
description: "Rails version, database, models, routes, gems, architecture patterns"
---

# AlNews — Overview

Rails 8.1.3 | Ruby 4.0.5

- Database: PostgreSQL — 27 tables
- Models: 25
- Routes: 172
- auth: devise, omniauth, pundit, devise-jwt, jwt
- jobs: solid_queue, mission_control-jobs
- frontend: turbo-rails, stimulus-rails, importmap-rails, tailwindcss-rails, propshaft, phlex-rails
- api: jbuilder, alba, oj
- database: pg, sqlite3, solid_cache, solid_cable
- files: activestorage, image_processing, aws-sdk-s3
- Hotwire (Turbo + Stimulus)
- Service objects pattern (app/services/)
- Presenters/Decorators
- ViewComponent (app/components/)
- phlex
- Auth: Devise
- I18n: 3 locales (en, ja, ko)
- Storage: ActiveStorage (2 models with attachments)
- Assets: propshaft, importmap, tailwindcss
- Databases: 3 (primary, cache, queue)
- Components: 123 components, 123 Phlex
- Performance: 2 issues detected
- Services: ArticleAgentsService, ContentService, DiscordDeliveryService, LikeFederationService, MastodonService, OperationService, PushNotificationService, SlackDeliveryService, SocialMediaService, TwitterService
- Jobs: ArticleBatchJob, ArticleJob, ArticleThumbnailJob, DiscardedArticleCleanupJob, DiscordArticleDeliveryJob, GmailArticleJob, HackerNewsSiteJob, RedditSiteJob, ReplyNotificationJob, RssSiteJob, RssSitePageJob, SlackArticleDeliveryJob, SocialDeleteJob, SocialPostJob, YoutubeSiteJob

**Global before_actions:** authenticate_user!

Use MCP tools for detailed data. Start with `detail:"summary"`.