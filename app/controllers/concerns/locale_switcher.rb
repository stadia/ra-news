# frozen_string_literal: true
# rbs_inline: enabled

module LocaleSwitcher
  extend ActiveSupport::Concern

  # 도메인↔로케일 매핑은 Hosts(app/functions/hosts.rb)가 단일 정본.
  # 여기서는 host→locale 역방향을 파생 상수로 가져온다.
  HOST_LOCALES = Hosts::LOCALE_FOR_HOST

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
                host_locale ||
                accept_language_locale

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
