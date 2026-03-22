# frozen_string_literal: true

require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "GET index preloads liked articles for signed in user" do
    user = users(:john)
    articles = 10.times.map do |index|
      Article.create!(
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
  end

  test "GET others preloads liked articles for signed in user" do
    user = users(:john)
    article = Article.create!(
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
    Like.create!(liker: user, likeable: article, created_at: Time.current)
    sign_in_as(user)

    like_queries = capture_like_queries do
      get others_path
    end

    assert_response :success
    assert_includes @response.body, "Other article"
    assert_equal 1, like_queries.size
  end

  test "GET show returns 200 with article title" do
    article = articles(:ruby_article)
    get article_path(article)

    assert_response :success
    assert_select "article"
    assert_select "h1", text: /#{Regexp.escape(article.title_ko)}/
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
