# frozen_string_literal: true

class Components::Users::User < Components::Base
  def initialize(user:)
    @user = user
  end

  def view_template
    div(id: dom_id(@user), class: "w-full sm:w-auto my-5 space-y-5") do
      div do
        strong(class: "block font-medium mb-1 text-slate-300") { "Email address:" }
        span(class: "text-slate-100") { @user.email_address }
      end
      div do
        strong(class: "block font-medium mb-1 text-slate-300") { "Name:" }
        span(class: "text-slate-100") { @user.name }
      end
      div do
        strong(class: "block font-medium mb-1 text-slate-300") { "Password:" }
        span(class: "text-slate-100") { @user.password }
      end
    end
  end
end
