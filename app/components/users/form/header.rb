# frozen_string_literal: true

class Components::Users::Form::Header < Components::Base
  def initialize(user:)
    @user = user
  end

  def view_template
    div(class: "flex flex-col sm:flex-row items-center sm:items-end gap-6 -mt-12 mb-10") do
      render RubyUI::Avatar.new(size: :xl, class: "h-24 w-24 ring-4 ring-app bg-app shadow-xl") do
        if avatar_url
          render RubyUI::AvatarImage.new(src: avatar_url, alt: avatar_alt)
        else
          render RubyUI::AvatarFallback.new(class: "bg-brand-solid text-brand-foreground text-3xl font-bold") do
            initials
          end
        end
      end

      div(class: "text-center sm:text-left pb-1 flex-1") do
        h2(class: "text-3xl font-bold text-content tracking-tight") { @user.persisted? ? t("users.form.edit_heading") : t("users.form.sign_up_heading") }
        p(class: "text-content-muted font-medium text-lg mt-1") { @user.email || t("users.form.new_beginning") }
      end
    end
  end

  private

  def initials
    (@user.name.presence || @user.email.presence || "U").first.upcase
  end

  def avatar_alt
    @user.name.presence || @user.username.presence || @user.email.presence || t("users.form.avatar_alt_default")
  end

  def avatar_url
    @user.avatar_url
  end
end
