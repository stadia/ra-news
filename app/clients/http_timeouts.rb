# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

# 외부 HTTP 클라이언트 공용 타임아웃 기본값(초).
# 특정 서비스가 다른 값이 필요하면 해당 클라이언트에서 자체 상수로 오버라이드한다.
module HttpTimeouts
  OPEN = 5       #: Integer  # 연결(open) 타임아웃
  REQUEST = 10   #: Integer  # 요청/읽기 타임아웃
end
