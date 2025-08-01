# frozen_string_literal: true

require "test_helper"

class TwitterPostJobTest < ActiveJob::TestCase
  setup do
    @article = articles(:one)
    @ruby_article = Article.new(
      title: "Ruby 3.4 Performance Improvements",
      title_ko: "Ruby 3.4 성능 개선사항",
      url: "https://example.com/ruby-performance",
      origin_url: "https://example.com/ruby-performance",
      user: users(:one),
      site: sites(:one),
      is_related: true,
      summary_key: [ "Ruby 3.4에서 JIT 컴파일러가 크게 개선되었습니다.", "메모리 사용량이 20% 감소했습니다." ]
    )
    @ruby_article.save!
  end

  test "should skip non-ruby articles" do
    non_ruby_article = Article.create!(
      title: "JavaScript Framework",
      url: "https://example.com/js-framework",
      origin_url: "https://example.com/js-framework",
      user: users(:one),
      site: sites(:one),
      is_related: false
    )

    TwitterPostJob.perform_now(non_ruby_article.id)
    # Should not raise any errors and should skip posting
  end

  test "should skip articles without required content" do
    incomplete_article = Article.create!(
      title: "Ruby Article",
      url: "https://example.com/ruby-incomplete",
      origin_url: "https://example.com/ruby-incomplete",
      user: users(:one),
      site: sites(:one),
      is_related: true
      # Missing title_ko and summary_key
    )

    TwitterPostJob.perform_now(incomplete_article.id)
    # Should not raise any errors and should skip posting
  end

  test "should handle non-existent article gracefully" do
    TwitterPostJob.perform_now(99999) # Non-existent ID
    # Should not raise any errors
  end

  test "should_post_article? returns true for valid Ruby articles" do
    job = TwitterPostJob.new
    assert job.send(:should_post_article?, @ruby_article)
  end

  test "should_post_article? returns false for non-ruby articles" do
    @ruby_article.is_related = false
    job = TwitterPostJob.new
    assert_not job.send(:should_post_article?, @ruby_article)
  end

  test "should_post_article? returns false for articles without Korean title" do
    @ruby_article.title_ko = nil
    job = TwitterPostJob.new
    assert_not job.send(:should_post_article?, @ruby_article)
  end

  test "should_post_article? returns false for articles without summary" do
    @ruby_article.summary_key = nil
    job = TwitterPostJob.new
    assert_not job.send(:should_post_article?, @ruby_article)
  end

  test "build_tweet_text should handle normal length content" do
    job = TwitterPostJob.new
    tweet_text = job.send(:build_tweet_text, @ruby_article)

    expected_text = "Ruby 3.4 성능 개선사항\n\nRuby 3.4에서 JIT 컴파일러가 크게 개선되었습니다.\n\nhttps://example.com/ruby-performance"
    assert_equal expected_text, tweet_text
    assert tweet_text.length <= TwitterPostJob::TWITTER_CHARACTER_LIMIT
  end

  test "build_tweet_text should truncate long content properly" do
    long_title = "A" * 100
    long_summary = "B" * 200

    article_with_long_content = Article.new(
      title: "Original Title",
      title_ko: long_title,
      url: "https://example.com/very-long-url-that-would-normally-be-too-long-but-twitter-shortens-it",
      summary_key: [ long_summary ]
    )

    job = TwitterPostJob.new
    tweet_text = job.send(:build_tweet_text, article_with_long_content)

    # Should be truncated to fit Twitter's limit
    assert tweet_text.length <= TwitterPostJob::TWITTER_CHARACTER_LIMIT
    assert tweet_text.include?("...")  # Should contain truncation indicator
    assert tweet_text.include?(article_with_long_content.url)  # URL should always be included
  end

  test "build_tweet_text should use fallback title when Korean title is missing" do
    @ruby_article.title_ko = nil

    job = TwitterPostJob.new
    tweet_text = job.send(:build_tweet_text, @ruby_article)

    assert tweet_text.include?(@ruby_article.title)
  end

  test "build_tweet_text should use fallback summary when summary_key is empty" do
    @ruby_article.summary_key = []

    job = TwitterPostJob.new
    tweet_text = job.send(:build_tweet_text, @ruby_article)

    assert tweet_text.include?("새로운 Ruby 관련 글이 올라왔습니다.")
  end

  test "build_tweet_text should handle nil summary_key" do
    @ruby_article.summary_key = nil

    job = TwitterPostJob.new
    tweet_text = job.send(:build_tweet_text, @ruby_article)

    assert tweet_text.include?("새로운 Ruby 관련 글이 올라왔습니다.")
  end

  test "constants are defined correctly" do
    assert_equal 280, TwitterPostJob::TWITTER_CHARACTER_LIMIT
    assert_equal 23, TwitterPostJob::TWITTER_SHORTENED_URL_LENGTH
    assert_equal 4, TwitterPostJob::FORMATTING_BUFFER
  end

  test "URL length calculation uses fixed Twitter shortened length" do
    # Create article with very long URL
    long_url = "https://example.com/" + "x" * 200
    @ruby_article.url = long_url

    job = TwitterPostJob.new
    tweet_text = job.send(:build_tweet_text, @ruby_article)

    # The tweet should be built assuming URL is only 23 chars
    # So content should have more space available than if using actual URL length
    assert tweet_text.length <= TwitterPostJob::TWITTER_CHARACTER_LIMIT

    # Calculate expected max content length
    max_content_length = TwitterPostJob::TWITTER_CHARACTER_LIMIT -
                        TwitterPostJob::TWITTER_SHORTENED_URL_LENGTH -
                        TwitterPostJob::FORMATTING_BUFFER

    content_part = tweet_text.gsub(/\n\n#{Regexp.escape(long_url)}$/, "")
    assert content_part.length <= max_content_length
  end
end
