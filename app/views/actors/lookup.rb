# app/views/actors/lookup.rb
# frozen_string_literal: true

class Views::Actors::Lookup < Views::Base
  include Phlex::Rails::Helpers::ContentFor

  def view_template
    content_for :title, "팔로우 검색"

    div(class: "max-w-xl mx-auto py-8") do
      render RubyUI::Heading.new(level: 1) { "팔로우 검색" }
      p(class: "text-content-muted mt-2 mb-6") { "Fediverse 주소로 사용자를 검색하세요." }

      render RubyUI::Form.new(action: lookup_actors_url, method: :get, class: "flex gap-2 items-end") do
        render RubyUI::FormField.new(class: "flex-1") do
          render RubyUI::FormFieldLabel.new(for: "account", class: "text-content-secondary") { "계정 주소" }
          render RubyUI::Input.new(
            type: :text,
            name: "account",
            id: "account",
            placeholder: "user@domain.tld",
            required: true,
            autofocus: true,
            class: "bg-surface-muted border-border-muted text-content placeholder:text-content-muted"
          )
        end
        render RubyUI::Button.new(type: "submit", class: "bg-brand-solid hover:bg-brand-solid-hover text-brand-foreground") { "검색" }
      end
    end
  end
end
