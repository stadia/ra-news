# typed: true
# frozen_string_literal: true

require "test_helper"

class ApplicationRecordTest < ActiveSupport::TestCase
  test "ApplicationRecord는 ActiveRecord::Base를 상속한다" do
    assert_operator ApplicationRecord, :<, ActiveRecord::Base
  end
end
