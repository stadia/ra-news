# frozen_string_literal: true

# rbs_inline: enabled

class ApplicationService
  include ActiveModel::Model

  class << self
    def call(*args, **kwargs)
      new(*args, **kwargs).call
    end
  end

  def call
    raise NotImplementedError, "You must implement the call method"
  end
end
