module Madmin
  module ActiveStorage
    # Nested explicitly rather than `class ActiveStorage::AttachmentsController`:
    # that spelling is ambiguous between Madmin::ActiveStorage and the top-level
    # ::ActiveStorage engine.
    class AttachmentsController < Madmin::ResourceController
    end
  end
end
