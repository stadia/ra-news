# frozen_string_literal: true

module LocaleSwitcher
  extend ActiveSupport::Concern

  HOST_LOCALES = {
    "ruby-news.jp" => :ja,
    "ruby-news.kr" => :ko
  }.freeze

  included do
    around_action :switch_locale
  end

  private

  def switch_locale(&)
    I18n.with_locale(resolved_locale, &)
  end

  def resolved_locale
    candidate = user_locale ||
                cookie_locale ||
                accept_language_locale ||
                host_locale

    permitted_locale(candidate) || I18n.default_locale
  end

  def user_locale
    return unless respond_to?(:current_user) && current_user&.locale.present?

    current_user.locale
  end

  def cookie_locale
    cookies[:locale]
  end

  def accept_language_locale
    header = request.env["HTTP_ACCEPT_LANGUAGE"]
    return if header.blank?

    header.scan(/[a-z]{2}/i).map(&:downcase).find do |code|
      permitted_locale(code)
    end
  end

  def host_locale
    HOST_LOCALES[request.host]
  end

  def permitted_locale(value)
    return if value.blank?

    sym = value.to_s.downcase.to_sym
    I18n.available_locales.include?(sym) ? sym : nil
  end
end
