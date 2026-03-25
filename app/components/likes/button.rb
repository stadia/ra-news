# frozen_string_literal: true

class Components::Likes::Button < Components::Base
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::DOMID
  include PhlexIcons

  def initialize(likeable:, liked: nil)
    @likeable = likeable
    @liked = liked
  end

  def view_template
    div(id: dom_id(@likeable, :like), class: "inline-flex items-center") do
      like_button
    end
  end

  private

  def like_button
    button_to(
      button_path,
      method: button_method,
      form: { data: { turbo_stream: true }, class: "inline-flex items-center m-0" },
      class: button_classes
    ) do
      heart_icon
      span { plain likes_count.to_s } if likes_count.positive?
    end
  end

  def heart_icon
    if liked?
      Hero::HeartSolid(class: "w-4 h-4")
    else
      Hero::Heart(variant: :outline, class: "w-4 h-4")
    end
  end

  def liked?
    return @liked unless @liked.nil?

    view_context.current_user&.likes?(@likeable) || false
  end

  def likes_count
    @likeable.likers_count.to_i
  end

  def button_path
    case @likeable
    when Post
      post_like_path(@likeable)
    when Article
      article_like_path(@likeable)
    else
      raise ArgumentError, "Unsupported likeable: #{@likeable.class.name}"
    end
  end

  def button_method
    liked? ? :delete : :post
  end

  def button_classes
    base = "inline-flex items-center gap-1 text-sm transition-colors hover:bg-transparent p-0"
    liked? ? "#{base} text-danger-text" : "#{base} text-content-muted hover:text-danger-text"
  end
end
