---
applyTo: "**/*"
name: "Rails Project Overview"
description: "Rails version, database, models, routes, gems, architecture patterns"
---

# AlNews — Overview

Rails 8.1.3 | Ruby 4.0.3

- Database: PostgreSQL — 25 tables
- Models: 22
- Routes: 150
- auth: devise, pundit, jwt
- jobs: solid_queue, mission_control-jobs
- frontend: turbo-rails, stimulus-rails, importmap-rails, tailwindcss-rails, propshaft, phlex-rails
- api: jbuilder, alba, oj
- database: pg, sqlite3, solid_cache, solid_cable
- files: activestorage, image_processing, mini_magick, aws-sdk-s3
- Hotwire (Turbo + Stimulus)
- Service objects pattern (app/services/)
- Presenters/Decorators
- ViewComponent (app/components/)
- phlex
- Auth: Devise
- I18n: 2 locales (en, ko)
- Storage: ActiveStorage (1 models with attachments)
- Assets: propshaft, importmap, tailwindcss
- Databases: 3 (primary, cache, queue)
- Components: 112 components, 112 Phlex
- Performance: 12 issues detected
- Services: ArticleAgentsService, ContentService, DiscordArticleNotifierService, LikeFederationService, MastodonService, OperationService, PushNotificationService, SitemapService, SlackArticleNotifierService, SocialMediaService, TwitterService
- Jobs: ArticleBatchJob, ArticleJob, DiscordArticleDeliveryJob, GmailArticleJob, HackerNewsSiteJob, RedditSiteJob, ReplyNotificationJob, RssSiteJob, RssSitePageJob, SlackArticleDeliveryJob, SocialDeleteJob, SocialPostJob, YoutubeSiteJob

**Global before_actions:** authenticate_user!

Use MCP tools for detailed data. Start with `detail:"summary"`.