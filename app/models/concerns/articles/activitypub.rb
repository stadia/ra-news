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
  end
end
