# frozen_string_literal: true

class Components::Users::Form::PasswordFields < Components::Base
  include Components::Users::Form::InputStyling

  def initialize(form:, user:)
    @form = form
    @user = user
  end

  def view_template
    form = @form
    div(class: "space-y-8 pt-8") do
      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: :user_password) { ::User.human_attribute_name(:password) }
        form.password_field :password, class: input_classes(@user.errors[:password]), autocomplete: "new-password"
        @user.errors[:password].each do |msg|
          render RubyUI::FormFieldError.new { msg }
        end
      end

      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: :user_password_confirmation) { ::User.human_attribute_name(:password_confirmation) }
        form.password_field :password_confirmation, class: input_classes(@user.errors[:password_confirmation]), autocomplete: "new-password"
        @user.errors[:password_confirmation].each do |msg|
          render RubyUI::FormFieldError.new { msg }
        end
      end
    end
  end
end
