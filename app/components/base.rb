# frozen_string_literal: true
# rbs_inline: enabled

class Components::Base < Phlex::HTML
  include RubyUI
  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::T

  private

  # 프로덕션(public R2 서비스)에서 처리된 변형의 .url 은 직접 CDN URL
  # (cdn.ruby-news.dev)을 주므로 리다이렉트 왕복을 없앤다. 단 변형이 아직
  # 처리되지 않았으면 .url 이 실제 파일이 없는 직접 URL을 반환해 브라우저가
  # 404를 받으므로, 먼저 processed(public, 멱등)로 처리를 보장한 뒤 직접 URL을
  # 얻는다 — 잡이 미리 처리해 뒀다면 no-op이고, 아니면 지연 처리라도 404는 없다.
  # public URL을 만들 수 없는 서비스(dev/test의 Disk는 url_options 필요)면 기본
  # 리다이렉트 라우트로 폴백한다 — 요청 컨텍스트에서 항상 동작하고, 리다이렉트
  # 컨트롤러가 지연 처리하므로 이미지가 깨지지 않는다.
  def cdn_variant_url(attachment, variant_name)
    variant = attachment.variant(variant_name)
    direct = begin
      variant.processed.url
    rescue StandardError
      nil
    end
    direct.presence || helpers.url_for(variant)
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
