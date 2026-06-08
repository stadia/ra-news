# frozen_string_literal: true

class Views::LongformPosts::Edit < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo
  include PhlexIcons

  def initialize(post:)
    @post = post
  end

  def view_template
    content_for :title, t("posts.longform.edit_title")

    div(class: "max-w-4xl mx-auto py-8 px-4 sm:px-6 space-y-6") do
      link_to feed_path, class: "inline-flex items-center gap-1.5 text-sm text-content-muted hover:text-content transition-colors" do
        Hero::ArrowLeft(variant: :outline, class: "w-4 h-4")
        plain t("posts.show.back_to_feed")
      end

      h1(class: "sr-only") { t("posts.longform.edit_heading") }
      render Components::Posts::LongformEditor.new(post: @post)
    end
  end
end
