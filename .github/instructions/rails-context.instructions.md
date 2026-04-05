---
applyTo: "**/*"
---

# AlNews — Overview

Rails 8.1.3 | Ruby 4.0.2

- Database: static_parse — 17 tables
- Models: 16
- Routes: 140
- auth: devise, pundit, jwt
- jobs: solid_queue, mission_control-jobs
- frontend: turbo-rails, stimulus-rails, importmap-rails, tailwindcss-rails, propshaft, phlex-rails
- api: jbuilder, alba, oj
- database: pg, sqlite3, solid_cache, solid_cable
- files: activestorage, image_processing, mini_magick
- Hotwire (Turbo + Stimulus)
- Service objects pattern (app/services/)
- ViewComponent (app/components/)
- phlex
- Stimulus controllers (app/javascript/controllers/)
- Auth: Devise
- I18n: 2 locales (en, ko)
- Components: 111 components, 111 Phlex
- Accessibility: minimal
- Performance: 9 issues detected
- Services: ArticleAgentsService, ContentService, LikeFederationService, MastodonService, OauthClientService, OperationService, PushNotificationService, SitemapService, SocialMediaService, TwitterService, WebPushConfig
- Jobs: ArticleBatchJob, ArticleJob, GmailArticleJob, HackerNewsSiteJob, RedditSiteJob, ReplyNotificationJob, RssSiteJob, RssSitePageJob, SocialDeleteJob, SocialPostJob, YoutubeSiteJob

**Global before_actions:** authenticate_user!

Use MCP tools for detailed data. Start with `detail:"summary"`.