# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

module Articles
  module Utils
    class << self
      #: (untyped value) -> untyped
      def truncate_title(value)
        return value unless value.is_a?(String)

        normalized = value.squish
        return normalized if normalized.length <= Article::TITLE_MAX_LENGTH

        content_limit = Article::TITLE_MAX_LENGTH - Article::TITLE_OMISSION.length
        boundary_index = normalized.rindex(Article::TITLE_BOUNDARY_PATTERN, content_limit)
        min_boundary_index = (content_limit * Article::TITLE_BOUNDARY_MIN_RATIO).floor
        cut_index = boundary_index && boundary_index >= min_boundary_index ? boundary_index : content_limit
        "#{normalized[0...cut_index].rstrip}#{Article::TITLE_OMISSION}"
      end

      # 도메인과 서브도메인을 정확히 체크하는 클래스 메서드
      #: (String url) -> bool
      def should_ignore_url?(url)
        return true if url.blank?

        begin
          uri = URI.parse(url)
          host = uri.host&.downcase
          return true if host.blank?

          # Check for dangerous file extensions
          return true if %w[.epub .pdf .exe .zip .rar].any? { |ext| uri.path.end_with?(ext) }

          Preference.ignore_hosts.any? do |ignore_host|
            # 정확한 도메인 매칭
            host == ignore_host ||
              host.end_with?(".#{ignore_host}") ||
              # 추가적으로 www 서브도메인도 고려
              (host.start_with?("www.") && host[4..] == ignore_host) ||
              # 서브도메인 매칭
              host.start_with?("job")
          end
        rescue URI::InvalidURIError => e
          logger.warn "Invalid URI detected: #{url} - #{e.message}"
          true
        end
      end
    end
  end
end
