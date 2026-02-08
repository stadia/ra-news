# frozen_string_literal: true

class Components::Users::Form < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(user:)
    @user = user
  end

  def view_template
    form_with(model: @user, class: "contents", url: @user.persisted? ? user_path(@user) : users_path) do |form|
      if @user.errors.any?
        div(id: "error_explanation", class: "bg-red-500/10 text-red-400 px-3 py-2 font-medium rounded-md mt-3 border border-red-500/30") do
          h2 {
            pluralize(@user.errors.count, "error") + " prohibited this user from being saved:"
          }
          ul(class: "list-disc ml-6") {
            @user.errors.each do |error|
              li { error.full_message }
            end
          }
        end
      end

      div(class: "my-5") do
        form.label :email_address, class: "block font-medium mb-1 text-slate-300"
        form.text_field :email_address, class: input_classes(@user.errors[:email_address])
      end

      div(class: "my-5") do
        form.label :name, class: "block font-medium mb-1 text-slate-300"
        form.text_field :name, class: input_classes(@user.errors[:name])
      end

      div(class: "my-5") do
        form.label :password, class: "block font-medium mb-1 text-slate-300"
        form.password_field :password, class: input_classes(@user.errors[:password])
      end

      div(class: "my-5") do
        form.label :password_confirmation, class: "block font-medium mb-1 text-slate-300"
        form.password_field :password_confirmation, class: input_classes(@user.errors[:password_confirmation])
      end

      div(class: "inline") do
        form.submit class: "w-full sm:w-auto rounded-md px-3.5 py-2.5 bg-green-500 hover:bg-green-600 text-white inline-block font-medium cursor-pointer focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:ring-offset-slate-900"
      end
    end
  end

  private

  def input_classes(errors)
    base_classes = "block shadow-sm rounded-md border px-3 py-2 mt-2 w-full bg-slate-700 text-slate-100 placeholder-slate-400 focus:outline-none focus:ring-2 focus:border-transparent transition-colors duration-200"
    error_classes = errors.any? ? "border-red-500 focus:ring-red-500" : "border-slate-600 focus:ring-green-500"
    "#{base_classes} #{error_classes}"
  end
end
