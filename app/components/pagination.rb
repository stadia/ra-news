# frozen_string_literal: true

class Components::Pagination < Components::Base
  include PhlexIcons

  def initialize(pagy:)
    @pagy = pagy
  end

  def view_template
    return if @pagy.pages <= 1

    first_url = @pagy.page_url(:first)
    prev_url = @pagy.page_url(:previous)
    next_url = @pagy.page_url(:next)
    last_url = @pagy.page_url(:last)

    start_page, end_page = page_window

    render div(class: "pagy mt-auto") do
      render RubyUI::Pagination.new(class: "bg-surface rounded-xl p-2 md:p-3 border border-border-strong") do
        render RubyUI::PaginationContent.new do
          RubyUI::PaginationItem(href: first_url || "#", class: "hidden sm:inline-flex #{disabled_class(first_url)}") do
            Hero::ChevronDoubleLeft(variant: :outline, class: "h-4 w-4 mr-1")
            plain "First"
          end
          RubyUI::PaginationItem(href: prev_url || "#", class: disabled_class(prev_url)) do
            Hero::ChevronLeft(variant: :outline, class: "h-4 w-4 sm:mr-1")
            span(class: "hidden sm:inline") { "Prev" }
          end

          RubyUI::PaginationEllipsis if start_page > 1

          loop_items

          RubyUI::PaginationEllipsis if end_page < last_page

          RubyUI::PaginationItem(href: next_url || "#", class: disabled_class(next_url)) do
            span(class: "hidden sm:inline") { "Next" }
            Hero::ChevronRight(variant: :outline, class: "h-4 w-4 sm:ml-1")
          end
          RubyUI::PaginationItem(href: last_url || "#", class: "hidden sm:inline-flex #{disabled_class(last_url)}") do
            plain "Last"
            Hero::ChevronDoubleRight(variant: :outline, class: "h-4 w-4 ml-1")
          end
        end
      end
    end
  end

  def loop_items
    start_page, end_page = page_window
    current_page = @pagy.page

    (start_page..end_page).each do |page|
      RubyUI::PaginationItem(href: @pagy.page_url(page), active: page == current_page) { page.to_s }
    end
  end

  private

  def page_window
    current_page = @pagy.page
    start_page = [ current_page - 1, 1 ].max
    end_page = [ start_page + 2, last_page ].min
    start_page = [ end_page - 2, 1 ].max
    [ start_page, end_page ]
  end

  def last_page
    @pagy.respond_to?(:last) ? @pagy.last : @pagy.pages
  end

  def disabled_class(url)
    url ? nil : "pointer-events-none opacity-50"
  end
end
