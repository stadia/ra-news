# typed: true
# frozen_string_literal: true

require "test_helper"

class ApplicationMailerTest < ActionMailer::TestCase
  test "default from 주소가 설정되어 있다" do
    assert_equal "bot@ruby-news.dev", ApplicationMailer.default[:from]
  end
end
