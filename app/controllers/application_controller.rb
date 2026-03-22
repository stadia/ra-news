# frozen_string_literal: true

# rbs_inline: enabled

require "schema_dot_org/web_site"

class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: { ie: false }
  layout -> { request.format.turbo_stream? ? false : Components::Layout }

  before_action do
    Honeybadger.context({
      user_id: Current.user&.id
    })

    # WebSite schema (Sitelinks Searchbox) — homepage only per Google spec
    if request.path == "/"
      @web_site = SchemaDotOrg::WebSite.new(
        name: "Ruby-News | 루비 AI 뉴스",
        url:  "https://ruby-news.kr",
        potential_action: SchemaDotOrg::SearchAction.new(
          target: "https://ruby-news.kr/articles?search={search_term_string}",
          query_input: "required name=search_term_string"
        )
      )
    end
  end

  unless Rails.env.production?
     around_action :n_plus_one_detection

     def n_plus_one_detection
       Prosopite.scan
       yield
     ensure
       Prosopite.finish
     end
  end

  private

  # 익명 GET 요청에서 세션 쿠키를 억제하여 CDN 캐싱을 활성화한다.
  # 인증된 사용자는 개인화 응답이므로 캐싱에서 제외.
  # 댓글 폼 등 CSRF가 필요한 페이지(articles#show)는 호출하지 않는다.
  def cacheable_page!(max_age: 5.minutes)
    return if authenticated?
    request.session_options[:skip] = true
    expires_in max_age, public: true
  end
end
