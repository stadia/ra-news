# Blog Public Index & Detail Namespacing — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/@user/blog` becomes the public blog index and `/@user/blog/:slug` the public blog detail; blog authoring/management moves to `/account/blog`.

**Architecture:** Reuse the existing profile activity-tab infrastructure (`ActivityTabs`, `render_activity_page`) — the `blog` tab flips from owner-only to public and renders published posts with `PostCard`, mirroring the `posts` tab. Blog detail is served by the existing `PostsController#show`, now branching on a nested `/@:username/blog/:slug` route (slugs are globally unique via `friendly_id`). A single `post_permalink_path` helper routes blog links to the new URL. Legacy `/posts/:slug` no longer serves blog posts (destructive — only 1 blog post exists today).

**Tech Stack:** Rails 8.1 / Ruby 4.0, Phlex views/components, Devise auth, Minitest + fixtures (`test/`), Discard soft-delete, FriendlyId slugs, Federails.

## Global Constraints

- Tests: **Minitest** (`ActionDispatch::IntegrationTest` / `ApplicationSystemTestCase`) under `test/`, using fixtures (`users(:john)`, `users(:jane)`, `posts(:blog_published)`, `posts(:blog_draft)`). NOT RSpec.
- Run Ruby commands via mise: `mise x -- <cmd>` (e.g. `mise x -- bin/rails test test/...`).
- Slugs are globally unique (`friendly_id :random_slug`); username in the blog-detail route is vanity/scoping, not the lookup key.
- Phlex route helpers are available in `Components::Base`/`Views::Base` via `Phlex::Rails::Helpers::Routes` — call `user_profile_blog_post_path(...)` / `post_path(...)` directly.
- Every new i18n key MUST be added to all three locales: `config/locales/en.yml`, `ja.yml`, `ko.yml`.
- Blog viewability rule (unchanged): a post is viewable if `kept? && published?`, OR `kept? && current_user == owner` (draft preview). Preserved by reusing `PostsController#viewable?`.
- After each task run the RuboCop/RBS pre-commit hook (runs automatically on commit); keep edits `# frozen_string_literal: true` compliant.

---

### Task 1: Routes, `PostsController#show` branching, and `post_permalink_path` helper

Blog detail moves to `/@:username/blog/:slug`; legacy `/posts/:slug` stops serving blog posts. Add the shared permalink helper both later tasks depend on.

**Files:**
- Modify: `config/routes.rb` (after line 115, the blog index route)
- Modify: `app/controllers/posts_controller.rb:12-20` (`#show`) + add private `find_show_post`
- Modify: `app/components/base.rb` (add `post_permalink_path`)
- Test: `test/controllers/posts_controller_test.rb` (update blog-show tests + add legacy-404 tests)

**Interfaces:**
- Produces: route helper `user_profile_blog_post_path(username:, slug:)` → `/@:username/blog/:slug`; route helper `account_blog_path` → `/account/blog`; instance method `post_permalink_path(post)` on `Components::Base` (and subclasses incl. `Views::Base`) returning the blog URL for `post.blog?` else `post_path(post)`.

- [ ] **Step 1: Add the two routes**

In `config/routes.rb`, immediately after the existing blog index line (`get "/@:username/blog", ...` at line 115) add:

```ruby
  get "/@:username/blog/:slug", to: "posts#show", as: :user_profile_blog_post, format: false, constraints: { username: /[^\/]+/ }
```

And after the `devise_scope :user do ... end` block (after line 24) add the management route:

```ruby
  get "account/blog", to: "blog_posts#index", as: :account_blog
```

- [ ] **Step 2: Branch `PostsController#show` on the route**

Replace `app/controllers/posts_controller.rb` lines 12-20 with:

```ruby
  def show
    post = find_show_post
    raise ActiveRecord::RecordNotFound unless viewable?(post)
    root = post.root
    @posts = build_thread(root)
    @liked_post_ids = current_user ? Like.liked_ids_for(liker: current_user, likeable_type: "Post", likeable_ids: @posts.map(&:id)) : []
    @boosted_post_ids = current_user ? Boost.boosted_ids_for(booster: current_user, boostable_type: "Post", boostable_ids: @posts.map(&:id)) : []
    render Views::Posts::Show.new(posts: @posts, liked_post_ids: @liked_post_ids, boosted_post_ids: @boosted_post_ids)
  end
```

Then add this private method (near the other private helpers, e.g. just above `def viewable?` at line 109):

```ruby
  def find_show_post
    includes = [ :user, :federails_actor, :article, :tags, { parent: [ :user, :federails_actor ] } ]
    if params[:username]
      User.find_by!(username: params[:username]).posts.blog.includes(includes).find_by!(slug: params[:slug])
    else
      Post.where.not(post_type: :blog).includes(includes).find_by!(slug: params[:id])
    end
  end
```

- [ ] **Step 3: Add `post_permalink_path` to `Components::Base`**

In `app/components/base.rb`, inside the `private` section (after `safe_url`), add:

```ruby
  def post_permalink_path(post)
    if post.blog?
      user_profile_blog_post_path(username: post.user.username, slug: post)
    else
      post_path(post)
    end
  end
```

- [ ] **Step 4: Update blog-show tests to the new URL + add legacy-404 tests**

In `test/controllers/posts_controller_test.rb`, replace every blog-post `get post_url(...)` in the show tests (the block around lines 104-152) with the nested helper. Concretely:

- "should show blog post with reading layout": `get user_profile_blog_post_url(username: post.user.username, slug: post)`
- "published post is served to anyone": `get user_profile_blog_post_url(username: post.user.username, slug: post)`
- "draft is not served to anonymous visitors": `get user_profile_blog_post_url(username: draft.user.username, slug: draft)` (still `assert_response :not_found`)
- "draft is not served to a non-owner": `get user_profile_blog_post_url(username: draft.user.username, slug: draft)` (still `:not_found`)
- "owner can preview their own draft": `get user_profile_blog_post_url(username: draft.user.username, slug: draft)` (still `:success`)
- "discarded blog is not served publicly": `get user_profile_blog_post_url(username: post.user.username, slug: post)` (still `:not_found`)

Then append two new tests to the class:

```ruby
  test "blog post is not served at legacy /posts/:slug" do
    blog = posts(:blog_published)

    get post_url(blog)

    assert_response :not_found
  end

  test "short post is still served at /posts/:slug" do
    short = posts(:short_with_article)

    get post_url(short)

    assert_response :success
  end
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `mise x -- bin/rails test test/controllers/posts_controller_test.rb`
Expected: PASS (all show tests green, legacy blog URL returns 404, short post still served).

- [ ] **Step 6: Commit**

```bash
git add config/routes.rb app/controllers/posts_controller.rb app/components/base.rb test/controllers/posts_controller_test.rb
git commit -m "feat: serve blog detail at /@user/blog/:slug, add account/blog route + permalink helper"
```

---

### Task 2: Route blog links through `post_permalink_path` (PostCard, controller redirects, reply job)

Every blog link/redirect must target the new URL. Legacy `post_path` for blog posts now 404s, so this task prevents broken links introduced by Task 1.

**Files:**
- Modify: `app/components/posts/post_card.rb:67,118,123`
- Modify: `app/controllers/blog_posts_controller.rb:40,65,79`
- Modify: `app/jobs/reply_notification_job.rb:45-55` (`notification_path`)
- Test: `test/controllers/blog_posts_controller_test.rb` (redirect expectations)

**Interfaces:**
- Consumes: `post_permalink_path(post)` from Task 1 (Components::Base); `user_profile_blog_post_path(username:, slug:)` route.

- [ ] **Step 1: Update redirect expectations in blog_posts test (write failing test first)**

In `test/controllers/blog_posts_controller_test.rb` change these assertions:

- "publishing a new draft creates and publishes in one request" (line 74):
  `assert_redirected_to user_profile_blog_post_url(username: published.user.username, slug: published)`
- "publishes a complete draft" (line 132):
  `assert_redirected_to user_profile_blog_post_url(username: @draft.user.username, slug: @draft)`
- "updates a published blog post" (line 152):
  `assert_redirected_to user_profile_blog_post_url(username: @published.user.username, slug: @published)`

- [ ] **Step 2: Run to verify failure**

Run: `mise x -- bin/rails test test/controllers/blog_posts_controller_test.rb -n "/publishing a new draft|publishes a complete draft|updates a published/"`
Expected: FAIL (controller still redirects to `post_url`).

- [ ] **Step 3: Update controller redirects**

In `app/controllers/blog_posts_controller.rb` replace the three `redirect_to post_path(@post), ...` lines (40, 65, 79) with:

```ruby
      redirect_to user_profile_blog_post_path(username: @post.user.username, slug: @post), notice: t("posts.blog.published")
```

(line 40, `#create`)

```ruby
        format.html { redirect_to user_profile_blog_post_path(username: @post.user.username, slug: @post), notice: t("posts.blog.updated") }
```

(line 65, `#update`)

```ruby
    redirect_to user_profile_blog_post_path(username: @post.user.username, slug: @post), notice: t("posts.blog.published")
```

(line 79, `#publish`)

- [ ] **Step 4: Update PostCard links**

In `app/components/posts/post_card.rb` replace `post_path(@post)` at lines 67, 118, 123 with `post_permalink_path(@post)`. Example (line 118):

```ruby
      link_to @post.title, post_permalink_path(@post), class: "hover:text-accent-text transition-colors", data: { turbo_frame: "_top" }
```

Do the same for line 67 (timestamp link) and line 123 (read_more link).

- [ ] **Step 5: Update reply notification path**

In `app/jobs/reply_notification_job.rb`, replace the `else` branch of `notification_path` (line 52) so blog parents link to the new URL:

```ruby
  def notification_path(parent_post)
    if parent_post.article.present?
      Rails.application.routes.url_helpers.article_path(
        parent_post.article,
        anchor: "post_#{parent_post.id}"
      )
    elsif parent_post.blog?
      Rails.application.routes.url_helpers.user_profile_blog_post_path(
        username: parent_post.user.username, slug: parent_post
      )
    else
      Rails.application.routes.url_helpers.post_path(parent_post)
    end
  end
```

- [ ] **Step 6: Run tests to verify pass**

Run: `mise x -- bin/rails test test/controllers/blog_posts_controller_test.rb`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add app/components/posts/post_card.rb app/controllers/blog_posts_controller.rb app/jobs/reply_notification_job.rb test/controllers/blog_posts_controller_test.rb
git commit -m "feat: route blog links/redirects through blog permalink"
```

---

### Task 3: Public blog index (profiles#blog + ActivityTabs + BlogList rewrite + Show view)

Flip the `blog` tab from owner-only management to a public list of published blog posts, reusing the `posts`-tab machinery.

**Files:**
- Modify: `app/controllers/profiles_controller.rb:7,98-108,154-164,191-193`
- Modify: `app/components/profiles/activity_tabs.rb:14-20`
- Rewrite: `app/views/profiles/blog_list.rb`
- Modify: `app/views/profiles/show.rb:134-138`
- Modify: `config/locales/{en,ja,ko}.yml` (add `profiles.blog_list.empty`)
- Test: `test/controllers/profiles_controller_test.rb` (rework blog-tab tests)

**Interfaces:**
- Consumes: `post_permalink_path` (Task 1) via `PostCard` (Task 2); `Components::Posts::PostCard`, `Components::Pagination`, `Components::Profiles::ActivityTabs`.
- Produces: `Views::Profiles::BlogList.new(user:, posts:, pagy:, liked_post_ids:, boosted_post_ids:, embedded:)` public reading list; `ProfilesController#blog` sets `@posts, @pagy, @liked_post_ids, @boosted_post_ids`.

- [ ] **Step 1: Add the public empty-state i18n key**

Under `profiles.blog_list:` in each locale add an `empty:` key.

`config/locales/ko.yml` (after `trash_empty:` at line 337):
```yaml
      empty: 아직 발행한 블로그 글이 없습니다.
```
`config/locales/en.yml` (same `profiles.blog_list` block):
```yaml
      empty: No published blog posts yet.
```
`config/locales/ja.yml` (same block):
```yaml
      empty: まだ公開されたブログ記事がありません。
```

- [ ] **Step 2: Rewrite the blog-tab tests (write failing tests first)**

In `test/controllers/profiles_controller_test.rb`:

Delete these owner-only/management tests (they move to Task 4): "owner blog tab shows draft management entry", "owner blog draft entry offers a delete control", "blog drafts exclude trashed drafts", "owner blog trash section lists discarded blog posts", "owner blog trash section shows empty state when nothing discarded", and "blog tab requires the owner".

Replace "owner blog tab lists published blog posts" and "blog tab is hidden from other users" with public-behavior tests:

```ruby
  test "public blog tab lists published blog posts to anyone" do
    get user_profile_blog_url(username: users(:john).username)

    assert_response :success
    assert_includes response.body, posts(:blog_published).title
    assert_select "a[href=?]", user_profile_blog_post_path(username: users(:john).username, slug: posts(:blog_published))
  end

  test "public blog tab excludes drafts and trash" do
    posts(:blog_published).discard!

    get user_profile_blog_url(username: users(:john).username)

    assert_response :success
    assert_not_includes response.body, posts(:blog_draft).title
    assert_not_includes response.body, posts(:blog_published).title
  end

  test "blog tab is visible to other users" do
    sign_in users(:jane)

    get user_profile_posts_url(username: users(:john).username)

    assert_response :success
    assert_includes response.body, user_profile_blog_path(username: users(:john).username)
  end
```

Keep "owner profile shows blog tab" as-is (still passes).

- [ ] **Step 3: Run to verify failure**

Run: `mise x -- bin/rails test test/controllers/profiles_controller_test.rb -n "/public blog tab|blog tab is visible/"`
Expected: FAIL (blog action still redirects non-owners; BlogList still management markup).

- [ ] **Step 4: Make `ProfilesController#blog` public**

In `app/controllers/profiles_controller.rb`:

Add `:blog` to the public actions on line 7:
```ruby
  skip_before_action :authenticate_user!, only: [ :show, :posts, :comments, :blog ]
```

Replace the `blog` action (lines 98-108) with:
```ruby
  def blog
    @pagy, @posts = pagy(
      @user.posts.published_blog.kept
        .includes(:user, :federails_actor, :article, :tags)
        .order(published_at: :desc)
    )
    @liked_post_ids = liked_ids_for_posts(@posts)
    @boosted_post_ids = boosted_ids_for_posts(@posts)
    render_activity_page(:blog)
  end
```

Replace the `when :blog` branch in `render_activity_page` (lines 154-164) with:
```ruby
      when :blog
        if turbo_frame_request?
          render Views::Profiles::BlogList.new(
            user: @user, posts: @posts, pagy: @pagy,
            liked_post_ids: @liked_post_ids,
            boosted_post_ids: @boosted_post_ids
          )
        else
          render_show_with_activity(active_tab: :blog)
        end
```

In `render_show_with_activity` remove the now-unused `blog_drafts:/blog_published:/blog_trash:` keyword args (lines 191-193).

- [ ] **Step 5: Make the blog tab always visible**

In `app/components/profiles/activity_tabs.rb`, move the blog tab line out of the `own_profile?` group. Replace lines 14-20 so `posts`, `comments`, `blog` are unconditional and only followers/following/likes/boosts stay guarded:

```ruby
        tab_link(t("profiles.activity_tabs.posts"), user_profile_posts_path(username: @user.username), :posts)
        tab_link(t("profiles.activity_tabs.comments"), user_profile_comments_path(username: @user.username), :comments)
        tab_link(t("profiles.activity_tabs.blog"), user_profile_blog_path(username: @user.username), :blog)
        tab_link(t("profiles.activity_tabs.followers"), user_profile_followers_path(username: @user.username), :followers) if own_profile?
        tab_link(t("profiles.activity_tabs.following"), user_profile_following_path(username: @user.username), :following) if own_profile?
        tab_link(t("profiles.activity_tabs.likes"), user_profile_likes_path(username: @user.username), :likes) if own_profile?
        tab_link(t("profiles.activity_tabs.boosts"), user_profile_boosts_path(username: @user.username), :boosts) if own_profile?
```

- [ ] **Step 6: Rewrite `Views::Profiles::BlogList` as a public reading list**

Replace the entire contents of `app/views/profiles/blog_list.rb` with (mirrors `PostList`):

```ruby
# frozen_string_literal: true

class Views::Profiles::BlogList < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::TurboFrameTag

  def initialize(user:, posts:, pagy:, liked_post_ids: [], boosted_post_ids: [], embedded: false)
    @user = user
    @posts = posts
    @pagy = pagy
    @liked_post_ids = liked_post_ids
    @boosted_post_ids = boosted_post_ids
    @embedded = embedded
  end

  def view_template
    if @embedded
      list_content
    else
      content_for :title, "@#{@user.username} — #{t("profiles.activity_tabs.blog")}"
      div(class: "max-w-2xl mx-auto py-10 px-4 sm:px-6") do
        turbo_frame_tag("activity-list", class: "block") do
          render Components::Profiles::ActivityTabs.new(user: @user, active_tab: :blog)
          div(class: "mt-4") { list_content }
        end
      end
    end
  end

  private

  def list_content
    if @posts.empty?
      div(class: "text-center py-16 text-content-disabled") do
        p { t("profiles.blog_list.empty") }
      end
    else
      div(class: "flex flex-col gap-4") do
        div(class: "flex flex-col gap-3") do
          @posts.each do |post|
            render Components::Posts::PostCard.new(
              post: post,
              liked: @liked_post_ids.include?(post.id),
              boosted: @boosted_post_ids.include?(post.id)
            )
          end
        end
        render Components::Pagination.new(pagy: @pagy)
      end
    end
  end
end
```

- [ ] **Step 7: Update the Show view's embedded blog render**

In `app/views/profiles/show.rb` replace the `when :blog` branch (lines 134-138) with:

```ruby
    when :blog
      render Views::Profiles::BlogList.new(
        user: @user, posts: @posts || [], pagy: @pagy,
        liked_post_ids: @liked_post_ids,
        boosted_post_ids: @boosted_post_ids, embedded: true
      )
```

- [ ] **Step 8: Run tests to verify pass**

Run: `mise x -- bin/rails test test/controllers/profiles_controller_test.rb`
Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add app/controllers/profiles_controller.rb app/components/profiles/activity_tabs.rb app/views/profiles/blog_list.rb app/views/profiles/show.rb config/locales/en.yml config/locales/ja.yml config/locales/ko.yml test/controllers/profiles_controller_test.rb
git commit -m "feat: public blog index tab at /@user/blog"
```

---

### Task 4: Blog management at `/account/blog`

Move the drafts/published/trash management UI (removed from the profile tab in Task 3) to an authenticated `/account/blog` page, linked from account settings.

**Files:**
- Modify: `app/controllers/blog_posts_controller.rb` (add `#index`; redirects at lines 96,106)
- Create: `app/views/blog_posts/index.rb`
- Modify: `app/views/users/edit.rb` (add management link)
- Modify: `config/locales/{en,ja,ko}.yml` (`posts.blog.manage_*`, `users.edit.blog_link`)
- Test: `test/controllers/blog_posts_controller_test.rb` (index tests + redirect updates)

**Interfaces:**
- Consumes: `account_blog_path` route (Task 1); existing `edit_blog_post_path`, `blog_post_path`, `undiscard_blog_post_path`, `destroy_permanently_blog_post_path`, `post_permalink_path`.
- Produces: `BlogPostsController#index` (sets `@drafts, @published, @trash` for `current_user`); `Views::BlogPosts::Index.new(user:, drafts:, published:, trash:)`.

- [ ] **Step 1: Add management i18n keys**

`config/locales/ko.yml` under `posts.blog:` (after `read_more:` line 282):
```yaml
      manage_title: 블로그 글 관리
      manage_heading: 블로그 글 관리
```
under `users.edit:` (after `title:` line 379):
```yaml
      blog_link: 블로그 글 관리
```
`config/locales/en.yml` (`posts.blog`):
```yaml
      manage_title: Manage blog posts
      manage_heading: Manage blog posts
```
`en.yml` (`users.edit`):
```yaml
      blog_link: Manage blog posts
```
`config/locales/ja.yml` (`posts.blog`):
```yaml
      manage_title: ブログ記事の管理
      manage_heading: ブログ記事の管理
```
`ja.yml` (`users.edit`):
```yaml
      blog_link: ブログ記事の管理
```

- [ ] **Step 2: Write failing index + redirect tests**

In `test/controllers/blog_posts_controller_test.rb` update the two redirect assertions:

- "undiscard restores a discarded post for the owner" (line 230): `assert_redirected_to account_blog_url`
- "destroy_permanently removes the row for the owner" (line 269): `assert_redirected_to account_blog_url`

Then append the management tests (moved from the profiles test in Task 3):

```ruby
  test "index requires authentication" do
    get account_blog_url

    assert_redirected_to new_user_session_url
  end

  test "index shows the owner's drafts with edit and delete controls" do
    sign_in @user

    get account_blog_url

    assert_response :success
    assert_includes response.body, I18n.t("profiles.blog_list.drafts_heading")
    assert_includes response.body, @draft.title
    assert_select "a[href=?]", edit_blog_post_path(@draft)
    assert_select "form[action=?]", blog_post_path(@draft)
  end

  test "index lists published posts linking to the public permalink" do
    sign_in @user

    get account_blog_url

    assert_response :success
    assert_includes response.body, @published.title
    assert_select "a[href=?]", user_profile_blog_post_path(username: @user.username, slug: @published)
  end

  test "index drafts exclude trashed drafts and offer restore" do
    sign_in @user
    @draft.discard!

    get account_blog_url

    assert_response :success
    assert_select "form[action=?]", undiscard_blog_post_path(@draft)
    assert_select "a[href=?]", edit_blog_post_path(@draft), count: 0
  end

  test "index trash section lists discarded published posts with restore and destroy" do
    sign_in @user
    @published.discard!

    get account_blog_url

    assert_response :success
    assert_select "form[action=?]", undiscard_blog_post_path(@published)
    assert_select "form[action=?]", destroy_permanently_blog_post_path(@published)
  end

  test "index trash section shows empty state when nothing discarded" do
    sign_in @user

    get account_blog_url

    assert_response :success
    assert_includes response.body, I18n.t("profiles.blog_list.trash_empty")
  end
```

- [ ] **Step 3: Run to verify failure**

Run: `mise x -- bin/rails test test/controllers/blog_posts_controller_test.rb -n "/index |undiscard restores|destroy_permanently removes/"`
Expected: FAIL (`#index` action / view missing, redirects still to `user_profile_blog_url`).

- [ ] **Step 4: Add `BlogPostsController#index` and update redirects**

In `app/controllers/blog_posts_controller.rb`, add the action (after the `before_action`s; `#index` needs no `set_post`). Insert above `def new` (line 16):

```ruby
  def index
    @drafts    = current_user.posts.blog.draft.kept.order(updated_at: :desc)
    @published = current_user.posts.blog.published.kept.order(published_at: :desc)
    @trash     = current_user.posts.blog.discarded.order(updated_at: :desc)
    render Views::BlogPosts::Index.new(
      user: current_user, drafts: @drafts, published: @published, trash: @trash
    )
  end
```

Change the two management redirects:
- line 96 (`#undiscard`): `redirect_to account_blog_path, notice: t("posts.blog.restored")`
- line 106 (`#destroy_permanently`): `redirect_to account_blog_path, notice: t("posts.blog.destroyed_permanently")`

- [ ] **Step 5: Create the management view**

Create `app/views/blog_posts/index.rb` with the management markup moved out of the old `BlogList` (drafts/published/trash rows + edit/delete/restore/destroy controls), rendered standalone (no ActivityTabs). The published row links to the public permalink:

```ruby
# frozen_string_literal: true

class Views::BlogPosts::Index < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(user:, drafts: [], published: [], trash: [])
    @user = user
    @drafts = drafts
    @published = published
    @trash = trash
  end

  def view_template
    content_for :title, t("posts.blog.manage_title")
    div(class: "max-w-2xl mx-auto py-10 px-4 sm:px-6") do
      div(class: "mb-6 px-1") do
        render RubyUI::Heading.new(level: 1, class: "text-2xl font-bold text-content tracking-tight") { t("posts.blog.manage_heading") }
      end
      div(class: "flex flex-col gap-8") do
        drafts_section
        published_section
        trash_section
      end
    end
  end

  private

  def drafts_section
    section(class: "flex flex-col gap-3") do
      h2(class: "text-sm font-semibold text-content") { t("profiles.blog_list.drafts_heading") }
      drafts = @drafts.to_a
      if drafts.empty?
        empty_state(t("profiles.blog_list.drafts_empty"))
      else
        div(class: "flex flex-col gap-2") { drafts.each { |d| draft_row(d) } }
      end
    end
  end

  def published_section
    section(class: "flex flex-col gap-3") do
      h2(class: "text-sm font-semibold text-content") { t("profiles.blog_list.published_heading") }
      published = @published.to_a
      if published.empty?
        empty_state(t("profiles.blog_list.published_empty"))
      else
        div(class: "flex flex-col gap-2") { published.each { |p| published_row(p) } }
      end
    end
  end

  def trash_section
    section(class: "flex flex-col gap-3") do
      h2(class: "text-sm font-semibold text-content") { t("profiles.blog_list.trash_heading") }
      trash = @trash.to_a
      if trash.empty?
        empty_state(t("profiles.blog_list.trash_empty"))
      else
        div(class: "flex flex-col gap-2") { trash.each { |p| trash_row(p) } }
      end
    end
  end

  def empty_state(message)
    div(class: "text-center py-8 text-content-disabled") { p { message } }
  end

  def draft_row(draft)
    row do
      link_to(edit_blog_post_path(draft),
        class: "min-w-0 flex-1 truncate text-sm text-content hover:text-brand-text transition-colors",
        data: { turbo_prefetch: false }) do
        plain draft.title.presence || t("posts.blog.untitled_draft")
      end
      div(class: "flex items-center gap-2 shrink-0") do
        button_to t("posts.blog.delete"), blog_post_path(draft),
          method: :delete,
          form: { data: { turbo_confirm: t("posts.blog.delete_confirm") } },
          class: "text-xs font-medium text-content-muted hover:text-danger-text transition-colors cursor-pointer"
      end
    end
  end

  def published_row(post)
    row do
      link_to(post_permalink_path(post),
        class: "min-w-0 flex-1 truncate text-sm text-content hover:text-brand-text transition-colors") do
        plain post.title.presence || t("posts.blog.untitled_draft")
      end
      div(class: "flex items-center gap-2 shrink-0") do
        link_to t("posts.blog.edit"), edit_blog_post_path(post),
          class: "text-xs font-medium text-content-muted hover:text-content transition-colors",
          data: { turbo_prefetch: false }
        button_to t("posts.blog.delete"), blog_post_path(post),
          method: :delete,
          form: { data: { turbo_confirm: t("posts.blog.delete_confirm") } },
          class: "text-xs font-medium text-content-muted hover:text-danger-text transition-colors cursor-pointer"
      end
    end
  end

  def trash_row(post)
    row do
      span(class: "min-w-0 flex-1 truncate text-sm text-content") do
        plain post.title.presence || t("posts.blog.untitled_draft")
      end
      div(class: "flex items-center gap-2 shrink-0") do
        button_to t("posts.blog.restore"), undiscard_blog_post_path(post),
          method: :patch,
          class: "text-xs font-medium text-content-muted hover:text-content transition-colors cursor-pointer"
        button_to t("posts.blog.destroy_permanently"), destroy_permanently_blog_post_path(post),
          method: :delete,
          form: { data: { turbo_confirm: t("posts.blog.destroy_permanently_confirm") } },
          class: "text-xs font-medium text-content-muted hover:text-danger-text transition-colors cursor-pointer"
      end
    end
  end

  def row(&block)
    div(class: "flex items-center justify-between gap-3 rounded-md border border-border-muted bg-app/40 px-3 py-2", &block)
  end
end
```

- [ ] **Step 6: Add the management link to account settings**

In `app/views/users/edit.rb`, add a link to `account_blog_path` after the form (inside the outer `div`, after `render Components::Users::Form...` on line 20):

```ruby
      div(class: "mt-6 px-1") do
        link_to t("users.edit.blog_link"), account_blog_path,
          class: "text-sm font-medium text-accent-text hover:underline"
      end
```

Add `include Phlex::Rails::Helpers::LinkTo` to the class includes (after line 5).

- [ ] **Step 7: Run tests to verify pass**

Run: `mise x -- bin/rails test test/controllers/blog_posts_controller_test.rb`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add app/controllers/blog_posts_controller.rb app/views/blog_posts/index.rb app/views/users/edit.rb config/locales/en.yml config/locales/ja.yml config/locales/ko.yml test/controllers/blog_posts_controller_test.rb
git commit -m "feat: move blog management to /account/blog"
```

---

### Task 5: Update the blog system test end-to-end

The system flow still assumes blog management/detail live at the old URLs; point it at the new public detail and `/account/blog`.

**Files:**
- Modify: `test/system/blog_posts_test.rb:53,61`

**Interfaces:**
- Consumes: `account_blog_path`, `user_profile_blog_post_path` (Tasks 1,4).

- [ ] **Step 1: Point draft management at /account/blog**

In `test/system/blog_posts_test.rb`, in "owner re-opens a draft, edits, and deletes a published post", change line 53:

```ruby
    visit account_blog_path
```

- [ ] **Step 2: Point the delete flow at the public blog detail**

In the same test, change line 61:

```ruby
    visit user_profile_blog_post_path(username: @user.username, slug: posts(:blog_published))
```

- [ ] **Step 3: Run the system test**

Run: `mise x -- bin/rails test:system test/system/blog_posts_test.rb`
Expected: PASS (create/publish/read flow + draft-edit + delete flow all green).

- [ ] **Step 4: Run the full affected suite**

Run: `mise x -- bin/rails test test/controllers/posts_controller_test.rb test/controllers/blog_posts_controller_test.rb test/controllers/profiles_controller_test.rb`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add test/system/blog_posts_test.rb
git commit -m "test: update blog system flow for new blog URLs"
```

---

## Notes / Rationale

- **Why reuse `viewable?`:** the blog-detail branch fetches `user.posts.blog` (any status) then applies `viewable?`, preserving owner draft-preview at `/@user/blog/:slug` while 404ing drafts/discarded for everyone else — identical semantics to today's `/posts/:slug`.
- **Why keep `post_permalink_path` on `Components::Base`:** both `PostCard` and `Views::BlogPosts::Index` need it, and route helpers are already mixed in there; the reply job can't use it and branches inline instead.
- **Destructive `/posts/:slug` for blog:** accepted because only one blog post exists; no redirect/back-compat needed.
