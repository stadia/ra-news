# typed: true
# frozen_string_literal: true

class Components::OauthButton::Google < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(path:, label:)
    @path = path
    @label = label
  end

  def view_template
    form_with(url: @path, method: :post, data: { turbo: false }, class: "w-full sm:w-auto") do
      button(
        type: "submit",
        class: [
          "inline-flex w-full items-center justify-center gap-3",
          "h-10 px-3 rounded-md cursor-pointer",
          "border border-[#747775] bg-white text-[#1F1F1F]",
          "font-medium text-sm leading-none",
          "hover:bg-[#F8F9FA] active:bg-[#F1F3F4]",
          "focus:outline-none focus:ring-2 focus:ring-[#4285F4] focus:ring-offset-2",
          "dark:border-[#8E918F] dark:bg-[#131314] dark:text-[#E3E3E3] dark:hover:bg-[#1F1F1F]"
        ].join(" ")
      ) do
        google_logo
        span { @label }
      end
    end
  end

  private

  def google_logo
    svg(xmlns: "http://www.w3.org/2000/svg", viewbox: "0 0 24 24", width: "20", height: "20", aria_hidden: "true") do |s|
      s.path(d: "M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z", fill: "#4285F4")
      s.path(d: "M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z", fill: "#34A853")
      s.path(d: "M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z", fill: "#FBBC05")
      s.path(d: "M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z", fill: "#EA4335")
    end
  end
end
