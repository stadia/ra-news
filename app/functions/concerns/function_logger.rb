# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

module FunctionLogger
  #: () -> ActiveSupport::Logger
  def logger
    Rails.logger
  end
end
