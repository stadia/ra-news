# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class OperationService < Dry::Operation
  #: () -> ActiveSupport::BroadcastLogger
  def logger
    Rails.logger
  end
end
