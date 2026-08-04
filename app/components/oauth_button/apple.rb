# typed: true
# frozen_string_literal: true

class Components::OauthButton::Apple < Components::Base
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
          "inline-flex w-full items-center justify-center gap-2",
          "h-11 px-4 rounded-md cursor-pointer",
          "bg-black text-white",
          "font-medium text-[15px] leading-none",
          "hover:bg-[#1A1A1A] active:bg-[#2A2A2A]",
          "focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-black",
          "dark:bg-white dark:text-black dark:hover:bg-[#F2F2F2] dark:focus:ring-black dark:focus:ring-offset-white"
        ].join(" ")
      ) do
        apple_logo
        span { @label }
      end
    end
  end

  private

  def apple_logo
    svg(xmlns: "http://www.w3.org/2000/svg", viewbox: "0 0 170 170", width: "18", height: "18", aria_hidden: "true", fill: "currentColor") do |s|
      s.path(d: "M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.2-2.12-9.97-3.17-14.34-3.17-4.58 0-9.49 1.05-14.75 3.17-5.26 2.13-9.5 3.24-12.74 3.35-4.93.21-9.84-1.96-14.75-6.52-3.13-2.73-7.04-7.41-11.73-14.04-5.03-7.08-9.17-15.29-12.41-24.65-3.47-10.11-5.21-19.9-5.21-29.38 0-10.86 2.35-20.22 7.04-28.07 3.69-6.3 8.61-11.27 14.76-14.92 6.15-3.65 12.79-5.51 19.95-5.63 3.91 0 9.05 1.21 15.43 3.59 6.36 2.39 10.45 3.6 12.24 3.6 1.34 0 5.88-1.42 13.57-4.24 7.27-2.62 13.42-3.7 18.45-3.27 13.63 1.1 23.87 6.47 30.68 16.15-12.19 7.39-18.22 17.73-18.1 31 .11 10.34 3.86 18.94 11.23 25.77 3.34 3.17 7.07 5.62 11.22 7.36-.9 2.61-1.85 5.11-2.86 7.51zM119.11 7.24c0 8.1-2.96 15.67-8.86 22.67-7.12 8.32-15.73 13.13-25.07 12.37-.12-.97-.19-1.99-.19-3.07 0-7.78 3.39-16.1 9.4-22.91 3-3.45 6.82-6.31 11.45-8.6 4.62-2.25 8.99-3.5 13.1-3.71.12 1.08.17 2.17.17 3.24z")
    end
  end
end
