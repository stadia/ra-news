# Code Style and Conventions

## Language & Documentation
- All responses and code comments should be in Korean
- Log outputs and command results should remain in original format
- Code follows RuboCop linting standards

## Type Annotations
- Use RBS inline annotations in models and controllers
- Enable with `# rbs_inline: enabled` comment
- Format: `def method_name(param) #: (ParamType) -> ReturnType`

## Database & Models
- Use soft delete pattern: `include Discard::Model`
- Use `.kept` scope for active records
- Add RBS type annotations for public methods
- Use vector embeddings (1536-dimension) for similarity
- Implement error handling with Honeybadger reporting

## Error Handling
- Jobs: Rescue StandardError with `rescue_with_honeybadger`
- Client classes: Use standardized error types (Forbidden, RateLimit, NotFound)
- Controllers: Use `render turbo_stream:` or explicit status codes
- Graceful degradation for external API failures

## AI Integration
- Custom tools inherit from RubyLLM::Tool
- Register tools in `tools.yml`
- Use feature flags for gradual AI feature rollout
- Process Korean content with Gemini models

## CSS & Frontend
- Use Tailwind CSS 4.2
- Define shared tokens in `app/assets/stylesheets/tokens.css`
- Use Hotwire (Turbo/Stimulus) for interactivity
- Default locale: `:ko` with Asia/Seoul timezone

## Localization
- New translation keys in `config/locales/ko.yml`
- Standardize dates/times with `l(Time.current, format: :short)`

## Deployment Considerations
- API keys stored in `config/credentials.yml.enc`
- Queue/cache/search impact should be noted in PR
- Provide rollback strategy for new features
- Coordinate with QA for authentication flow changes
