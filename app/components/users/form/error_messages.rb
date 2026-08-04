# typed: false
# frozen_string_literal: true

class Components::Users::Form::ErrorMessages < Components::Base
  include PhlexIcons

  def initialize(user:)
    @user = user
  end

  def view_template
    return unless @user.errors.any?

    div(id: "error_explanation", class: "mb-8 p-4 bg-danger-solid/10 border border-danger-solid/20 rounded-xl text-danger-text") do
      h2(class: "font-bold mb-2 flex items-center gap-2") do
        Hero::ExclamationCircle(variant: :outline, class: "w-[18px] h-[18px]")
        plain t("errors.messages.form_errors", count: @user.errors.count)
      end
      ul(class: "list-disc ml-6 space-y-1 text-sm") do
        @user.errors.each { |error| li { error.full_message } }
      end
    end
  end
end
