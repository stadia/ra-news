# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

# 웹 전용(turbo_stream·html) 엔드포인트의 포맷 협상을 상태 변경 **전에** 끝낸다.
#
# `respond_to` 블록은 액션 본문 끝에서 평가되므로, 미지원 포맷 요청은
# `like!`/`boost!`가 커밋된 뒤에야 406을 받는다. 클라이언트는 실패로 보고
# 재시도하지만 반응은 이미 만들어져 있다. JSON은 api/v1이 맡으므로
# 여기서는 요청을 받자마자 406으로 끊는다.
module WebOnlyFormats
  extend ActiveSupport::Concern

  SUPPORTED_FORMATS = %i[turbo_stream html].freeze

  included do
    before_action :ensure_web_format
  end

  private

  # Accept가 `*/*`(브라우저 폼 전송·curl 기본)인 경우는 통과시킨다 —
  # `respond_to`가 첫 블록으로 응답할 수 있는 요청이기 때문이다.
  #: () -> void
  def ensure_web_format
    return if request.formats.any? { |format| format == Mime::ALL || SUPPORTED_FORMATS.include?(format.symbol) }

    head :not_acceptable
  end
end
