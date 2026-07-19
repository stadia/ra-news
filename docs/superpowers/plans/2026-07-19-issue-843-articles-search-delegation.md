# Issue 843 Articles Search Delegation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep the articles index behavior unchanged while moving its search-page composition out of `ArticlesController`.

**Architecture:** `Articles::Query` remains the relation builder. `Articles::Search` receives the index request inputs and produces the HTML index view state; it owns source selection, relation pagination, and suggestions. `ArticlesController#index` supplies request and shared presentation dependencies, then renders the returned state.

**Tech Stack:** Rails 8, Ruby 4, Minitest integration tests, Pagy, Phlex.

## Global Constraints

- Preserve the Google source fast path, including its zero Article/Like/Tag query guarantee.
- Preserve search-term trimming and the existing maximum length.
- Add no dependencies and do not change routes, schema, or the Phlex view contract.
- Run Rails semantic validation after every code edit and the PostgreSQL-backed test suite before completion.

---

### Task 1: Lock the index composition boundary with a regression test

**Files:**

- Modify: `test/controllers/articles_controller_test.rb`
- Test: `test/controllers/articles_controller_test.rb`

**Interfaces:**

- Consumes: `Articles::Search.index_html` (new)
- Produces: a regression assertion that the controller delegates Ruby-News index composition to `Articles::Search`.

- [ ] **Step 1: Write the failing test**

Add an integration test that stubs `Articles::Search.index_html` and verifies an ordinary index request calls it with the trimmed search term and current page parameters, while preserving a successful response.

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/articles_controller_test.rb -n /delegates/`

Expected: FAIL because `Articles::Search.index_html` does not exist and the controller still calls `Articles::Query.index_html` directly.

- [ ] **Step 3: Write minimal implementation**

Add `Articles::Search.index_html(search:, page:, pagy:)`, returning immutable index state that contains `pagy`, `articles`, and `suggestions`. Call it from `ArticlesController#index` only for the Ruby-News source.

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/controllers/articles_controller_test.rb -n /delegates/`

Expected: PASS.

### Task 2: Preserve existing index behavior and validate the refactor

**Files:**

- Modify: `app/functions/articles/search.rb`
- Modify: `app/controllers/articles_controller.rb`
- Modify: `test/controllers/articles_controller_test.rb`

**Interfaces:**

- Consumes: `Articles::Query.index_html(search)`, `Articles::Search.suggest(query)`, and the controller's existing Pagy helper.
- Produces: the existing `Views::Articles::Index` keyword inputs without changing its public contract.

- [ ] **Step 1: Run the focused controller tests**

Run: `bin/rails test test/controllers/articles_controller_test.rb`

Expected: PASS, including Google-source query avoidance and signed-in preload assertions.

- [ ] **Step 2: Validate edited Rails files**

Run: `bin/rails 'ai:tool[validate]' files=app/functions/articles/search.rb,app/controllers/articles_controller.rb level=rails`

Expected: no syntax or Rails semantic errors.

- [ ] **Step 3: Run quality gates**

Run: `bin/rake quality`

Expected: all currently configured gates pass; if an unrelated baseline gate fails, record its number and cause without claiming success.
