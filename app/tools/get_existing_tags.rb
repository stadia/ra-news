# typed: false
# frozen_string_literal: true
# rbs_inline: enabled

class GetExistingTags < RubyLLM::Tool
  description "기존 confirmed 태그 목록을 조회한다. keyword가 주어지면 이름으로 필터링하고, 없으면 사용 빈도순으로 반환한다."

  params type: "object",
    properties: {
      keyword: {
        type: "string",
        description: "태그 이름 필터 키워드 (LIKE 검색)"
      },
      limit: {
        type: "integer",
        description: "최대 반환 건수",
        minimum: 1,
        maximum: 50,
        default: 20
      }
    },
    required: []

  def execute(keyword: nil, limit: 20)
    limit = [ [ limit.to_i, 1 ].max, 50 ].min

    tags = if keyword.present?
      Tag.confirmed.named_like(keyword).order(:name).limit(limit).pluck(:name)
    else
      Tag.confirmed.order(taggings_count: :desc).limit(limit).pluck(:name)
    end

    { tags: tags }
  rescue StandardError => e
    { error: e.message }
  end
end
