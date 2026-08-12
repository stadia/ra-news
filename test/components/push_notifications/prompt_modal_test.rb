# frozen_string_literal: true

require "test_helper"

class PushNotificationsPromptModalTest < ActiveSupport::TestCase
  test "설정 버튼이 primary 텍스트 색상을 덮어쓰지 않는다" do
    source = Rails.root.join("app/components/push_notifications/prompt_modal.rb").read

    assert_not_includes source, "text-link"
    assert_not_includes source, "hover:text-link-hover"
  end

  test "설정 버튼이 분할형 모달의 모서리를 둥글게 만들지 않는다" do
    source = Rails.root.join("app/components/push_notifications/prompt_modal.rb").read

    assert_includes source, "class: \"w-full font-semibold rounded-none\""
  end
end
