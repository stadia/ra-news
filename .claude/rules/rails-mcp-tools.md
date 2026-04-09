## Tools (38) — MANDATORY, Use Before Read

This project has 38 MCP tools via `rails ai:serve`.
**MANDATORY — use these instead of reading files.** They return ground truth from the running app:
real schema, real associations, real filters — not guesses from file reads.
Read files ONLY when you are about to Edit them.
If MCP tools are not connected, use CLI fallback: `rails 'ai:tool[TOOL_NAME]' param=value`

### Anti-Hallucination Protocol — Verify Before You Write

AI assistants produce confident-wrong code when statistical priors from training
data override observed facts in the current project. These 6 rules force
verification at the exact moments hallucination is most likely.

1. **Verify before you write.** Never reference a column, association, route, helper, method, class, partial, or gem you have NOT verified in THIS project via a tool call in THIS turn. If it's not verified here, verify it now. Never invent names that "sound right."
2. **Mark every assumption.** If you must proceed without verification, prefix the relevant output with `[ASSUMPTION]` and state what you're assuming and why. Silent assumptions are forbidden. "I'd need to check X first" is a valid and preferred answer.
3. **Training data describes average Rails. This app isn't average.** When something feels "obviously" like standard Rails, query anyway. Factories vs fixtures? Pundit vs CanCan? Devise vs has_secure_password? Check `rails_get_conventions` and `rails_get_gems` BEFORE scaffolding anything.
4. **Check the inheritance chain before every edit.** Before writing a controller action: inherited `before_action` filters and ancestor classes. Before writing a model method: concerns, includes, STI parents. Inheritance is never flat.
5. **Empty tool output is information, not permission.** "0 callers found," "no validations," or a missing model is a signal to investigate or confirm with the user — not a license to proceed on guesses. Follow `_Next:` hints.
6. **Stale context lies. Re-query after writes.** After any edit, tool output from earlier in this turn may be wrong. Re-query the affected tool before the next write.

### detail parameter — ALWAYS start with summary

Most tools accept `detail:"summary"`. Use the right level:
- **summary** — first call, orient yourself (table list, model names, route overview)
- **standard** — working detail (columns with types, associations, action source) — DEFAULT
- **full** — only when you need indexes, foreign keys, code snippets, or complete content

Pattern: summary to find the target → standard to understand it → full only if needed.

### Start here — composite tools save multiple calls

**New to this project?** Get a full walkthrough first:
→ MCP: `rails_onboard(detail:"standard")`
→ CLI: `rails 'ai:tool[onboard]' detail=standard`

**`get_context` is your power tool** — bundles schema + model + controller + routes + views in ONE call:
→ MCP: `rails_get_context(controller:"CooksController", action:"create")`
→ CLI: `rails 'ai:tool[context]' controller=CooksController action=create`
→ MCP: `rails_get_context(model:"Cook")`
→ CLI: `rails 'ai:tool[context]' model=Cook`
→ MCP: `rails_get_context(feature:"cook")`
→ CLI: `rails 'ai:tool[context]' feature=cook`

**`analyze_feature` for broad discovery** — scans all layers (models, controllers, routes, services, jobs, views, tests):
→ MCP: `rails_analyze_feature(feature:"authentication")`
→ CLI: `rails 'ai:tool[analyze_feature]' feature=authentication`

Use individual tools only when you need deeper detail on a specific layer.

### Step-by-step workflows (follow this order)

**Modify a model** (add field, change validation, add scope):
1. `rails_get_context(model:"Cook")` or `rails 'ai:tool[context]' model=Cook` — schema + associations + validations in one call
2. Read the model file, make your edit
3. `rails_migration_advisor(action:"add_column", table:"cooks", column:"rating", type:"integer")` or `rails 'ai:tool[migration_advisor]' action=add_column table=cooks column=rating type=integer` — if schema change needed
4. `rails_validate(files:["app/models/cook.rb"], level:"rails")` or `rails 'ai:tool[validate]' files=app/models/cook.rb level=rails` — EVERY time after editing
5. `rails_generate_test(model:"Cook")` or `rails 'ai:tool[generate_test]' model=Cook` — generate tests matching project patterns

**Fix a controller bug:**
1. `rails_get_context(controller:"CooksController", action:"create")` or `rails 'ai:tool[context]' controller=CooksController action=create` — action source + routes + views + model
2. Read the controller file, make your fix
3. `rails_validate(files:["app/controllers/cooks_controller.rb"], level:"rails")` or `rails 'ai:tool[validate]' files=app/controllers/cooks_controller.rb level=rails`

**Build or modify a view:**
1. `rails_get_view(controller:"cooks")` or `rails 'ai:tool[view]' controller=cooks` — existing templates, partials, Stimulus refs
2. `rails_get_partial_interface(partial:"shared/status_badge")` or `rails 'ai:tool[partial_interface]' partial=shared/status_badge` — partial locals contract
3. `rails_get_component_catalog(component:"Button")` or `rails 'ai:tool[component_catalog]' component=Button` — ViewComponent/Phlex props, slots, previews
4. Read the view file, make your edit
5. `rails_validate(files:["app/views/cooks/index.html.erb"])` or `rails 'ai:tool[validate]' files=app/views/cooks/index.html.erb`

**Trace a method:**
→ MCP: `rails_search_code(pattern:"can_cook?", match_type:"trace")`
→ CLI: `rails 'ai:tool[search_code]' pattern="can_cook?" match_type=trace`

**Debug an error (one call — gathers context + git + logs + fix):**
→ MCP: `rails_diagnose(error:"NoMethodError: undefined method `foo` for nil", file:"app/models/cook.rb")`
→ CLI: `rails 'ai:tool[diagnose]' error="NoMethodError: undefined method foo" file=app/models/cook.rb`

**Review changes before merging:**
→ MCP: `rails_review_changes(ref:"main")`
→ CLI: `rails 'ai:tool[review_changes]' ref=main`

**Generate tests matching project patterns:**
→ MCP: `rails_generate_test(model:"Cook")`
→ CLI: `rails 'ai:tool[generate_test]' model=Cook`

### Common mistakes — avoid these

- **Don't read db/schema.rb** — use `get_schema`. It adds [indexed]/[unique] hints you'd miss.
- **Don't read model files for reference** — use `get_model_details`. It resolves concerns, inherited methods, and implicit belongs_to validations.
- **Prefer `rails_search_code` over Grep** for method tracing and cross-layer search. It excludes sensitive files, supports `match_type:"trace"`, and paginates.
- **Don't call tools without a target** — `get_model_details()` without `model:` returns a paginated list, not an error. Always specify what you want.
- **Don't skip validation** — run `rails_validate` after EVERY edit. It catches syntax errors AND Rails-specific issues (missing partials, bad column refs).
- **Don't ignore cross-references** — tool responses include `_Next:` hints suggesting the best follow-up call. Follow them.
- **Don't call `detail:"full"` first** — start with `summary` to find your target, then drill in. Full responses bury the signal.

### Rules

1. **Use composite tools first** — `rails_get_context` and `rails_analyze_feature` before individual tools
2. **NEVER read reference files** — db/schema.rb, config/routes.rb, model files, test files — tools are better
3. **Prefer `rails_search_code`** for tracing and cross-layer search — standard search tools are fine for simple targeted lookups
4. **Read files ONLY to Edit them** — not for reference
5. **Validate EVERY edit** — `rails_validate(files:[...], level:"rails")`
6. **Follow _Next:_ hints** — tool responses suggest the best follow-up call
7. If MCP tools are not connected, use CLI: `rails 'ai:tool[TOOL_NAME]' param=value`

### All 38 Tools

| MCP | CLI | What it does |
|-----|-----|-------------|
| `rails_get_context(model:"X")` | `rails 'ai:tool[context]' model=X` | **START HERE** — schema + model + controller + routes + views in one call |
| `rails_analyze_feature(feature:"X")` | `rails 'ai:tool[analyze_feature]' feature=X` | Full-stack: models + controllers + routes + services + jobs + views + tests |
| `rails_search_code(pattern:"X", match_type:"trace")` | `rails 'ai:tool[search_code]' pattern=X match_type=trace` | Search + trace: definition, source, callers, test coverage. Also: `match_type:"any"` for regex search |
| `rails_get_controllers(controller:"X", action:"Y")` | `rails 'ai:tool[controllers]' controller=X action=Y` | Action source + inherited filters + render map + private methods |
| `rails_validate(files:[...], level:"rails")` | `rails 'ai:tool[validate]' files=a.rb,b.rb level=rails` | Syntax + semantic validation (run after EVERY edit) |
| `rails_get_schema(table:"X")` | `rails 'ai:tool[schema]' table=X` | Columns with [indexed]/[unique]/[encrypted]/[default] hints |
| `rails_get_model_details(model:"X")` | `rails 'ai:tool[model_details]' model=X` | Associations, validations, scopes, enums, macros, delegations |
| `rails_get_routes(controller:"X")` | `rails 'ai:tool[routes]' controller=X` | Routes with code-ready helpers and controller filters inline |
| `rails_get_view(controller:"X")` | `rails 'ai:tool[view]' controller=X` | Templates with ivars, Turbo wiring, Stimulus refs, partial locals |
| `rails_get_stimulus(controller:"X")` | `rails 'ai:tool[stimulus]' controller=X` | Targets, values, actions + HTML data-attributes + view lookup |
| `rails_get_test_info(model:"X")` | `rails 'ai:tool[test_info]' model=X` | Tests + fixture contents + test template |
| `rails_get_concern(name:"X", detail:"full")` | `rails 'ai:tool[concern]' name=X detail=full` | Concern methods with source + which models include it |
| `rails_get_callbacks(model:"X")` | `rails 'ai:tool[callbacks]' model=X` | Callbacks in Rails execution order with source |
| `rails_get_edit_context(file:"X", near:"Y")` | `rails 'ai:tool[edit_context]' file=X near=Y` | Code around a match with class/method context |
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
| `rails_generate_test(model:"X")` | `rails 'ai:tool[generate_test]' model=X` | Generate test scaffolding matching project patterns (framework, factories, style) |
| `rails_diagnose(error:"X")` | `rails 'ai:tool[diagnose]' error="X"` | One-call error diagnosis: context + git changes + logs + fix suggestions |
| `rails_review_changes(ref:"main")` | `rails 'ai:tool[review_changes]' ref=main` | PR/commit review: file context + warnings (missing indexes, removed validations) |
| `rails_onboard(detail:"standard")` | `rails 'ai:tool[onboard]' detail=standard` | Narrative app walkthrough for new developers or AI agents |
| `rails_runtime_info(detail:"standard")` | `rails 'ai:tool[runtime_info]' detail=standard` | Live runtime: DB pool, table sizes, cache stats, job queues, pending migrations |
| `rails_session_context(action:"status")` | `rails 'ai:tool[session_context]' action=status` | Track what you've already queried, avoid redundant calls |