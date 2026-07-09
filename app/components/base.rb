# frozen_string_literal: true

class Components::Base < Phlex::HTML
  include RubyUI
  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::T

  private

  # 프로덕션(public R2 서비스)에서 처리된 변형의 .url 은 직접 CDN URL
  # (cdn.ruby-news.dev)을 주므로 리다이렉트 왕복을 없앤다. 미처리라 .url 이
  # 빈 문자열이거나, public URL을 만들 수 없는 서비스(dev/test의 Disk는
  # url_options 필요)면 기본 리다이렉트 라우트로 폴백한다 — 요청 컨텍스트에서
  # 항상 동작하고, 리다이렉트 컨트롤러가 지연 처리하므로 이미지가 깨지지 않는다.
  def cdn_variant_url(attachment, variant_name)
    variant = attachment.variant(variant_name)
    direct = begin
      variant.url
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
