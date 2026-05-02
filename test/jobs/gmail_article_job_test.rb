# frozen_string_literal: true

require "test_helper"

class GmailArticleJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "enqueue_all이 Site.kept.gmail의 ID를 예약한다" do
    assert_enqueued_with(job: GmailArticleJob, args: [Site.kept.gmail.order("id ASC").pluck(:id)]) do
      GmailArticleJob.enqueue_all
    end
  end

  test "GmailArticleJob은 LinkHelper를 포함한다" do
    assert_includes GmailArticleJob.ancestors, LinkHelper
  end
end