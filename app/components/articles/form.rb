# frozen_string_literal: true

class Components::Articles::Form < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(article:)
    @article = article
  end

  def view_template
     form_with(model: @article, class: "contents") do |form|
       if @article.errors.any?
         div(id: "error_explanation", class: "bg-red-50 text-red-500 px-3 py-2 font-medium rounded-md mt-3") do
           h2 {
             pluralize(article.errors.count, "error") + " prohibited this article from being saved:"
           }
           ul(class: "list-disc ml-6") {
             @article.errors.each do |error|
               li { error.full_message }
             end
           }
         end
       end

       div(class: "my-5") do
         form.label :url
         form.text_field :url, class: [ "block shadow-sm rounded-md border px-3 py-2 mt-2 w-full bg-white text-gray-900", { "border-gray-400 focus:outline-blue-600": @article.errors[:url].none?, "border-red-400 focus:outline-red-600": @article.errors[:url].any? } ]
       end

       div(class: "inline") do
         form.submit class: "w-full sm:w-auto rounded-md px-3.5 py-2.5 bg-blue-600 hover:bg-blue-500 text-white inline-block font-medium cursor-pointer"
       end
     end
   end
end
