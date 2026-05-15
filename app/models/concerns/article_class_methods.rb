# frozen_string_literal: true
# rbs_inline: enabled

module ArticleClassMethods
  extend ActiveSupport::Concern

  class_methods do
    #: (untyped value) -> untyped
    def truncate_title(value)
      return value unless value.is_a?(String)

      normalized = value.squish
      return normalized if normalized.length <= self::TITLE_MAX_LENGTH

      content_limit = self::TITLE_MAX_LENGTH - self::TITLE_OMISSION.length
      boundary_index = normalized.rindex(self::TITLE_BOUNDARY_PATTERN, content_limit)
      min_boundary_index = (content_limit * self::TITLE_BOUNDARY_MIN_RATIO).floor
      cut_index = boundary_index && boundary_index >= min_boundary_index ? boundary_index : content_limit
      "#{normalized[0...cut_index].rstrip}#{self::TITLE_OMISSION}"
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

    #: (Hash[String, untyped]) -> Hash[Symbol, untyped]
    def from_activitypub_object(hash)
      {
        federated_url: hash["id"],
        url: hash["url"] || hash["id"],
        title: hash["name"],
        title_ko: hash["content"]
      }
    end

    #: (Hash[String, untyped]) -> bool
    def handle_federated_object?(hash)
      # 이 메서드는 inbox로 들어온 remote object를 Article이 수신할지 결정합니다.
      # Article은 로컬 bot user가 발행하는 용도이므로, remote Note는 생성 대상으로 받지 않습니다.
      # outbound federation 여부는 should_federate?가 따로 결정합니다.
      false
    end

    # inbox 디스패치 시 Article은 수신 처리를 하지 않음.
    # handle_federated_object?가 false여도 inbox는 Article에게 디스패치하므로,
    # Article.from_activitypub_object(title: 등)가 Post에 잘못 assign되는 것을 방지한다.
    #: (untyped) -> void
    def handle_incoming_fediverse_data(activity)
      logger.info do
        {
          message: "[Federation] Article ignored incoming activity",
          activity_type: activity["type"],
          activity_id: activity["id"],
          actor: activity["actor"],
          object_id: activity["object"].is_a?(Hash) ? activity["object"]["id"] : activity["object"],
          object_type: activity["object"].is_a?(Hash) ? activity["object"]["type"] : nil
        }.inspect
      end
    end

    # slug로 Article을 찾는 메서드
    #: (String slug) -> Article?
    def find_by_slug(slug)
      find_by(slug: slug)
    end
  end
end
