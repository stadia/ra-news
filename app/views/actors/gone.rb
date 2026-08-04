# typed: true
# app/views/actors/gone.rb
# frozen_string_literal: true

class Views::Actors::Gone < Views::Base
  include Phlex::Rails::Helpers::ContentFor

  def view_template
    content_for :title, "Gone"

    div(class: "max-w-2xl mx-auto py-16 px-4 text-center") do
      render RubyUI::Heading.new(level: 1) { "410 Gone" }
      p(class: "text-content-muted mt-4") { t("actors.gone.message") }
    end
  end
end
