# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

module Reactions
  # 좋아요/부스트 대상(Post·Article) 조회. 웹 컨트롤러(turbo_stream)와
  # API 컨트롤러(JSON)가 같은 화이트리스트·조회 규칙을 쓰도록 분리했다.
  #
  # 화이트리스트를 상수 해시가 아니라 case/when으로 둔 건, 클래스 객체를
  # 로드 시점에 붙잡지 않아 개발 환경 리로드에도 안전하기 때문이다.
  module TargetLookup
    class << self
      # `params`를 통째로 받는 건 id 파라미터 이름(`post_id`/`article_id`)이
      # 대상 타입에서 파생되기 때문이다. 호출부 4곳의 중복을 없앤다.
      #: (type: untyped, params: untyped, ?kept_only: bool) -> untyped
      def find(type:, params:, kept_only: false)
        klass = resolve(type)
        return nil if klass.nil?

        id = params.require(:"#{klass.model_name.singular}_id")
        scope = kept_only && klass.respond_to?(:kept) ? klass.kept : klass
        scope.respond_to?(:friendly) ? scope.friendly.find(id) : scope.find(id)
      end

      private

      def resolve(type)
        case type.to_s
        when "Post" then Post
        when "Article" then Article
        end
      end
    end
  end
end
