# frozen_string_literal: true

class Components::TagsSidebar < Components::Base
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::T
  include PhlexIcons

  def initialize(tags:, current_tag: nil)
    @tags = tags
    @current_tag = current_tag
  end

  def view_template
    aside(class: "tags-sidebar") do
      h3(class: "text-lg font-semibold text-content mb-4 flex items-center gap-2") do
        Hero::Tag(variant: :outline, class: "w-5 h-5 text-accent-text")
        plain t("tags_sidebar.heading")
      end

      render RubyUI::Card.new(class: "bg-surface p-4 border-border-strong hover:border-border-muted transition-colors rounded-lg") do
        if @tags.any?
          div(class: "flex flex-wrap gap-2") do
            @tags.each do |tag|
              tag_link(tag)
            end
          end
        else
          p(class: "text-sm text-content-muted") { t("tags_sidebar.empty") }
        end
      end
    end
  end

  private

  def tag_link(tag)
    active = @current_tag == tag.name
    classes = [
      "inline-flex items-center rounded-full border px-3 py-1.5 text-sm transition-colors",
      active ? "border-brand bg-brand-subtle text-content" : "border-border hover:border-brand/60 hover:bg-surface-muted text-content-secondary hover:text-content"
    ].join(" ")

    link_to tag_path(tag.name), class: classes do
      plain "##{tag.name}"
    end
  end
end
