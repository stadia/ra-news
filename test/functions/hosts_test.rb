# frozen_string_literal: true

require "test_helper"

class HostsTest < ActiveSupport::TestCase
  test "INDEX_NOW_KEY는 public 키 파일명과 일치하는 문자열이다" do
    assert_equal "187d5ed120cc45f8869b89302011d43a", Hosts::INDEX_NOW_KEY
    assert File.exist?(Rails.public_path.join("#{Hosts::INDEX_NOW_KEY}.txt"))
  end

  test "INDEX_NOW_HOSTS는 FOR_LOCALE에서 파생된 호스트 목록이다" do
    assert_equal %w[ruby-news.dev ruby-news.jp], Hosts::INDEX_NOW_HOSTS
  end
end
