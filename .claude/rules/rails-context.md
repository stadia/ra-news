# AlNews — Overview

Rails 8.1.3 | Ruby 4.0.4

- Database: static_parse — 24 tables
- Models: 22
- Routes: 160
- Auth: Devise
- I18n: 2 locales (en, ko)
- Storage: ActiveStorage (2 models with attachments)
- Assets: propshaft, importmap, tailwindcss
- Databases: 3 (primary, cache, queue)
- Components: 120 components, 120 Phlex
- Performance: 11 issues detected

**Global before_actions:** authenticate_user!

ALWAYS use MCP tools for context — do NOT read reference files directly.
Start with `detail:"summary"`. Read files ONLY when you will Edit them.