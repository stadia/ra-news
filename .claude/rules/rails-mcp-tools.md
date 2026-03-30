## Tools (33) — MANDATORY, Use Before Read

This project has 33 MCP tools via `rails ai:serve` (configured in `.mcp.json`).
**MANDATORY — use these instead of reading files.** They return structured data and save tokens.
Read files ONLY when you are about to Edit them.
If MCP tools are not connected, use CLI fallback: `rails 'ai:tool[TOOL_NAME]' param=value`

### What Are You Trying to Do?

**Understand a feature or area:**
→ MCP: `rails_analyze_feature(feature:"cook")`
→ CLI: `rails 'ai:tool[analyze_feature]' feature=cook`
→ MCP: `rails_get_context(model:"Cook")`
→ CLI: `rails 'ai:tool[context]' model=Cook`
→ MCP: `rails_get_frontend_stack`
→ CLI: `rails 'ai:tool[frontend_stack]'`

**Understand a method (who calls it, what it calls):**
→ MCP: `rails_search_code(pattern:"can_cook?", match_type:"trace")`
→ CLI: `rails 'ai:tool[search_code]' pattern="can_cook?" match_type=trace`

**Add a field or modify a model:**
→ MCP: `rails_get_schema(table:"cooks")`
→ CLI: `rails 'ai:tool[schema]' table=cooks`
→ MCP: `rails_get_model_details(model:"Cook")`
→ CLI: `rails 'ai:tool[model_details]' model=Cook`
→ MCP: `rails_migration_advisor(action:"add_column", table:"cooks", column:"rating", type:"integer")`
→ CLI: `rails 'ai:tool[migration_advisor]' action=add_column table=cooks column=rating type=integer`

**Fix a controller bug:**
→ MCP: `rails_get_controllers(controller:"CooksController", action:"create")`
→ CLI: `rails 'ai:tool[controllers]' controller=CooksController action=create`

**Build or modify a view:**
→ MCP: `rails_get_design_system(detail:"standard")`
→ CLI: `rails 'ai:tool[design_system]' detail=standard`
→ MCP: `rails_get_view(controller:"cooks")`
→ CLI: `rails 'ai:tool[view]' controller=cooks`
→ MCP: `rails_get_partial_interface(partial:"shared/status_badge")`
→ CLI: `rails 'ai:tool[partial_interface]' partial=shared/status_badge`
→ MCP: `rails_get_component_catalog(component:"Alert")`
→ CLI: `rails 'ai:tool[component_catalog]' component=Alert`

**Write tests:**
→ MCP: `rails_get_test_info(detail:"standard")`
→ CLI: `rails 'ai:tool[test_info]' detail=standard`
→ MCP: `rails_get_test_info(model:"Cook")`
→ CLI: `rails 'ai:tool[test_info]' model=Cook`

**Find code:**
→ MCP: `rails_search_code(pattern:"has_many")`
→ CLI: `rails 'ai:tool[search_code]' pattern="has_many"`
→ MCP: `rails_search_code(pattern:"create", match_type:"definition")`
→ CLI: `rails 'ai:tool[search_code]' pattern=create match_type=definition`

**Check performance:**
→ MCP: `rails_performance_check(model:"Cook")`
→ CLI: `rails 'ai:tool[performance_check]' model=Cook`

**Understand dependencies:**
→ MCP: `rails_dependency_graph(model:"Cook", format:"mermaid")`
→ CLI: `rails 'ai:tool[dependency_graph]' model=Cook format=mermaid`

**Query the database:**
→ MCP: `rails_query(sql:"SELECT COUNT(*) FROM users WHERE created_at > '2024-01-01'")`
→ CLI: `rails 'ai:tool[query]' sql="SELECT COUNT(*) FROM users WHERE created_at > '2024-01-01'"`

**Debug errors:**
→ MCP: `rails_read_logs(level:"error", lines:100)`
→ CLI: `rails 'ai:tool[read_logs]' level=error lines=100`

**Search docs:**
→ MCP: `rails_search_docs(query:"active_record_queries")`
→ CLI: `rails 'ai:tool[search_docs]' query=active_record_queries`

**After editing (EVERY time):**
→ MCP: `rails_validate(files:["app/models/cook.rb"], level:"rails")`
→ CLI: `rails 'ai:tool[validate]' files=app/models/cook.rb level=rails`

### Rules

1. NEVER read db/schema.rb, config/routes.rb, model files, or test files for reference — use the MCP tools above
2. NEVER use Grep or search agents for code search — use `rails_search_code`
3. NEVER run `ruby -c`, `erb`, or `node -c` — use `rails_validate`
4. Read files ONLY when you are about to Edit them
5. Start with `detail:"summary"` to orient, then drill into specifics
6. If MCP tools are not connected, use CLI: `rails 'ai:tool[TOOL_NAME]' param=value`

### All 33 Tools

| MCP | CLI | What it does |
|-----|-----|-------------|
| `rails_analyze_feature(feature:"X")` | `rails 'ai:tool[analyze_feature]' feature=X` | Full-stack: models + controllers + routes + services + jobs + views + tests |
| `rails_get_context(model:"X")` | `rails 'ai:tool[context]' model=X` | Composite: schema + model + controller + routes + views in one call |
| `rails_search_code(pattern:"X", match_type:"trace")` | `rails 'ai:tool[search_code]' pattern=X match_type=trace` | Trace: definition + source + siblings + callers + test coverage |
| `rails_get_controllers(controller:"X", action:"Y")` | `rails 'ai:tool[controllers]' controller=X action=Y` | Action source + inherited filters + render map + private methods |
| `rails_validate(files:[...], level:"rails")` | `rails 'ai:tool[validate]' files=a.rb,b.rb level=rails` | Syntax + semantic validation + Brakeman security |
| `rails_get_schema(table:"X")` | `rails 'ai:tool[schema]' table=X` | Columns with [indexed]/[unique]/[encrypted]/[default] hints |
| `rails_get_model_details(model:"X")` | `rails 'ai:tool[model_details]' model=X` | Associations, validations, scopes, enums, macros, delegations |
| `rails_get_routes(controller:"X")` | `rails 'ai:tool[routes]' controller=X` | Routes with code-ready helpers and controller filters inline |
| `rails_get_view(controller:"X")` | `rails 'ai:tool[view]' controller=X` | Templates with ivars, Turbo wiring, Stimulus refs, partial locals |
| `rails_get_design_system` | `rails 'ai:tool[design_system]'` | Canonical HTML/ERB copy-paste patterns for buttons, inputs, cards |
| `rails_get_stimulus(controller:"X")` | `rails 'ai:tool[stimulus]' controller=X` | Targets, values, actions + HTML data-attributes + view lookup |
| `rails_get_test_info(model:"X")` | `rails 'ai:tool[test_info]' model=X` | Tests + fixture contents + test template |
| `rails_get_concern(name:"X", detail:"full")` | `rails 'ai:tool[concern]' name=X detail=full` | Concern methods with source + which models include it |
| `rails_get_callbacks(model:"X")` | `rails 'ai:tool[callbacks]' model=X` | Callbacks in Rails execution order with source |
| `rails_get_edit_context(file:"X", near:"Y")` | `rails 'ai:tool[edit_context]' file=X near=Y` | Code around a match with class/method context |
| `rails_search_code(pattern:"X")` | `rails 'ai:tool[search_code]' pattern=X` | Regex search + `exclude_tests` + `group_by_file` + pagination |
| `rails_get_service_pattern` | `rails 'ai:tool[service_pattern]'` | Service objects: interface, dependencies, side effects, callers |
| `rails_get_job_pattern` | `rails 'ai:tool[job_pattern]'` | Jobs: queue, retries, guard clauses, broadcasts, schedules |
| `rails_get_env` | `rails 'ai:tool[env]'` | Environment variables + credentials keys (not values) |
| `rails_get_partial_interface(partial:"X")` | `rails 'ai:tool[partial_interface]' partial=X` | Partial locals contract: what to pass + usage examples |
| `rails_get_turbo_map` | `rails 'ai:tool[turbo_map]'` | Turbo Stream/Frame wiring + mismatch warnings |
| `rails_get_helper_methods` | `rails 'ai:tool[helper_methods]'` | App + framework helpers with view cross-references |
| `rails_get_config` | `rails 'ai:tool[config]'` | Database adapter, auth, assets, cache, queue, Action Cable |
| `rails_get_gems` | `rails 'ai:tool[gems]'` | Notable gems with versions, categories, config file locations |
| `rails_get_conventions` | `rails 'ai:tool[conventions]'` | App patterns: auth checks, flash messages, test patterns |
| `rails_security_scan` | `rails 'ai:tool[security_scan]'` | Brakeman static analysis: SQL injection, XSS, mass assignment |
| `rails_get_component_catalog(component:"X")` | `rails 'ai:tool[component_catalog]' component=X` | ViewComponent/Phlex: props, slots, previews, usage |
| `rails_performance_check(model:"X")` | `rails 'ai:tool[performance_check]' model=X` | N+1 risks, missing indexes, Model.all anti-patterns |
| `rails_dependency_graph(model:"X")` | `rails 'ai:tool[dependency_graph]' model=X` | Model association graph as Mermaid diagram |
| `rails_migration_advisor(action:"X", table:"Y")` | `rails 'ai:tool[migration_advisor]' action=X table=Y` | Generate migration code, flag irreversible ops |
| `rails_get_frontend_stack` | `rails 'ai:tool[frontend_stack]'` | React/Vue/Svelte/Angular, Inertia, TypeScript, package manager |
| `rails_search_docs(query:"X")` | `rails 'ai:tool[search_docs]' query=X` | Bundled topic index with weighted keyword search, on-demand GitHub fetch |
| `rails_query(sql:"X")` | `rails 'ai:tool[query]' sql=X` | Safe read-only SQL queries with timeout, row limit, column redaction |
| `rails_read_logs(level:"X")` | `rails 'ai:tool[read_logs]' level=X` | Reverse file tail with level filtering and sensitive data redaction |