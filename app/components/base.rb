# frozen_string_literal: true

class Components::Base < Phlex::HTML
  include RubyUI
  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::T

  private

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
