# iOS GraphQL Article Feed Design

## Goal

Replace the iOS app's first set of article list REST calls with a GraphQL API while keeping the existing REST endpoints available during migration.

The first implementation scope is intentionally small:

- `GET /api/v1/articles`
- `GET /api/v1/articles/others`
- `GET /api/v1/articles/tag/:keyword`

Authentication, token refresh, mutations, comments, likes, and article detail changes are out of scope for this first pass.

## Current Behavior

The existing REST article API is public. If a request includes a valid logged-in user, the response personalizes the `liked` field. If there is no current user, the endpoint still returns articles and `liked` resolves to `false`.

All three REST actions use the same response shape:

- `articles`: array of serialized articles
- `pagination`: `page`, `next_page`, and `limit`

The current article selection logic must remain the source of truth:

- Main feed uses `Articles::Query.index_json(search)`
- Other feed uses `Articles::Query.others`
- Tagged feed uses `Articles::Query.tagged(keyword)`
- All feeds order by `published_at desc, id desc`

The GraphQL layer must reuse this query module instead of duplicating feed rules.

## Chosen Approach

Add a GraphQL endpoint with one feed query:

```graphql
query ArticleFeed(
  $kind: ArticleFeedKind!,
  $search: String,
  $keyword: String,
  $page: String,
  $limit: Int
) {
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
```

The enum values are:

- `RELATED`: maps to the current `index` REST action
- `OTHERS`: maps to the current `others` REST action
- `TAGGED`: maps to the current `tag` REST action

This keeps the iOS client on a single GraphQL operation while still preserving the three existing feed concepts.

## Schema

```graphql
type Query {
  articleFeed(
    kind: ArticleFeedKind!,
    search: String,
    keyword: String,
    page: String,
    limit: Int
  ): ArticleFeed!
}

enum ArticleFeedKind {
  RELATED
  OTHERS
  TAGGED
}

type ArticleFeed {
  articles: [Article!]!
  pagination: Pagination!
}

type Article {
  slug: String
  title: String
  titleKo: String
  url: String
  host: String
  isRelated: Boolean!
  likersCount: Int!
  postsCount: Int!
  summaryKey: JSON
  tags: [String!]!
  liked: Boolean!
  publishedAt: ISO8601DateTime
  createdAt: ISO8601DateTime!
  updatedAt: ISO8601DateTime!
}

type Pagination {
  page: String
  nextPage: String
  limit: Int!
}
```

## Authentication

The first GraphQL endpoint must match current REST access:

- Anonymous requests are allowed for `articleFeed`.
- Requests with a bearer token should resolve `current_user` through the same Devise/JWT path used by existing API requests.
- `Article.liked` should be `false` when no user is present.
- `Article.liked` should be calculated from `Like.liked_ids_for` when a user is present.

Token refresh stays on the existing REST endpoint for now.

## Pagination

Use the same Pagy keyset behavior as the REST controller. The GraphQL response should expose the existing pagination fields as camelCase:

- `page`
- `nextPage`
- `limit`

The first implementation does not introduce Relay connections. That can be revisited after the iOS app has moved its first article lists to GraphQL.

## Error Handling

Invalid input should produce GraphQL errors rather than REST-style JSON error objects.

Rules:

- `kind: TAGGED` requires `keyword`.
- Blank `keyword` for `TAGGED` is invalid.
- `search` is only meaningful for `RELATED`; ignore it for the other feed kinds unless the implementation can reject it without hurting client ergonomics.
- Pagination values should use the same defaults as the current REST path when omitted.

## Tests

Add focused request tests for `/graphql`:

- Public `RELATED` feed returns `articles` and `pagination`.
- Public `OTHERS` feed returns `articles`.
- Public `TAGGED` feed filters by keyword.
- Authenticated request marks liked articles correctly.
- `TAGGED` without `keyword` returns a GraphQL error.

Existing REST tests should remain unchanged during the first migration step.

## Rollout

1. Add GraphQL server support and schema files.
2. Add `articleFeed` query using existing `Articles::Query`.
3. Verify GraphQL request tests pass.
4. Keep existing REST endpoints in place.
5. Update the iOS app to use `articleFeed`.
6. Remove REST article list endpoints only after the iOS app no longer depends on them.

## Non-Goals

- No GraphQL mutations in the first pass.
- No token refresh replacement in the first pass.
- No article detail replacement in the first pass.
- No comment, post, follow, or notification GraphQL API in the first pass.
- No Relay connection schema in the first pass.
