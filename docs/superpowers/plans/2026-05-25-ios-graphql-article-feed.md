# iOS GraphQL Article Feed Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a small GraphQL article feed API that lets the iOS app replace the existing article list REST calls without removing those REST endpoints yet.

**Architecture:** Add `graphql-ruby`, expose `POST /graphql`, and implement a single `articleFeed` query. The resolver delegates feed selection to the existing `Articles::Query` module and keeps the current Pagy keyset pagination and optional liked personalization.

**Tech Stack:** Rails 8.1, Ruby 4.0, graphql-ruby, Devise/JWT, Pagy keyset, Minitest, PostgreSQL.

---

## File Structure

- Modify `Gemfile`: add the `graphql` gem near the existing API/JSON gems.
- Modify `config/routes.rb`: add `post "/graphql", to: "graphql#execute"`.
- Create `app/controllers/graphql_controller.rb`: JSON-only GraphQL endpoint with optional bearer-token authentication.
- Create `app/graphql/al_news_schema.rb`: root GraphQL schema.
- Create `app/graphql/types/base_object.rb`: shared GraphQL object base class.
- Create `app/graphql/types/base_enum.rb`: shared GraphQL enum base class.
- Create `app/graphql/types/query_type.rb`: root query field registration.
- Create `app/graphql/types/article_feed_kind_enum.rb`: feed-kind enum.
- Create `app/graphql/types/article_type.rb`: article fields matching the iOS REST contract.
- Create `app/graphql/types/article_feed_type.rb`: feed payload wrapper.
- Create `app/graphql/types/pagination_type.rb`: pagination payload wrapper.
- Create `app/graphql/resolvers/article_feed_resolver.rb`: resolver that applies `Articles::Query`, Pagy keyset, and liked-id calculation.
- Create `test/controllers/graphql_controller_test.rb`: request tests for public, tagged, authenticated-liked, and invalid tagged feed behavior.

Do not edit `Api::V1::ArticlesController` in this pass. REST endpoints stay available.

---

### Task 1: Add GraphQL Dependency

**Files:**
- Modify: `Gemfile`
- Modify: `Gemfile.lock`

- [ ] **Step 1: Add the gem**

Add this line immediately after `gem "jbuilder"` in `Gemfile`:

```ruby
gem "graphql", "~> 2.5"
```

- [ ] **Step 2: Install dependencies**

Run:

```bash
bundle install
```

Expected: Bundler resolves and writes `Gemfile.lock` with `graphql`.

- [ ] **Step 3: Verify the gem is installed**

Run:

```bash
bundle exec ruby -e 'require "graphql"; puts GraphQL::VERSION'
```

Expected: prints a `2.5.x` or newer compatible `2.x` version.

- [ ] **Step 4: Commit**

Run:

```bash
git add Gemfile Gemfile.lock
git commit -m "Add GraphQL dependency"
```

---

### Task 2: Write Failing GraphQL Request Tests

**Files:**
- Create: `test/controllers/graphql_controller_test.rb`

- [ ] **Step 1: Create the failing tests**

Create `test/controllers/graphql_controller_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class GraphqlControllerTest < ActionDispatch::IntegrationTest
  ARTICLE_FEED_QUERY = <<~GRAPHQL
    query ArticleFeed($kind: ArticleFeedKind!, $search: String, $keyword: String, $page: String, $limit: Int) {
      articleFeed(kind: $kind, search: $search, keyword: $keyword, page: $page, limit: $limit) {
        articles {
          slug
          title
          titleKo
          url
          host
          isRelated
          likersCount
          postsCount
          summaryKey
          tags
          liked
          publishedAt
          createdAt
          updatedAt
        }
        pagination {
          page
          nextPage
          limit
        }
      }
    }
  GRAPHQL

  test "public related feed returns articles and pagination" do
    post graphql_path,
         params: { query: ARTICLE_FEED_QUERY, variables: { kind: "RELATED" } },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert_nil body["errors"]
    assert_kind_of Array, body.dig("data", "articleFeed", "articles")
    assert_kind_of Hash, body.dig("data", "articleFeed", "pagination")
    assert_equal 15, body.dig("data", "articleFeed", "pagination", "limit")
  end

  test "public others feed returns articles" do
    post graphql_path,
         params: { query: ARTICLE_FEED_QUERY, variables: { kind: "OTHERS" } },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert_nil body["errors"]
    assert_kind_of Array, body.dig("data", "articleFeed", "articles")
  end

  test "public tagged feed filters by keyword" do
    article = articles(:ruby_article)
    make_visible_related_article(article)
    article.tag_list.add("ruby")
    article.save!

    post graphql_path,
         params: { query: ARTICLE_FEED_QUERY, variables: { kind: "TAGGED", keyword: "ruby" } },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    slugs = body.dig("data", "articleFeed", "articles").map { |item| item["slug"] }

    assert_nil body["errors"]
    assert_includes slugs, article.slug
  end

  test "authenticated related feed marks liked articles" do
    user = users(:john)
    article = articles(:ruby_article)
    make_visible_related_article(article)
    user.like!(article)
    token = jwt_for(user)

    post graphql_path,
         params: { query: ARTICLE_FEED_QUERY, variables: { kind: "RELATED" } },
         headers: { "Authorization" => token },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    liked_article = body.dig("data", "articleFeed", "articles").find { |item| item["slug"] == article.slug }

    assert_nil body["errors"]
    assert_equal true, liked_article["liked"]
  end

  test "tagged feed requires keyword" do
    post graphql_path,
         params: { query: ARTICLE_FEED_QUERY, variables: { kind: "TAGGED" } },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert_nil body["data"]["articleFeed"]
    assert_match "keyword is required for tagged article feed", body["errors"].first["message"]
  end

  private
    def make_visible_related_article(article)
      article.update!(
        deleted_at: nil,
        is_related: true,
        title_ko: article.title_ko.presence || "루비 기사",
        slug: article.slug.presence || "ruby-article",
        published_at: article.published_at || Time.current
      )
    end

    def jwt_for(user)
      post user_session_path,
           params: { user: { email: user.email, password: "password" } },
           as: :json

      response.headers.fetch("Authorization")
    end
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```bash
TEST_DATABASE_URL=postgres://postgres:postgres1234@localhost:5432/ra-news_test bin/rails test test/controllers/graphql_controller_test.rb
```

Expected: fail because `graphql_path` or `GraphqlController` is not defined.

- [ ] **Step 3: Commit the failing test**

Run:

```bash
git add test/controllers/graphql_controller_test.rb
git commit -m "Add GraphQL article feed request tests"
```

---

### Task 3: Add Route, Controller, and Schema Skeleton

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/graphql_controller.rb`
- Create: `app/graphql/al_news_schema.rb`
- Create: `app/graphql/types/base_object.rb`
- Create: `app/graphql/types/base_enum.rb`
- Create: `app/graphql/types/query_type.rb`

- [ ] **Step 1: Add the route**

In `config/routes.rb`, add this route after the Devise routes and before the `namespace :api` block:

```ruby
  post "/graphql", to: "graphql#execute"
```

- [ ] **Step 2: Add the controller**

Create `app/controllers/graphql_controller.rb`:

```ruby
# frozen_string_literal: true

class GraphqlController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  skip_before_action :authenticate_user!
  before_action :authenticate_user_from_bearer_token

  def execute
    result = AlNewsSchema.execute(
      params[:query],
      variables: variables,
      context: { current_user: current_user }
    )

    render json: result
  end

  private
    def authenticate_user_from_bearer_token
      return if request.authorization.blank?

      authenticate_user!
    end

    def variables
      case params[:variables]
      when String
        params[:variables].present? ? JSON.parse(params[:variables]) : {}
      when Hash, ActionController::Parameters
        params[:variables]
      when nil
        {}
      else
        raise ArgumentError, "Unexpected parameter: variables"
      end
    end
end
```

- [ ] **Step 3: Add GraphQL base types and schema**

Create `app/graphql/types/base_object.rb`:

```ruby
# frozen_string_literal: true

module Types
  class BaseObject < GraphQL::Schema::Object
  end
end
```

Create `app/graphql/types/base_enum.rb`:

```ruby
# frozen_string_literal: true

module Types
  class BaseEnum < GraphQL::Schema::Enum
  end
end
```

Create `app/graphql/types/query_type.rb`:

```ruby
# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    description "The query root of this schema"
  end
end
```

Create `app/graphql/al_news_schema.rb`:

```ruby
# frozen_string_literal: true

class AlNewsSchema < GraphQL::Schema
  query Types::QueryType
end
```

- [ ] **Step 4: Run route and syntax validation**

Run:

```bash
bin/rails routes -g graphql
```

Expected: output includes `POST /graphql(.:format) graphql#execute`.

Run:

```bash
rails 'ai:tool[validate]' files=app/controllers/graphql_controller.rb,config/routes.rb level=rails
```

Expected: no syntax or Rails semantic errors.

- [ ] **Step 5: Run the GraphQL tests**

Run:

```bash
TEST_DATABASE_URL=postgres://postgres:postgres1234@localhost:5432/ra-news_test bin/rails test test/controllers/graphql_controller_test.rb
```

Expected: fail because `articleFeed` is not defined on `Types::QueryType`.

- [ ] **Step 6: Commit**

Run:

```bash
git add config/routes.rb app/controllers/graphql_controller.rb app/graphql/al_news_schema.rb app/graphql/types/base_object.rb app/graphql/types/base_enum.rb app/graphql/types/query_type.rb
git commit -m "Add GraphQL endpoint skeleton"
```

---

### Task 4: Add Article Feed Types and Resolver

**Files:**
- Modify: `app/graphql/types/query_type.rb`
- Create: `app/graphql/types/article_feed_kind_enum.rb`
- Create: `app/graphql/types/article_type.rb`
- Create: `app/graphql/types/article_feed_type.rb`
- Create: `app/graphql/types/pagination_type.rb`
- Create: `app/graphql/resolvers/article_feed_resolver.rb`

- [ ] **Step 1: Add the enum and object types**

Create `app/graphql/types/article_feed_kind_enum.rb`:

```ruby
# frozen_string_literal: true

module Types
  class ArticleFeedKindEnum < Types::BaseEnum
    value "RELATED", "Related articles feed"
    value "OTHERS", "Other articles feed"
    value "TAGGED", "Articles tagged with a keyword"
  end
end
```

Create `app/graphql/types/pagination_type.rb`:

```ruby
# frozen_string_literal: true

module Types
  class PaginationType < Types::BaseObject
    field :page, String, null: true
    field :next_page, String, null: true
    field :limit, Integer, null: false
  end
end
```

Create `app/graphql/types/article_type.rb`:

```ruby
# frozen_string_literal: true

module Types
  class ArticleType < Types::BaseObject
    field :slug, String, null: true
    field :title, String, null: true
    field :title_ko, String, null: true
    field :url, String, null: true
    field :host, String, null: true
    field :is_related, Boolean, null: false
    field :likers_count, Integer, null: false
    field :posts_count, Integer, null: false
    field :summary_key, GraphQL::Types::JSON, null: true
    field :tags, [String], null: false
    field :liked, Boolean, null: false
    field :published_at, GraphQL::Types::ISO8601DateTime, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    def tags
      object.tags.map(&:name)
    end

    def liked
      context[:liked_article_ids]&.include?(object.id) || false
    end
  end
end
```

Create `app/graphql/types/article_feed_type.rb`:

```ruby
# frozen_string_literal: true

module Types
  class ArticleFeedType < Types::BaseObject
    field :articles, [Types::ArticleType], null: false
    field :pagination, Types::PaginationType, null: false
  end
end
```

- [ ] **Step 2: Add the resolver**

Create `app/graphql/resolvers/article_feed_resolver.rb`:

```ruby
# frozen_string_literal: true
# rbs_inline: enabled

module Resolvers
  class ArticleFeedResolver < GraphQL::Schema::Resolver
    type Types::ArticleFeedType, null: false

    argument :kind, Types::ArticleFeedKindEnum, required: true
    argument :search, String, required: false
    argument :keyword, String, required: false
    argument :page, String, required: false
    argument :limit, Integer, required: false

    #: (kind: String, ?search: String?, ?keyword: String?, ?page: String?, ?limit: Integer?) -> Hash[Symbol, untyped]
    def resolve(kind:, search: nil, keyword: nil, page: nil, limit: nil)
      relation = article_relation(kind:, search:, keyword:)
      pagy = Pagy::Keyset.new(
        relation.reorder(published_at: :desc, id: :desc),
        page:,
        limit: limit || Pagy::OPTIONS[:limit]
      )
      articles = pagy.records
      context[:liked_article_ids] = liked_article_ids(articles)

      {
        articles:,
        pagination: {
          page: pagy.page,
          next_page: pagy.next,
          limit: pagy.limit
        }
      }
    end

    private
      #: (kind: String, search: String?, keyword: String?) -> ActiveRecord::Relation
      def article_relation(kind:, search:, keyword:)
        case kind
        when "RELATED"
          Articles::Query.index_json(search)
        when "OTHERS"
          Articles::Query.others
        when "TAGGED"
          raise GraphQL::ExecutionError, "keyword is required for tagged article feed" if keyword.blank?

          Articles::Query.tagged(keyword)
        else
          raise GraphQL::ExecutionError, "unsupported article feed kind"
        end
      end

      #: (Array[Article]) -> Array[Integer]
      def liked_article_ids(articles)
        Like.liked_ids_for(
          liker: context[:current_user],
          likeable_type: "Article",
          likeable_ids: articles.map(&:id)
        )
      end
  end
end
```

- [ ] **Step 3: Register the field**

Replace `app/graphql/types/query_type.rb` with:

```ruby
# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    description "The query root of this schema"

    field :article_feed, resolver: Resolvers::ArticleFeedResolver
  end
end
```

- [ ] **Step 4: Run focused validation and tests**

Run:

```bash
rails 'ai:tool[validate]' files=app/graphql/types/query_type.rb,app/graphql/types/article_feed_kind_enum.rb,app/graphql/types/article_type.rb,app/graphql/types/article_feed_type.rb,app/graphql/types/pagination_type.rb,app/graphql/resolvers/article_feed_resolver.rb level=rails
```

Expected: no syntax or Rails semantic errors.

Run:

```bash
TEST_DATABASE_URL=postgres://postgres:postgres1234@localhost:5432/ra-news_test bin/rails test test/controllers/graphql_controller_test.rb
```

Expected: all GraphQL controller tests pass.

- [ ] **Step 5: Commit**

Run:

```bash
git add app/graphql/types/query_type.rb app/graphql/types/article_feed_kind_enum.rb app/graphql/types/article_type.rb app/graphql/types/article_feed_type.rb app/graphql/types/pagination_type.rb app/graphql/resolvers/article_feed_resolver.rb
git commit -m "Add GraphQL article feed resolver"
```

---

### Task 5: Final Verification and Graph Update

**Files:**
- Generated/updated: `graphify-out/`

- [ ] **Step 1: Run existing REST API tests**

Run:

```bash
TEST_DATABASE_URL=postgres://postgres:postgres1234@localhost:5432/ra-news_test bin/rails test test/controllers/api/v1/articles_controller_test.rb
```

Expected: pass. This confirms the existing REST article API was not broken.

- [ ] **Step 2: Run GraphQL tests**

Run:

```bash
TEST_DATABASE_URL=postgres://postgres:postgres1234@localhost:5432/ra-news_test bin/rails test test/controllers/graphql_controller_test.rb
```

Expected: pass.

- [ ] **Step 3: Run quality gate**

Run:

```bash
TEST_DATABASE_URL=postgres://postgres:postgres1234@localhost:5432/ra-news_test bin/rake quality
```

Expected: pass. Record line coverage, branch coverage, flog max method, and flog max class in the final response or PR description.

- [ ] **Step 4: Rebuild graphify code graph**

Run:

```bash
python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('.'))"
```

Expected: exits successfully and updates `graphify-out/` if code graph content changed.

- [ ] **Step 5: Validate final diff**

Run:

```bash
git status --short
git diff --stat HEAD
```

Expected: only GraphQL implementation, tests, lockfile, and graphify updates are present.

- [ ] **Step 6: Commit final graph update if needed**

Run:

```bash
git add graphify-out
git commit -m "Update graph for GraphQL article feed"
```

If `graphify-out/` did not change, skip this commit.
