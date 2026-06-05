# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @thumbnail_path = Rails.root.join("public/apple-touch-icon.png")
  end

  test "GET root renders successfully" do
    get root_path

    assert_response :success
    assert_select "h1.sr-only", text: /Ruby·Rails 개발자를 위한 한국어 AI 뉴스/
    assert_select "aside.recent-comments-sidebar"
    assert_select "aside.tags-sidebar"
    assert_select "a[href='#{tag_path(tags(:ruby_tag).name)}']", text: /#ruby/
    assert_select "a[href='https://github.com/stadia/ruby-news']", text: /GitHub/
  end

  test "GET root preloads liked articles for signed in user" do
    user = users(:john)
    Like.create!(actor: user.federails_actor, likeable: articles(:ruby_article), created_at: Time.current)
    sign_in_as(user)

    like_queries = capture_like_queries do
      get root_path
    end

    assert_response :success
    assert_equal 1, like_queries.size
  end

  test "GET root avoids per-record queries for thumbnails and recent comment authors" do
    queries = capture_queries do
      get root_path
    end

    assert_response :success
    assert_empty queries.grep(/FROM "active_storage_blobs" WHERE "active_storage_blobs"\."id" =/)
    assert_empty queries.grep(/FROM "active_storage_attachments" WHERE "active_storage_attachments"\."record_id" =/)
    assert_operator queries.grep(/FROM "users" WHERE "users"\."id" =/).size, :<=, 1
  end

  test "GET root renders featured article cards with hero summary string" do
    attach_thumbnail(articles(:ruby_article))
    attach_thumbnail(articles(:korean_content_article))
    attach_thumbnail(create_featured_article!(title: "Feature third", title_ko: "세 번째 주요 기사", slug: "feature-third", summary_key: "핵심 요약"))

    get root_path

    assert_response :success
    assert_select "section", text: /주요 뉴스/
    assert_select "img", minimum: 3
    assert_select "a[href='#{article_path(articles(:ruby_article))}']", text: /Ruby 3.4의 놀라운 새 기능들/
  end

  test "GET root renders featured hero summary array items" do
    attach_thumbnail(articles(:ruby_article))
    attach_thumbnail(articles(:korean_content_article))
    attach_thumbnail(create_featured_article!(
      title: "Array feature",
      title_ko: "배열 요약 주요 기사",
      slug: "array-feature",
      summary_key: [ "첫 번째 요약", "두 번째 요약", "세 번째 요약" ],
      published_at: 1.minute.from_now
    ))

    get root_path

    assert_response :success
    assert_select "li span", text: /첫 번째 요약/
    assert_select "li span", text: /두 번째 요약/
    assert_select "li span", text: /세 번째 요약/
  end

  test "GET about returns 200 with introduction content" do
    get about_path

    assert_response :success
    assert_select "h1", text: /Ruby-News 소개/
  end

  test "GET privacy policy returns 200 with privacy content" do
    get privacy_policy_path

    assert_response :success
    assert_select "h1", text: /개인정보처리방침/
  end

  test "GET terms returns 200 with terms content" do
    get terms_path

    assert_response :success
    assert_select "h1", text: /이용약관/
  end

  private

  def capture_like_queries(&block)
    capture_queries(&block).select { |sql| sql.include?('"likes"') }
  end

  def capture_queries(&block)
    queries = []
    callback = lambda do |_name, _start, _finish, _id, payload|
      sql = payload[:sql]
      next unless sql
      next if payload[:name] == "SCHEMA"

      queries << sql
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      block.call
    end

    queries
  end

  def attach_thumbnail(article)
    article.thumbnail.attach(
      io: File.open(@thumbnail_path),
      filename: "#{article.slug || article.id}.png",
      content_type: "image/png"
    )
  end

  def create_featured_article!(title:, title_ko:, slug:, summary_key:, published_at: Time.current)
    article = Article.new(
      title: title,
      title_ko: title_ko,
      url: "https://example.com/#{slug}",
      origin_url: "https://example.com/#{slug}",
      host: "example.com",
      slug: slug,
      published_at: published_at,
      is_related: true,
      summary_key: summary_key,
      user: users(:john),
      site: sites(:ruby_weekly)
    )

    article.stub(:generate_metadata, nil) { article.save! }
    article
  end
end
