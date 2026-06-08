# frozen_string_literal: true

class Views::LongformPosts::Edit < Views::Base
  include Phlex::Rails::Helpers::ContentFor

  def initialize(post:)
    @post = post
  end

  def view_template
    content_for :title, t("posts.longform.edit_title")
    div(class: "max-w-3xl mx-auto py-8 px-4 sm:px-6") do
      h1(class: "text-3xl font-bold text-content") { t("posts.longform.edit_heading") }
      p(class: "mt-2 text-sm text-content-muted") { @post.title }
    end
  end
end
