# frozen_string_literal: true

class Components::Boosts::Button < Components::Base
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::DOMID
  include PhlexIcons

  def initialize(boostable:, boosted: nil)
    @boostable = boostable
    @boosted = boosted
  end

  def view_template
    div(id: dom_id(@boostable, :boost), class: "inline-flex items-center") do
      boost_button
    end
  end

  private

  def boost_button
    button_to(
      button_path,
      method: button_method,
      form: { data: { turbo_stream: true }, class: "inline-flex items-center m-0" },
      class: button_classes
    ) do
      boost_icon
      span { plain boosts_count.to_s } if boosts_count.positive?
    end
  end

  def boost_icon
    if boosted?
      Hero::ArrowsRightLeftSolid(class: "w-4 h-4")
    else
      Hero::ArrowsRightLeft(variant: :outline, class: "w-4 h-4")
    end
  end

  def boosted?
    return @boosted unless @boosted.nil?

    view_context.current_user&.boosts?(@boostable) || false
  end

  def boosts_count
    @boostable.boosters_count.to_i
  end

  def button_path
    case @boostable
    when Post
      post_boost_path(@boostable)
    when Article
      article_boost_path(@boostable)
    else
      raise ArgumentError, "Unsupported boostable: #{@boostable.class.name}"
    end
  end

  def button_method
    boosted? ? :delete : :post
  end

  def button_classes
    base = "inline-flex items-center gap-1 text-sm transition-colors hover:bg-transparent p-0"
    boosted? ? "#{base} text-success" : "#{base} text-content-muted hover:text-success"
  end
end
