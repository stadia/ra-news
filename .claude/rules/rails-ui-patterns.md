# Design System

## Design System

### Colors
- **Success:** green — confirmations, positive feedback
- **Text:** gray-900/gray-700/gray-500
- **Backgrounds:** gray-50, gray-800, gray-700, green-100, green-900
- --color-red-300: `oklch(80.8% .114 19.571)`
- --color-red-400: `oklch(70.4% .191 22.216)`
- --color-red-500: `oklch(63.7% .237 25.331)`
- --color-red-600: `oklch(57.7% .245 27.325)`
- --color-red-700: `oklch(50.5% .213 27.518)`

### Components — Copy These Patterns
- **Alert:** `alert alert-danger`
- **Navigation:** `nav-group`
- **Card:** `bg-white p-6 rounded-lg shadow`
- **Link:** `hover:underline hover:text-content flex items-center gap-1`
- **Heading (page):** `text-3xl font-bold mb-6`
- **Heading (section):** `text-lg font-semibold text-gray-600`
- **Heading (sub):** `text-sm font-medium text-gray-900 dark:text-white mb-3`
- **Modal overlay:** `fixed inset-0 bg-app/75 z-50 hidden items-center justify-center`

### Typography
- **h1:** `text-3xl font-bold mb-6`
- **h2:** `text-lg font-semibold text-gray-600`
- **h3:** `text-sm font-medium text-gray-900 dark:text-white mb-3`
- Sizes: text-sm, text-3xl, text-lg, text-xs, text-xl
- Weights: font-bold, font-medium, font-semibold

### Layout & Spacing
- Container: max-w-7xl, container
- Grid: grid-cols-1, grid-cols-2, grid-cols-4
- Spacing: p-6, p-4, px-4, py-1, gap-3, px-6
- Form spacing: space-y-4

### Interactive States
- **hover:** hover:underline, hover:text-content, hover:text-blue-600
- **focus:** focus:not-sr-only, focus:absolute, focus:top-4

### Dark Mode
- Active — use `dark:` prefix for all color-dependent classes
- Common: dark:text-white, dark:text-gray-400, dark:border-gray-700, dark:bg-gray-800, dark:bg-gray-700

### When to Use What
- **Confirmation needed** → `data: { turbo_confirm: "Are you sure?" }` on `button_to`

### Design Rules
- Always add responsive breakpoints (mobile-first with md: and lg: variants)
- All interactive elements MUST have hover: and focus: states
- Use existing spacing scale: p-6, p-4, px-4, py-1
- Border radius: rounded-lg (card)
- Mirror all bg/text colors with dark: variants
- Reuse shared partials from app/views/shared/ before creating new markup


## Page Examples — Copy These Patterns

### Detail Page (comments/create.turbo_stream.erb)

```erb
<% if @comment.persisted? %>
  <% if @comment.parent_id.present? %>
    <%= turbo_stream.append "comment_replies_#{@comment.parent_id}" do %>
      <%= render(
        Components::Comments::Comment.new(
          comment: @comment,
          article: @article,
          depth: @comment.depth,
          children: {},
        ),
      ) %>
    <% end %>
  <% else %>
    <%= turbo_stream.prepend "comments_list" do %>
      <%= render(
        Components::Comments::Comment.new(
          comment: @comment,
          article: @article,
          depth: 0,
          children: {},
        ),
      ) %>
    <% end %>
  <% end %>

  <%= turbo_stream.update "comments_header" do %>
    <%= render(Components::Comments::CommentHeader.new(comments: @comments)) %>
  <% end %>

  <%= turbo_stream.update "comment_form" do %>
    <%= render(Components::Comments::CommentForm.new(article: @article, comment: Comment.new)) %>
  <% end %>
<% else %>
  <% if @comment.parent_id.present? && @comment.parent.present? %>
    <%= turbo_stream.replace "reply_form_#{@comment.parent_id}" do %>
      <%= render(Components::Comments::CommentReplyForm.new(article: @article, comment: @comment, parent_comment: @comment.parent, visible: true)) %>
    <% end %>
  <% else %>
    <%= turbo_stream.update "comment_form" do %>
      <%= render(Components::Comments::CommentForm.new(article: @article, comment: @comment)) %>
    <% end %>
  <% end %>
<% end %>
```

### List/Grid Page (madmin/dashboard/show.html.erb)

```erb
<div class="container mx-auto px-4 py-8">
  <h1 class="text-3xl font-bold mb-6">관리자 대시보드</h1>

  <!-- Key Metrics -->
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
    <div class="bg-white p-6 rounded-lg shadow">
      <h2 class="text-lg font-semibold text-gray-600">총 기사 수</h2>
      <p class="text-3xl font-bold"><%= @articles_count %></p>
    </div>
    <div class="bg-white p-6 rounded-lg shadow">
      <h2 class="text-lg font-semibold text-gray-600">총 사이트 수</h2>
      <p class="text-3xl font-bold"><%= @sites_count %></p>
    </div>
    <div class="bg-white p-6 rounded-lg shadow">
      <h2 class="text-lg font-semibold text-gray-600">총 사용자 수</h2>
      <p class="text-3xl font-bold"><%= @users_count %></p>
    </div>
    <div class="bg-white p-6 rounded-lg shadow">
      <h2 class="text-lg font-semibold text-gray-600">총 댓글 수</h2>
      <p class="text-3xl font-bold"><%= @comments_count %></p>
    </div>
  </div>

  <!-- Weekly Stats -->
  <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
    <div class="bg-white p-6 rounded-lg shadow">
      <h2 class="text-lg font-semibold text-gray-600">이번 주 새 기사</h2>
      <p class="text-3xl font-bold"><%= @weekly_articles %></p>
    </div>
    <div class="bg-white p-6 rounded-lg shadow">
      <h2 class="text-lg font-semibold text-gray-600">활성 RSS 사이트 (1주일)</h2>
      <p class="text-3xl font-bold"><%= @active_sites %></p>
    </div>
  </div>

  <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
    <!-- Recent Articles -->
    <div class="lg:col-span-2 bg-white p-6 rounded-lg shadow">
      <h2 class="text-xl font-bold mb-4">최신 기사</h2>
      <ul>
        <% @recent_articles.each do |article| %>
          <li class="border-b last:border-b-0 py-3">
            <p class="font-semibold"><%= link_to article.title, madmin_article_path(article), class: "hover:text-blue-600" %></p>
            <p class="text-sm text-gray-500"><%= article.site&.name %> - <%= time_ago_in_words(article.created_at) %> 전</p>
          </li>
        <% end %>
      </ul>
    </div>

    <!-- Popular Tags -->
    <div class="bg-white p-6 rounded-lg shadow">
      <h2 class="text-xl font-bold mb-4">인기 태그</h2>
      <table class="w-full text-sm text-left text-gray-500">
        <thead class="text-xs text-gray-700 uppercase bg-gray-50">
          <tr>
            <th scope="col" class="px-6 py-3">태그</th>
            <th scope="col" class="px-6 py-3">카운트</th>
          </tr>
        </thead>
        <tbody>
          <% @popular_tags.each do |tag| %>
            <tr class="bg-white border-b">
              <th scope="row" class="px-6 py-4 font-medium text-gray-900 whitespace-nowrap">
                <%= tag.name %>
              </th>
              <td class="px-6 py-4">
                <%= tag.taggings_count %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
  </div>

  <!-- Recent Comments -->
  <div class="mt-8 bg-white p-6 rounded-lg shadow">
    <h2 class="text-xl font-bold mb-4">최신 댓글</h2>
    <ul>
      <% @recent_comments.each do |comment| %>
```

## Responsive Breakpoints

- **sm:** text-center, mt-0
- **md:** flex, grid-cols-2, hidden, w-auto
- **lg:** grid-cols-4, grid-cols-3, col-span-2


## Helpers (ApplicationHelper)
- time_ago_in_words_korean
- responsive_image_tag
- truncate_smart
- nav_link_to

## Stimulus controllers
character_count, comment_form, guest_name, infinite_scroll, modal, page_loader, post_form, push_notifications, reply_form, ruby_ui-alert_dialog, ruby_ui-dialog, ruby_ui-form_field, ruby_ui-select, ruby_ui-select_item, ruby_ui-theme_toggle