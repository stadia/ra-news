# frozen_string_literal: true

require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "GET index preloads liked articles for signed in user" do
    user = users(:john)
    articles = 10.times.map do |index|
      article = Article.new(
        title: "Indexed article #{index}",
        title_ko: "인덱스 기사 #{index}",
        url: "https://example.com/indexed-article-#{index}",
        origin_url: "https://example.com/indexed-article-#{index}",
        host: "example.com",
        slug: "indexed-article-#{index}",
        published_at: (20 - index).days.ago,
        created_at: (20 - index).days.ago,
        is_related: true,
        user: user,
        site: sites(:ruby_weekly)
      )
      article.stub(:generate_metadata, nil) { article.save! }
      article
    end
    article = articles.first
    Like.create!(liker: user, likeable: article, created_at: Time.current)
    sign_in_as(user)

    like_queries = capture_like_queries do
      get articles_path
    end

    assert_response :success
    assert_includes @response.body, article.title_ko
    assert_equal 1, like_queries.size
    assert_select "aside.tags-sidebar"
    assert_select "a[href='#{tag_path(tags(:ruby_tag).name)}']", text: /#ruby/
  end

  test "GET others preloads liked articles for signed in user" do
    user = users(:john)
    article = Article.new(
      title: "Other article",
      title_ko: "기타 기사",
      url: "https://example.com/other-article",
      origin_url: "https://example.com/other-article",
      host: "example.com",
      slug: "other-article",
      published_at: 10.days.ago,
      created_at: 10.days.ago,
      is_related: false,
      user: user,
      site: sites(:hn_site)
    )
    article.stub(:generate_metadata, nil) { article.save! }
    Like.create!(liker: user, likeable: article, created_at: Time.current)
    sign_in_as(user)

    like_queries = capture_like_queries do
      get others_path
    end

    assert_response :success
    assert_includes @response.body, "Other article"
    assert_equal 1, like_queries.size
    assert_select "aside.tags-sidebar"
    assert_select "a[href='#{tag_path(tags(:rails_tag).name)}']", text: /#rails/
  end

  test "GET tag filters articles by keyword" do
    article = articles(:ruby_article)
    article.tag_list.add("ruby")
    article.save!

    get tag_path("ruby")

    assert_response :success
    assert_select "h1", text: "#ruby"
    assert_select "#articlesList", text: /#{Regexp.escape(article.title_ko)}/
    assert_select "a[href='#{tag_path("ruby")}']", text: /#ruby/
  end

  test "GET tag supports dotted keywords" do
    article = articles(:ruby_article)
    article.tag_list.add("ruby-3.4")
    article.save!

    get tag_path("ruby-3.4")

    assert_response :success
    assert_select "h1", text: "#ruby-3.4"
    assert_select "#articlesList", text: /#{Regexp.escape(article.title_ko)}/
  end

  test "GET show returns 200 with article title" do
    article = articles(:ruby_article)
    get article_path(article)

    assert_response :success
    assert_select "article"
    assert_select "h1", text: /#{Regexp.escape(article.title_ko)}/
  end

  test "GET new renders intake form for authenticated user" do
    sign_in_as(users(:john))

    get new_article_path

    assert_response :success
    assert_select "h1", text: "새 글 등록"
    assert_select "form[action='#{articles_path}']"
    assert_select "input[name='article[url]']"
    assert_select "a[href='#{articles_path}']", text: "목록으로 돌아가기"
  end

  test "POST create without url rerenders form with validation errors" do
    sign_in_as(users(:john))

    post articles_path, params: { article: { url: "" } }

    assert_response :unprocessable_entity
    assert_select "#error_explanation"
    assert_select "#error_explanation li", text: /URL/
  end

  test "GET others renders pagination and push notification modal when multiple pages exist" do
    user = users(:john)

    35.times do |index|
      article = Article.new(
        title: "Paginated article #{index}",
        title_ko: "페이지 기사 #{index}",
        url: "https://example.com/paginated-article-#{index}",
        origin_url: "https://example.com/paginated-article-#{index}",
        host: "example.com",
        slug: "paginated-article-#{index}",
        published_at: (4.days + index.minutes).ago,
        created_at: (4.days + index.minutes).ago,
        is_related: false,
        user: user,
        site: sites(:ruby_weekly)
      )
      article.stub(:generate_metadata, nil) { article.save! }
    end

    WebPushConfig.stub(:configured?, true) do
      WebPushConfig.stub(:public_key, "test-public-key") do
        sign_in_as(user)
        get others_path

        assert_response :success
        assert_includes @response.body, "알림 설정"
        assert_includes @response.body, "나중에 하기"
        assert_includes @response.body, "First"
        assert_includes @response.body, "Prev"
        assert_includes @response.body, "Next"
        assert_includes @response.body, "Last"
      end
    end
  end

  private

  def capture_like_queries
    queries = []
    callback = lambda do |_name, _start, _finish, _id, payload|
      sql = payload[:sql]
      next unless sql&.include?('"likes"')
      next unless payload[:name] != "SCHEMA"

      queries << sql
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      yield
    end

    queries
  end
end
