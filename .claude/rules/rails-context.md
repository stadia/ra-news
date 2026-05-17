# AlNews — Overview

Rails 8.1.3 | Ruby 4.0.4

- Database: static_parse — 24 tables
- Models: 22
- Routes: 164
- Auth: Devise
- I18n: 3 locales (en, ja, ko)
- Storage: ActiveStorage (2 models with attachments)
- Assets: propshaft, importmap, tailwindcss
- Databases: 3 (primary, cache, queue)
- Components: 121 components, 121 Phlex
- Performance: 8 issues detected

**Global before_actions:** authenticate_user!

ALWAYS use MCP tools for context — do NOT read reference files directly.
Start with `detail:"summary"`. Read files ONLY when you will Edit them.