# Copilot Instructions for RA-News

You are an expert in Ruby on Rails 8, PostgreSQL, AI/LLM integration, and modern Rails toolchain including Solid Queue, Solid Cache, and Solid Cable.

## Project Architecture

**RA-News** is a Ruby-focused news aggregation platform with AI-powered content processing. Key architectural patterns:

### Tech Stack & Rails 8 Features
- **Rails 8** with Solid Queue (background jobs), Solid Cache, Solid Cable
- **Ruby 3.4** with RBS inline type annotations (`# rbs_inline: enabled`)
- **PostgreSQL** with pg_search (Korean/English), neighbor gem for vector similarity
- **AI Integration**: RubyLLM gem with Gemini models for content summarization
- **Frontend**: Hotwire (Turbo/Stimulus), Tailwind CSS 4.2, Flowbite components

### Core Domain Models
- `Article`: Main content with AI-generated summaries, embeddings for similarity search
- `Site`: RSS feed sources, external integrations (HackerNews, YouTube)
- `User`: Authentication with bcrypt, article creation permissions
- `Comment`: Nested discussions on articles

## Development Workflows

### Running the Application
```bash
bin/dev  # Starts Rails server + CSS watching via Procfile.dev
```

### Job Processing Architecture
- **Solid Queue** handles background jobs in production (`SOLID_QUEUE_IN_PUMA=true`)
- **ArticleJob**: Core AI processing pipeline for content summarization
- **Custom Tools**: `ArticleBodyTool`, `YoutubeContentTool`, `HtmlContentTool` for LLM interactions

### AI Content Processing Pipeline
```ruby
# ArticleJob pattern for AI content analysis
chat = RubyLLM.chat(model: "gemini-2.5-flash-preview-05-20", provider: :gemini)
chat.with_instructions("Korean expert content analyzer...")
chat.with_tool(ArticleBodyTool.new)
```

## Project-Specific Patterns

### Client Architecture Pattern
- `ApplicationClient` base class with error handling for external APIs
- Specialized clients: `RssClient`, `GmailClient`, `HackerNewsClient`
- Standardized error types: `Forbidden`, `RateLimit`, `NotFound`, etc.

### Search & Content Discovery
```ruby
# Full-text search with Korean/English support
Article.full_text_search_for(term)
Article.title_matching(query)  # Korean dictionary
Article.body_matching(query)   # English dictionary

# Vector similarity for related articles
@article.nearest_neighbors(:embedding, @article.embedding, distance: "cosine")
```

### Soft Delete Pattern
```ruby
# Using discard gem consistently
include Discard::Model
scope :kept  # Active records only
Article.kept.find_by_slug(params[:id])
```

### Authentication & Authorization
- Custom authentication system (not Devise)
- `allow_unauthenticated_access` in controllers
- `Current.user` pattern for user context

### Korean Localization
- Default locale: `:ko` (Asia/Seoul timezone)
- AI summaries generated in Korean with structured JSON output
- Database configured for Korean text search

## Key Integration Points

### AI/LLM Integration
- **RubyLLM**: Configured in `config/initializers/ruby_llm.rb`
- **Content Tools**: Inherit from `RubyLLM::Tool` for structured AI interactions
- **Embedding Search**: Uses neighbor gem for vector similarity

### External Service Clients
- **RSS Feeds**: Automated ingestion via `RssClient`
- **YouTube**: Video transcript extraction via `yt` gem
- **Error Monitoring**: Honeybadger integration in `ApplicationJob`

### Database Features
- **Vector Search**: `has_neighbors :embedding` for content similarity
- **Full-text Search**: pg_search with Korean/English dictionaries
- **Tagging**: acts-as-taggable-on for article categorization

## Development Standards

### Type Safety
- Use RBS inline annotations: `#: (String) -> void`
- Enable with `# rbs_inline: enabled` at file top

### Error Handling
- Rescue StandardError in ApplicationJob with Honeybadger reporting
- Use Rails 8 authentication patterns (`allow_unauthenticated_access`)

### Performance
- Eager load associations: `includes(:user, :site)`
- Use Pagy for pagination: `@pagy, @articles = pagy(scope)`
- Leverage Solid Cache for production caching

### Code Organization
- Jobs in `app/jobs/` for background processing
- Clients in `app/clients/` for external API integration
- Tools in `app/jobs/` for LLM interaction patterns
