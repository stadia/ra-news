# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

# Add your extra requires here (`bin/tapioca require` can be used to bootstrap this list)

# Boot the full Rails environment before tapioca's `eager_load_all!`.
# Engines such as solid_cache call `connects_to` while their models are being
# autoloaded, which raises AdapterNotSpecified unless the initializers that
# populate ActiveRecord::Base.configurations have already run.
require_relative "../../config/environment"
