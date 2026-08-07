# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

module FunctionLogger
  # Rails 8의 Rails.logger는 BroadcastLogger(로거 팬아웃 래퍼)다.
  #: () -> ActiveSupport::BroadcastLogger
  def logger
    Rails.logger
  end
end
