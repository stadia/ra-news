# frozen_string_literal: true

class Components::Articles::Form < Components::Base
  include Phlex::Rails::Helpers::FormWith

  attr_reader :article

  def initialize(article:)
    @article = article
  end

  def view_template
     form_with(model: article, class: "contents") do |form|
       if article.errors.any?
         div(id: "error_explanation", class: "bg-red-500/10 text-red-400 px-3 py-2 font-medium rounded-md mt-3 border border-red-500/30") do
           h2 {
             pluralize(article.errors.count, "error") + " prohibited this article from being saved:"
           }
           ul(class: "list-disc ml-6") {
             article.errors.each do |error|
               li { error.full_message }
             end
           }
         end
       end

       div(class: "my-5") do
         form.label :url
         form.text_field :url, class: [ "block shadow-sm rounded-md border px-3 py-2 mt-2 w-full bg-slate-700 text-slate-100 placeholder-slate-400 focus:outline-none focus:ring-2 focus:border-transparent transition-colors duration-200", { "border-slate-600 focus:ring-green-500": article.errors[:url].none?, "border-red-500 focus:ring-red-500": article.errors[:url].any? } ]
       end

       div(class: "inline") do
         form.submit class: "w-full sm:w-auto rounded-md px-3.5 py-2.5 bg-green-500 hover:bg-green-600 text-white inline-block font-medium cursor-pointer focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:ring-offset-slate-900"
       end
     end
   end
end
