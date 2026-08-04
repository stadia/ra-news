# typed: true
# frozen_string_literal: true

class Views::Likes::ToggleTurboStream < Views::Base
  include Phlex::Rails::Helpers::DOMID
  include Phlex::Rails::Helpers::TurboStream

  def initialize(likeable:)
    @likeable = likeable
  end

  def view_template
    turbo_stream.replace(dom_id(@likeable, :like)) do
      render Components::Likes::Button.new(likeable: @likeable)
    end
  end
end
