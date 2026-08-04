# typed: strong
# frozen_string_literal: true

require "test_helper"

class RedditTest < ActiveSupport::TestCase
  test "Reddit는 모듈이다" do
    assert_kind_of Module, Reddit
  end

  test "Reddit은 feed 싱글톤 메서드를 가진다" do
    assert_respond_to Reddit, :feed
  end

  test "BASE_URL 상수가 정의되어 있다" do
    assert_equal "https://www.reddit.com", Reddit::BASE_URL
  end

  test "SUBREDDIT 상수가 정의되어 있다" do
    assert_equal "ruby+rails", Reddit::SUBREDDIT
  end

  test "USER_AGENT 상수가 정의되어 있다" do
    assert_match(/ruby-news/, Reddit::USER_AGENT)
  end

  test "JSON API가 실패하면 Atom feed로 fallback한다" do
    atom_posts = [ { "title" => "Fallback post" } ]

    Reddit.stub(:fetch_json_posts, nil) do
      Reddit.stub(:fetch_atom_posts, atom_posts) do
        assert_equal atom_posts, Reddit.feed(limit: 1)
      end
    end
  end

  test "Atom content에서 외부 링크만 추출한다" do
    content = <<~HTML
      <a href="https://www.reddit.com/r/ruby/comments/abc/post/">[link]</a>
      <a href="https://example.com/post">[link]</a>
    HTML

    assert_equal "https://example.com/post", Reddit.send(:external_link_from_content, content)
  end
end
