# frozen_string_literal: true
# rbs_inline: enabled

# 도메인↔로케일 호스트 매핑의 단일 진실의 원천(single source of truth).
# 이전에는 Components::Layout 와 SitemapBuilder 에 HREFLANG_HOSTS 가 중복 정의돼
# 있었다. 로케일별 절대 호스트가 필요한 모든 곳(hreflang, sitemap, JSON-LD publisher,
# llms.txt 등)은 이 모듈을 참조한다.
module Hosts
  # locale(String|Symbol) → 절대 호스트 URL
  FOR_LOCALE = {
    "ko" => "https://ruby-news.dev",
    "ja" => "https://ruby-news.jp"
  }.freeze

  DEFAULT = "https://ruby-news.dev"

  # host(스킴 제외) → Google Analytics 4 측정 ID.
  GA_ID_FOR_HOST = {
    "ruby-news.dev" => "G-56PSNXG7QG",
    "ruby-news.jp"  => "G-56PSNXG7QG"
  }.freeze

  # host(스킴 제외) → locale 심볼. FOR_LOCALE 에서 자동 파생되는 역방향 매핑.
  # LocaleSwitcher 가 이 상수를 참조하므로 도메인 추가 시 FOR_LOCALE 한 곳만 고치면 된다.
  LOCALE_FOR_HOST = FOR_LOCALE.to_h { |locale, url| [ URI(url).host, locale.to_sym ] }.freeze

  class << self
    # 주어진 로케일의 절대 호스트를 반환한다. 알 수 없는 로케일은 기본값(.dev)으로.
    #: (String | Symbol) -> String
    def for_locale(locale)
      FOR_LOCALE.fetch(locale.to_s, DEFAULT)
    end

    # request.host(스킴 제외) → locale 심볼. 알 수 없는 호스트는 기본 로케일(ko).
    # "어느 사이트냐"(호스트 캐노니컬 도메인, 구조화 데이터)는 쿠키·사용자 로케일이
    # 아니라 실제 요청 호스트로 결정해야 하므로 이 매핑을 사용한다.
    #: (String) -> Symbol
    def locale_for_host(request_host)
      LOCALE_FOR_HOST.fetch(request_host, :ko)
    end
  end
end
