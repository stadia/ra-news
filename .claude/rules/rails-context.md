# AlNews — Overview

Rails 8.1.3 | Ruby 4.0.2

- Database: static_parse — 0 tables
- Models: 15
- Routes: 147
- auth: devise, pundit, jwt
- jobs: solid_queue, mission_control-jobs
- frontend: turbo-rails, stimulus-rails, importmap-rails, tailwindcss-rails, propshaft, phlex-rails
- api: jbuilder, alba, oj
- database: pg, sqlite3, solid_cache, solid_cable
- files: activestorage, image_processing, mini_magick
- hotwire
- service_objects
- view_components
- phlex
- stimulus
- Components: 99 components

**Global before_actions:** authenticate_user!

ALWAYS use MCP tools for context — do NOT read reference files directly.
Start with `detail:"summary"`. Read files ONLY when you will Edit them.