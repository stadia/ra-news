# typed: true
# frozen_string_literal: true

class Components::Users::Form < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(user:)
    @user = user
  end

  def view_template
    form_with(model: @user, class: "contents", url: user_registration_path, method: @user.persisted? ? :put : :post) do |form|
      render RubyUI::Card.new(class: "w-full max-w-2xl bg-app/40 border-border-subtle rounded-2xl overflow-hidden shadow-2xl my-6") do
        # Decorative Header
        div(class: "h-24 bg-linear-to-r from-surface to-surface-muted/50 border-b border-border-subtle")

        render RubyUI::CardContent.new(class: "px-6 pb-8 sm:px-10 sm:pb-10 pt-0") do
          # Avatar & Primary Identity Section (Visual only)
          render Components::Users::Form::Header.new(user: @user)

          # Error Messages
          render Components::Users::Form::ErrorMessages.new(user: @user)

          if @user.persisted?
            render Components::Users::Form::PersistedFields.new(form: form, user: @user)
          else
            render Components::Users::Form::NewFields.new(form: form, user: @user)
          end

          unless @user.persisted?
            render Components::Users::Form::PasswordFields.new(form: form, user: @user)
          end

          # Submit Button
          render Components::Users::Form::Actions.new(user: @user)
        end
      end
    end
  end
end
