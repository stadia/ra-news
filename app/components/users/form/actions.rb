# typed: true
# frozen_string_literal: true

class Components::Users::Form::Actions < Components::Base
  include PhlexIcons

  def initialize(user:)
    @user = user
  end

  def view_template
    div(class: "mt-10 pt-8 border-t border-border-subtle/60 flex items-center justify-end gap-3") do
      if @user.persisted?
        render RubyUI::Link.new(
          href: account_password_path,
          class: "flex items-center justify-center gap-2 rounded-xl bg-surface hover:bg-surface-muted text-content font-bold text-sm border border-border-strong transition-all active:scale-95 shadow-lg"
        ) do
          Hero::Key(variant: :outline, class: "w-4 h-4")
          plain t("users.form.change_password")
        end

        render RubyUI::Link.new(
          href: user_profile_path(@user),
          class: "flex items-center justify-center gap-2 rounded-xl bg-surface hover:bg-surface-muted text-content font-bold text-sm border border-border-strong transition-all active:scale-95 shadow-lg"
        ) do
          Hero::ChevronLeft(variant: :outline, class: "w-4 h-4")
          plain t("users.form.back")
        end
      end

      render RubyUI::Button.new(
        type: "submit",
        class: "group relative flex items-center justify-center gap-2 rounded-xl bg-brand-solid hover:bg-brand-solid-hover text-brand-foreground font-bold text-sm transition-all active:scale-95 shadow-lg shadow-brand/20"
      ) do
        plain @user.persisted? ? t("users.form.save_changes") : t("users.form.sign_up_submit")
        Hero::ArrowLongRight(variant: :outline, class: "w-5 h-5 transition-transform group-hover:translate-x-1")
      end
    end
  end
end
