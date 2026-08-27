# typed: true
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
    # 하트 아이콘만 있으면 스크린리더가 "버튼"으로만 읽어 용도를 알 수 없다
    # (WCAG 4.1.2 button-name). sr-only 텍스트로 접근명을 부여한다. aria-label 대신
    # sr-only를 써서 보이는 카운트가 접근명에 포함되게 한다(2.5.3 불일치 회피).
    button_to(
      button_path,
      method: button_method,
      form: { data: { turbo_stream: true }, class: "inline-flex items-center m-0" },
      class: button_classes
    ) do
      span(class: "sr-only") { plain aria_label }
      heart_icon
      span { plain likes_count.to_s } if likes_count.positive?
    end
  end

  def aria_label
    liked? ? t("likes.button.aria_label.undo") : t("likes.button.aria_label.like")
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
