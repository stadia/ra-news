# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

# ActivityPub federation formatting for Article.
module Articles
  module Activitypub
    extend ActiveSupport::Concern

    #: () -> Hash[String, untyped]
    def to_activitypub_object
      content_data = base_content
      title = content_data[:title]
      summary = content_data[:summary]

      # HTML 포맷팅으로 Mastodon에서 더 멋있게 표시
      article_url = Rails.application.routes.url_helpers.article_url(self)
      # ActivityStreams 표준은 문자열 키를 사용하므로 custom 해시도 문자열 키로 통일
      custom = { "url" => article_url }

      # 해시태그 생성 (태그가 있는 경우)
      custom["tag"] = tag_list.map { |t| { "type" => "Hashtag", "name" => t } } if tag_list.present?

      # HTML 콘텐츠 구성
      content_parts = []
      content_parts << "<p><strong>#{title}</strong></p>"
      content_parts << "<p>#{summary}</p>"

      # 링크 추가 (짧은 텍스트로)
      link_html = "<p><a href=\"#{article_url}\">🔗 원문 보기</a></p>"
      content_parts << link_html

      full_content = content_parts.join("\n")

      # 썸네일 이미지 첨부
      if thumbnail.attached?
        thumb_url = Rails.application.routes.url_helpers.rails_blob_url(thumbnail, disposition: "inline")
        custom["attachment"] = [ { "type" => "Image", "mediaType" => thumbnail.blob.content_type, "url" => thumb_url } ]
      end

      Federails::DataTransformer::Note.to_federation(
        self, name: title_ko, content: full_content, custom:
      )
    end

    class_methods do
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
    end
  end
end
