# typed: true
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

  test "last_checked_at은 수집 시작 시각으로 저장해 작업 중 발행된 스토리를 놓치지 않는다" do
    site = sites(:hn_site)
    site.update!(last_checked_at: 1.day.ago)

    started_at = Time.zone.now
    # 아이템 조회가 30분 걸리는 상황을 시뮬레이션한다
    slow_item = ->(_id) {
      travel 30.minutes
      { "type" => "story", "url" => "https://example.com/java-news",
        "title" => "Java news", "text" => "", "time" => Time.current.to_i }
    }

    travel_to started_at do
      HackerNews.stub(:new_stories, [ 1 ]) do
        HackerNews.stub(:item, slow_item) do
          HackerNewsSiteJob.perform_now
        end
      end
    end

    # 종료 시각(시작+30분)이 아니라 수집 시작 시각이 커서로 저장되어야 한다
    assert_in_delta started_at, site.reload.last_checked_at, 1
  end

  test "오래된 스토리를 만나면 수집을 중단한다 (break 경로)" do
    site = sites(:hn_site)
    site.update!(last_checked_at: Time.current)

    old_item = { "type" => "story", "url" => "https://example.com/old",
                 "title" => "Old", "text" => "", "time" => 1.day.ago.to_i }
    new_item = { "type" => "story", "url" => "https://example.com/new",
                 "title" => "New", "text" => "", "time" => Time.current.to_i }

    HackerNews.stub(:new_stories, [ 1, 2 ]) do
      HackerNews.stub(:item, ->(id) { id == 1 ? old_item : new_item }) do
        assert_no_difference "Article.count" do
          HackerNewsSiteJob.perform_now
        end
      end
    end

    # 첫 스토리가 오래되면 process_story가 false를 반환해 루프가 중단된다.
    # 뒤의 신규 스토리(2번)는 처리되지 않으므로 기사가 생성되지 않는다.
    assert_equal 0, Article.where(origin_url: "https://example.com/new").count
  end
end
