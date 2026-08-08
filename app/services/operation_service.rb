# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

class OperationService < Dry::Operation
  # Deliberately untyped. Rails' own types say `Rails.logger` is an
  # ActiveSupport::BroadcastLogger, but rails_semantic_logger replaces it: at
  # runtime this returns a SemanticLogger::Logger, which is not a
  # BroadcastLogger and shares no ancestor with one below Object. Naming either
  # class would be a signature that is false in every environment or in none.
  #: () -> untyped
  def logger
    Rails.logger
  end
end
