# app/views/actors/lookup.rb
# frozen_string_literal: true

class Views::Actors::Lookup < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::FormTag
  include Phlex::Rails::Helpers::LabelTag

  def view_template
    content_for :title, "팔로우 검색"

    div(class: "max-w-xl mx-auto py-8") do
      render RubyUI::Heading.new(level: 1) { "팔로우 검색" }
      p(class: "text-slate-400 mt-2 mb-6") { "Fediverse 주소로 사용자를 검색하세요." }

      form_tag lookup_actors_url, method: :get, class: "flex gap-2 items-end" do
        div(class: "flex-1") do
          label_tag :account, "계정 주소", class: "block text-sm text-slate-400 mb-1"
          render RubyUI::Input.new(
            type: :text,
            name: "account",
            id: "account",
            placeholder: "user@domain.tld",
            required: true,
            autofocus: true
          )
        end
        render RubyUI::Button.new(type: "submit") { "검색" }
      end
    end
  end
end
