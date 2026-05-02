# frozen_string_literal: true

require "test_helper"

class HackerNewsSiteJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "HackerNewsSiteJob은 ApplicationJob을 상속한다" do
    assert_includes HackerNewsSiteJob.ancestors, ActiveJob::Base
  end
end
