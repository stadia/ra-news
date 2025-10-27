# Development Commands for Ruby-News

## Running the Application
```bash
bin/dev                         # Start Rails server + CSS watching (via Procfile.dev)
bin/rails server               # Rails server only
bin/rails tailwindcss:watch    # CSS watching only
bin/rails jobs:clear           # Initialize queue (dev only)
bin/jobs                        # Start Solid Queue worker
```

## Testing & Quality Assurance
```bash
bin/rails test                 # Run test suite
bin/rubocop                    # Lint with RuboCop
bundle exec steep check        # Type checking with Steep
bin/brakeman                   # Security analysis
bin/rails test:system BROWSER=headless_firefox  # System tests in headless mode
bin/rails jobs:stats          # Check queue status (manual check before CI)
```

## Database & Migrations
```bash
bin/rails db:migrate          # Run pending migrations
bin/rails db:rollback         # Rollback last migration
bin/rails db:seed             # Seed database
lib/tasks/embeddings.rake     # Backfill vector embeddings for new fields
```

## Git & Commits
```bash
git status                     # Check status
git diff                       # View changes
git log                        # View commit history
```

## Prerequisites Before Committing
1. **Linting**: Run `bin/rubocop` (must pass)
2. **Type Checking**: Run `bundle exec steep check` (must pass)
3. **Testing**: Run `bin/rails test` (must pass)
4. **Security**: Run `bin/brakeman` (review warnings)
5. **Documentation**: Update CHANGELOG for significant changes
6. **Database**: Note any migration impacts
7. **Background Jobs**: Verify queue/cache/search impacts documented in commit message

## Notes
- Default locale: Korean (`:ko`)
- Database timezone: Asia/Seoul
- AI features use RubyLLM with Gemini models
- All commits should document context and test results
