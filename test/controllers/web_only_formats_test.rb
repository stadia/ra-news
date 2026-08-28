# frozen_string_literal: true

require "test_helper"

# HTML 전용 엔드포인트가 JSON 요청에 200 + HTML로 답하던 회귀를 막는다.
#
# 이 컨트롤러들은 `render Views::Foo.new(...)`로 Phlex 뷰를 **명시적으로**
# 렌더링한다. 일반 Rails `render`라면 `.json` 템플릿이 없어 UnknownFormat이
# 나지만 명시 렌더링에는 그 안전망이 없어, 클라이언트가 JSON 성공으로 오인한 뒤
# 파싱에서 깨졌다. `WebOnlyFormats`가 조회 전에 406으로 끊는다.
class WebOnlyFormatsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    @article = articles(:ruby_article)
    @post = Post.create!(body: "web only formats post", user: @user)
  end

  def html_only_paths
    {
      "home#index" => "/",
      "home#about" => "/about",
      "home#terms" => "/terms",
      "home#privacy_policy" => "/privacy-policy",
      "articles#index" => "/articles",
      "articles#show" => "/articles/#{@article.to_param}",
      "articles#others" => "/others",
      "articles#new" => "/articles/new",
      "profiles#show" => "/@#{@user.username}",
      "profiles#posts" => "/@#{@user.username}/posts",
      "posts#show" => "/posts/#{@post.to_param}",
      "blog_posts#index" => "/account/blog",
      "blog_posts#new" => "/blog_posts/new",
      "actors#lookup" => "/actors/lookup"
    }
  end

  test "HTML 전용 엔드포인트는 Accept: application/json을 406으로 끊는다" do
    sign_in_as(@user)

    html_only_paths.each do |label, path|
      get path, as: :json

      assert_response :not_acceptable, "#{label} (#{path})이 JSON 요청에 #{response.status}로 답했다"
    end
  end

  test "HTML 전용 엔드포인트는 같은 경로의 HTML 요청에는 정상 응답한다" do
    sign_in_as(@user)

    html_only_paths.each do |label, path|
      get path

      assert_response :success, "#{label} (#{path})이 HTML 요청에 #{response.status}로 답했다"
      assert_equal "text/html", response.media_type, "#{label} (#{path})"
    end
  end

  test "의도적으로 비-HTML을 내놓는 엔드포인트는 그대로 둔다" do
    expected = {
      "/rss" => "application/rss+xml",
      "/llms.txt" => "text/plain",
      "/robots.txt" => "text/plain"
    }

    expected.each do |path, media_type|
      get path

      assert_response :success, path
      assert_equal media_type, response.media_type, path
    end
  end

  test "초안 자동저장 JSON은 계속 동작한다" do
    sign_in_as(@user)

    post blog_posts_path, params: { post: { body: "draft body" } }, as: :json

    assert_response :success
    assert_nothing_raised { JSON.parse(response.body) }
  end

  # 인증 실패(401)와 포맷 거부(406)의 순서를 고정한다. PostsController는 전역
  # `authenticate_user!`를 다시 등록해 체인 끝으로 옮기므로, 포맷 가드가 앞서면
  # 미인증 JSON 요청이 401 대신 406을 받게 된다.
  test "미인증 JSON 쓰기 요청은 포맷 거부보다 인증 실패가 먼저다" do
    post article_posts_url(@article, format: :json),
         params: { post: { body: "댓글" } },
         as: :json

    assert_response :unauthorized
    assert_equal "unauthorized", JSON.parse(response.body)["error"]
  end

  test "인증된 JSON 쓰기 요청은 부작용 없이 406으로 끊긴다" do
    sign_in_as(@user)

    assert_no_difference("Post.count") do
      post article_posts_url(@article), params: { post: { body: "댓글" } }, as: :json
    end

    assert_response :not_acceptable
  end

  test "articles#show의 .md 표현은 계속 제공된다" do
    get article_path(@article, format: :md)

    assert_response :success
    assert_equal "text/markdown", response.media_type
  end
end
