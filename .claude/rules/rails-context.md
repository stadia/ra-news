# RubyNews - Overview

Rails 8.1.3.1 | Ruby 4.0.6

- Database: PostgreSQL - 31 tables
- Models: 21
- Routes: 186
- Auth: Devise
- I18n: 3 locales (en, ja, ko)
- Storage: ActiveStorage (2 models with attachments)
- Assets: propshaft, importmap, tailwindcss
- Databases: 3 (primary, cache, queue)
- Components: 140 components, 140 Phlex
- Performance: 5 issues detected

**Global before_actions:** authenticate_user!, set_web_site_schema

ALWAYS use MCP tools for context - do NOT read reference files directly.
Start with `detail:"summary"`. Read files ONLY when you will Edit them.