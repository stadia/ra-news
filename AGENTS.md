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

---

## AI Development Team Configuration
*Configured by team-configurator on 2025-07-30*

Your project uses: **Rails 8**, **Ruby 3.4**, **PostgreSQL with vector embeddings**, **Hotwire (Turbo/Stimulus)**, **Tailwind CSS 4.2**

### Specialist Assignments

#### Backend Development
- **Rails Core Logic** → @rails-backend-expert
  - Job processing pipeline (ArticleJob, RssSiteJob, YoutubeSiteJob, GmailArticleJob)
  - AI content processing with RubyLLM and Gemini models
  - Custom authentication system, soft delete patterns
  - Korean localization and timezone handling

- **API Development** → @rails-api-developer
  - RESTful endpoints for content aggregation
  - API versioning and rate limiting
  - JSON serialization for Korean content
  - Authentication patterns for API access

- **Database Optimization** → @rails-activerecord-expert
  - PostgreSQL vector embeddings for article similarity
  - Full-text search optimization (Korean/English dictionaries)
  - Complex queries for content recommendations
  - Performance tuning for background job processing

#### Frontend Development
- **UI Components** → @frontend-developer
  - Hotwire (Turbo/Stimulus) patterns
  - Real-time updates for news feeds
  - Korean UI/UX considerations
  - Responsive design for mobile news consumption

- **Styling & Layout** → @tailwind-frontend-expert
  - Tailwind CSS 4.2 configuration
  - Korean typography and layout patterns
  - Flowbite component integration
  - Dark mode and accessibility features

#### Architecture & Quality
- **System Design** → @api-architect
  - Solid Queue, Solid Cache, Solid Cable architecture
  - External service integrations (YouTube, Gmail, HackerNews)
  - Scalable news aggregation patterns
  - Webhook and real-time processing design

- **Code Quality** → @code-reviewer
  - RuboCop and Steep type checking integration
  - Security analysis with Brakeman
  - Korean content handling validation
  - Background job error handling patterns

- **Performance** → @performance-optimizer
  - AI processing pipeline optimization
  - Database query performance for large news datasets
  - Caching strategies for Korean content
  - Vector search performance tuning

### How to Use Your Specialized Team

**For Content Processing:**
- "Optimize the article summarization pipeline"
- "Add support for new RSS feed sources"
- "Improve Korean text analysis accuracy"

**For Search & Discovery:**
- "Enhance vector similarity search for articles"
- "Add multilingual search capabilities"
- "Optimize recommendation algorithms"

**For UI/UX:**
- "Create responsive news card components"
- "Add real-time comment threading"
- "Improve Korean text rendering"

**For Performance:**
- "Optimize background job processing"
- "Improve database query performance"
- "Scale the vector embedding system"

**For API Development:**
- "Build admin dashboard APIs"
- "Add webhook endpoints for external sources"
- "Create mobile app API endpoints"

Your specialized Rails AI team is ready to help with RA-News development!