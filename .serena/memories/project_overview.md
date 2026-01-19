# Ruby-News Project Overview

## Project Purpose
Ruby-News is a Korean Ruby-focused news aggregation platform that aggregates content from multiple sources (RSS, YouTube, HackerNews, Gmail) and provides AI-powered summarization and recommendation features.

## Tech Stack
- **Framework**: Rails 8 with Solid Queue, Solid Cache, Solid Cable
- **Language**: Ruby 4.0 with RBS inline type annotations
- **Database**: PostgreSQL with vector embeddings (pgvector), Korean/English full-text search
- **AI Integration**: RubyLLM with Gemini models for Korean content processing
- **Frontend**: Hotwire (Turbo/Stimulus), Tailwind CSS 4.2
- **Type Checking**: Steep for RBS validation
- **Testing**: Rails default test suite
- **Job Queue**: Solid Queue for background jobs
- **Monitoring**: Honeybadger for error reporting

## Key Domain Models
- **Article**: Central content model with AI summaries, embeddings, soft-delete
- **Site**: RSS/external feed sources with kind enum
- **User**: Custom authentication system (not Devise)
- **Comment**: Nested comment system using awesome_nested_set

## Database Features
- Vector embeddings (1536-dimension) for article similarity
- Full-text search with Korean dictionary support
- Soft delete pattern using discard gem
- Index on articles.created_at for performance

## Codebase Structure
- `app/models/`: Domain models
- `app/jobs/`: Background job classes (ArticleJob, RssSiteJob, etc.)
- `app/controllers/`: Request handlers with custom auth
- `app/lib/`: Custom utilities and AI tools
- `lib/tasks/`: Rake tasks including embeddings backfill
- `config/locales/ko.yml`: Korean translations
- `app/assets/stylesheets/tokens.css`: Shared CSS tokens

## Important Conventions
- All responses and commits should be in Korean (logs/commands in original)
- Use `Current.user` for authentication context
- Soft delete with `.kept` scope
- AI tools registered in `tools.yml`
- Error handling via Honeybadger in jobs
- New features should include queue/cache/search impact in PR checklist
