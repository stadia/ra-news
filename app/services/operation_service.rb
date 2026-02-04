# frozen_string_literal: true

# rbs_inline: enabled

class OperationService < Dry::Operation
  def logger
    Rails.logger
  end
end
