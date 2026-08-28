# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

# 웹 전용(turbo_stream·html) 엔드포인트의 포맷 협상을 액션 **전에** 끝낸다.
# JSON은 api/v1이 맡으므로 여기서는 요청을 받자마자 406으로 끊는다.
#
# 두 가지 실패를 막는다.
#
# 1. 쓰기 액션: `respond_to` 블록은 액션 본문 끝에서 평가되므로, 미지원 포맷
#    요청은 `like!`/`boost!`가 커밋된 뒤에야 406을 받는다. 클라이언트는 실패로
#    보고 재시도하지만 반응은 이미 만들어져 있다.
# 2. 읽기 액션: `respond_to` 분기 없이 Phlex 뷰를 바로 렌더링하는 액션은
#    `Accept: application/json`이나 `.json`에도 200 + HTML을 돌려준다.
#    클라이언트는 성공으로 보고 파싱에서 깨진다.
module WebOnlyFormats
  extend ActiveSupport::Concern

  SUPPORTED_FORMATS = %i[turbo_stream html].freeze

  included do
    before_action :ensure_web_format
  end

  private

  # 이 액션이 실제로 응답할 수 있는 포맷. 웹 포맷 외에 JSON 등을 함께 제공하는
  # 액션이 있으면 컨트롤러에서 이 메서드를 덮어써 `super + %i[json]`처럼 넓힌다.
  #
  # 부작용이 있는 액션이라면 `skip_before_action`으로 가드를 통째로 끄지 말 것.
  # 그러면 XML 같은 나머지 미지원 포맷까지 액션 본문에 들어가, 저장이 커밋된
  # 뒤에야 `respond_to`가 406을 낸다 — 이 concern이 막으려던 바로 그 실패다.
  #: () -> Array[Symbol]
  def supported_web_formats
    SUPPORTED_FORMATS
  end

  # Accept가 `*/*`(브라우저 폼 전송·curl 기본)인 경우는 통과시킨다 —
  # `respond_to`가 첫 블록으로 응답할 수 있는 요청이기 때문이다.
  #: () -> void
  def ensure_web_format
    allowed = supported_web_formats
    return if request.formats.any? { |format| format == Mime::ALL || allowed.include?(format.symbol) }

    head :not_acceptable
  end
end
