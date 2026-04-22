# frozen_string_literal: true

class Components::UserAvatar < Components::Base
  def initialize(user: nil, federails_actor: nil, name:, size: "h-8 w-8", fallback_class: "bg-surface-muted text-accent-text ring-1 ring-inset ring-border-muted text-sm font-bold")
    @user = user
    @federails_actor = federails_actor
    @name = name
    @size = size
    @fallback_class = fallback_class
  end

  def view_template
    render RubyUI::Avatar.new(class: "#{@size} shrink-0") do
      if avatar_url.present?
        render RubyUI::AvatarImage.new(src: avatar_url, alt: @name)
      else
        render RubyUI::AvatarFallback.new(class: @fallback_class) do
          plain @name.to_s.first.to_s.upcase
        end
      end
    end
  end

  private

  def avatar_url
    @user&.avatar_url || @federails_actor&.extensions&.dig("icon", "url")
  end
end
