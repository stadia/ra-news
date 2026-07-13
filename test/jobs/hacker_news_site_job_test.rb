# frozen_string_literal: true

require "test_helper"

class HackerNewsSiteJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "HackerNewsSiteJob은 ApplicationJob을 상속한다" do
    assert_includes HackerNewsSiteJob.ancestors, ActiveJob::Base
  end

  test "URI.parse가 실패하는 잘못된 URL 아이템은 스킵하고 job은 끝까지 진행한다" do
    site = sites(:hn_site)
    # 공백이 포함된 URL은 URI.parse가 URI::InvalidURIError를 던진다
    invalid_item = { "type" => "story", "url" => "http://exa mple.com/x",
                     "title" => "Ruby news", "text" => "", "time" => Time.current.to_i }

    HackerNews.stub(:new_stories, [ 1 ]) do
      HackerNews.stub(:item, ->(_id) { invalid_item }) do
        assert_no_difference "Article.count" do
          assert_nothing_raised { HackerNewsSiteJob.perform_now }
        end
      end
    end

    # 잘못된 URL은 next로 스킵되고 루프가 끝나 last_checked_at이 갱신된다(끝까지 진행)
    assert_operator site.reload.last_checked_at, :>, 5.minutes.ago
  end
end
