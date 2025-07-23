# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Technology Stack

**RA-News** is a Korean Ruby-focused news aggregation platform built with Rails 8. Key technologies:

- **Rails 8** with Solid Queue, Solid Cache, Solid Cable
- **Ruby 3.4** with RBS inline type annotations
- **PostgreSQL** with vector embeddings, Korean/English full-text search
- **AI Integration**: RubyLLM with Gemini models for content processing
- **Frontend**: Hotwire (Turbo/Stimulus), Tailwind CSS 4.2, Flowbite

## Development Commands

### Running the Application
```bash
bin/dev                    # Start Rails server + CSS watching (via Procfile.dev)
bin/rails server          # Rails server only
bin/rails tailwindcss:watch  # CSS watching only
```

### Testing & Quality
```bash
bin/rails test            # Run test suite
bin/rubocop               # Lint with RuboCop
bundle exec steep check   # Type checking with Steep
bin/brakeman              # Security analysis
```

### Database Operations
```bash
bin/rails db:create db:migrate db:seed
bin/rails db:test:prepare
```

### Background Jobs
```bash
bin/jobs                  # Start Solid Queue worker
bin/rails jobs:work       # Alternative job processing
```

## Core Architecture

### Domain Models
- **Article**: Central content model with AI-generated summaries, embeddings for similarity
- **Site**: RSS/external feed sources (YouTube, HackerNews, Gmail)
- **User**: Authentication with custom system (not Devise)
- **Comment**: Nested comment system using awesome_nested_set

### Job Processing Pipeline
Background jobs handle all AI content processing via Solid Queue:

```ruby
# Core AI processing pattern
ArticleJob.perform_later(article.id)
# Uses RubyLLM with Gemini for Korean content analysis
```

Key jobs:
- `ArticleJob`: Main AI summarization pipeline
- `RssSiteJob`: RSS feed processing
- `YoutubeSiteJob`: YouTube video content extraction
- `GmailArticleJob`: Email newsletter processing

### Client Architecture
External service integrations follow consistent pattern:

```ruby
# All clients inherit from ApplicationClient
class RssClient < ApplicationClient
  # Standardized error handling: Forbidden, RateLimit, NotFound
end
```

### Search System
Multi-layered search with Korean/English support:

```ruby
# Full-text search
Article.full_text_search_for(term)

# Language-specific search
Article.title_matching(query)  # Korean dictionary
Article.body_matching(query)   # English dictionary

# Vector similarity for related articles
article.nearest_neighbors(:embedding, distance: "cosine")
```

### Authentication Pattern
Custom authentication system (not Devise):
- Uses `Current.user` for context
- `allow_unauthenticated_access` in controllers
- Session-based with bcrypt

## Code Conventions

### Type Annotations
Enable RBS inline in models/controllers:
```ruby
# rbs_inline: enabled

def process_content(url) #: (String) -> void
```

### Soft Delete Pattern
Using discard gem consistently:
```ruby
include Discard::Model
scope :kept  # Use for active records
Article.kept.find_by_slug(params[:id])
```

### AI Tool Integration
Custom tools for LLM interactions:
```ruby
class ArticleBodyTool < RubyLLM::Tool
  # Structured AI content extraction
end
```

### Error Handling
- Rescue StandardError in ApplicationJob with Honeybadger reporting
- Client classes use standardized error types
- Graceful degradation for external API failures

## Korean Localization
- Default locale: `:ko` with Asia/Seoul timezone
- AI summaries generated in Korean
- PostgreSQL configured for Korean text search
- Database uses Korean dictionary for full-text search

## Key Features
- **Content Aggregation**: RSS, YouTube, Gmail, HackerNews
- **AI Summarization**: Korean-language content processing with Gemini
- **Vector Search**: Article similarity and recommendations
- **Nested Comments**: Full comment system with threading
- **Admin Dashboard**: Madmin integration for content management
- **SEO**: Automated sitemap generation and meta tags