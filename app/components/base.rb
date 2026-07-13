# frozen_string_literal: true

class Components::Base < Phlex::HTML
  include RubyUI
  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::T

  private

  # 처리된 변형의 .url 은 public R2 서비스에서 직접 CDN URL을 주므로 리다이렉트
  # 왕복을 없앤다. 단 변형이 아직 처리되지 않았으면 .url 이 실제 파일이 없는 URL을
  # 반환해 브라우저가 404를 받으므로, 먼저 processed 로 존재를 보장한다 —
  # track_variants=true 라 이는 변형 레코드 DB 조회이고(R2 HEAD 아님), 잡이 미리
  # 처리해 뒀다면 조회만, 아니면 동기 변환+업로드 후 직접 URL을 얻는다.
  # public URL을 만들 수 없는 서비스(dev/test의 Disk는 url_options 필요)면 기본
  # 리다이렉트 라우트로 폴백한다 — 요청 컨텍스트에서 항상 동작하고 지연 처리된다.
  def cdn_variant_url(attachment, variant_name)
    variant = attachment.variant(variant_name)
    direct = begin
      variant.processed.url
    rescue StandardError => e
      # dev/test의 Disk 서비스는 url_options 미설정으로 예상된 실패라 조용히
      # 폴백한다. 그 외(프로덕션의 R2 인증 실패·변형 오류 등)는 사이트 전역 LCP
      # 회귀 신호이므로 삼키지 않고 로깅한다("no silent failures").
      unless Rails.env.local?
        Rails.logger.error("cdn_variant_url failed (#{variant_name}): #{e.class} - #{e.message}")
        Sentry.capture_exception(e) if defined?(Sentry)
      end
      nil
    end
    direct.presence || helpers.url_for(variant)
  end

  # lexxy(리치텍스트 에디터, ~917KB) asset을 "에디터가 있는 페이지에서만" eager
  # 로드하는 힌트를 <lexxy-editor>가 렌더되는 컴포넌트 바로 옆에 심는다.
  #
  # 왜 컴포넌트에서 심는가:
  #   - 서버는 이 컴포넌트를 렌더하는 순간 해당 페이지에 에디터가 있음을 이미 안다.
  #   - 컨트롤러 인스턴스 변수 방식은 에디터 폼을 렌더하는 액션마다(활동 피드/기사
  #     상세/블로그 편집/댓글 turbo_stream 등) 개별 수정이 필요하고 turbo_stream
  #     응답은 layout head를 거치지 않아 누락된다. 컴포넌트에 심으면 렌더 경로와
  #     무관하게 항상 함께 나간다.
  #
  # modulepreload: 브라우저가 이 <link>를 파싱하는 즉시 lexxy.min.js를 병렬로 받아
  #   모듈 그래프에 캐시한다. application.js의 turbo:load 후 import("lexxy")는
  #   같은 URL을 요청하므로 네트워크 왕복 없이 캐시에서 즉시 해석된다 → 에디터가
  #   뒤늦게 나타나는 지연 제거. import 로직 자체는 유지되므로 Sentry 에러 핸들링과
  #   Turbo 네비게이션 모듈 캐시 동작이 보존된다.
  #
  # stylesheet: 에디터 페이지에서는 동기 로드로 FOUC를 없앤다. 에디터 없는 페이지는
  #   이 힌트가 전혀 나가지 않으므로 전 페이지 604KB/CSS 비용을 지지 않는다.
  #   data-turbo-track은 붙이지 않는다(layout.rb render_lexxy_stylesheet 주석 참고:
  #   rel 전환/방문 비교로 인한 전체 리로드 함정). 에셋 갱신 감지는 app.css가 담당.
  #
  # importmap의 bare specifier "lexxy"는 asset_path("lexxy.min.js")와 동일한
  # digested URL로 매핑되므로(config/importmap.rb 참고) modulepreload href와
  # import() 대상이 정확히 일치한다. 한 페이지에 lexxy 에디터 폼이 여러 번
  # 렌더될 수 있어(예: 댓글마다 반복되는 reply form) 요청당 한 번만 태그를
  # 내보내도록 컨트롤러 인스턴스에 플래그를 둔다.
  def lexxy_editor_asset_tags
    controller = helpers.controller
    return if controller.instance_variable_get(:@lexxy_editor_assets_rendered)

    controller.instance_variable_set(:@lexxy_editor_assets_rendered, true)
    js_href = helpers.asset_path("lexxy.min.js")
    css_href = helpers.stylesheet_path("lexxy")
    link(rel: "modulepreload", href: js_href)
    link(rel: "stylesheet", href: css_href)
  end

  def safe_url(url)
    uri = URI.parse(url.to_s)
    %w[http https].include?(uri.scheme) ? url : nil
  rescue URI::InvalidURIError
    nil
  end

  def post_permalink_path(post)
    if post.blog? && post.user
      user_profile_blog_post_path(username: post.user.username, slug: post)
    else
      post_path(post)
    end
  end

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end
end
