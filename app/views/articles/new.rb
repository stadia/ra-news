# frozen_string_literal: true

class Views::Articles::New < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo

  attr_reader :article

  def initialize(article:)
     @article = article
  end

  def view_template
    content_for :title, "새 글 등록"
    div(class: "md:w-2/3 w-full") do
      h1(class: "font-bold text-4xl") { "새 글" }
      render Components::Articles::Form.new(article: article)
      link_to "목록으로 돌아가기",
              articles_path,
              class:
                "w-full sm:w-auto text-center mt-2 sm:mt-0 sm:ml-2 rounded-md px-3.5 py-2.5 bg-slate-700 hover:bg-slate-600 text-slate-100 inline-block font-medium focus:outline-none focus:ring-2 focus:ring-slate-500 focus:ring-offset-2 focus:ring-offset-slate-900"
    end
  end
end
