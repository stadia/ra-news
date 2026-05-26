# frozen_string_literal: true

require "test_helper"

class LayoutHreflangTest < ActiveSupport::TestCase
  test "한국어 hreflang 도메인은 ruby-news.dev이다" do
    assert_equal "https://ruby-news.dev", Components::Layout::HREFLANG_HOSTS.fetch("ko")
  end

  test "일본어 hreflang 도메인은 ruby-news.jp이다" do
    assert_equal "https://ruby-news.jp", Components::Layout::HREFLANG_HOSTS.fetch("ja")
  end
end
