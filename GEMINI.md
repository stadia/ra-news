## AI Development Team Configuration
*Configured by team-configurator on 2025-07-30*

Your project uses: **Rails 8**, **Ruby 3.4**, **PostgreSQL with vector embeddings**, **Hotwire (Turbo/Stimulus)**, **Tailwind CSS 4.2**

### Specialist Assignments

#### Backend Development
- **Rails Core Logic** → @.claude/agents/rails-architect.md
  - Job processing pipeline (ArticleJob, RssSiteJob, YoutubeSiteJob, GmailArticleJob)
  - AI content processing with RubyLLM and Gemini models
  - Custom authentication system, soft delete patterns
  - Korean localization and timezone handling

- **API Development** → @.claude/agents/rails-controller-specialist.md
  - RESTful endpoints for content aggregation
  - API versioning and rate limiting
  - JSON serialization for Korean content
  - Authentication patterns for API access

- **Database Optimization** → @.claude/agents/models-specialist.md
  - PostgreSQL vector embeddings for article similarity
  - Full-text search optimization (Korean/English dictionaries)
  - Complex queries for content recommendations
  - Performance tuning for background job processing

#### Frontend Development
- **UI Components** → @.claude/agents/stimulus-turbo-specialist.md
  - Hotwire (Turbo/Stimulus) patterns
  - Real-time updates for news feeds
  - Korean UI/UX considerations
  - Responsive design for mobile news consumption

- **Styling & Layout** → @.claude/agents/rails-views-specialist.md/
  - Tailwind CSS 4.2 configuration
  - Korean typography and layout patterns
  - Dark mode and accessibility features

#### Architecture & Quality
- **System Design** → @.claude/agents/rails-architect.md
  - Solid Queue, Solid Cache, Solid Cable architecture
  - External service integrations (YouTube, Gmail, HackerNews)
  - Scalable news aggregation patterns
  - Webhook and real-time processing design

- **Code Quality**
  - RuboCop and Steep type checking integration
  - Security analysis with Brakeman
  - Korean content handling validation
  - Background job error handling patterns

- **Performance**
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

Your specialized Rails AI team is ready to help with Ruby-News development!

## System Instructions
- **Language**: Always answer in **Korean** (한국어) for all interactions, including tool outputs and user notifications.
