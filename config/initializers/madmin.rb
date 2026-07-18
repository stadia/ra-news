# frozen_string_literal: true
# rbs_inline: enabled

# Madmin 커스터마이징
Rails.application.config.after_initialize do
  packages = Madmin.importmap.instance_variable_get(:@packages)

  # madmin gem 기본값은 비압축 lexxy.js(917KB)를 pin하지만, 메인 앱 importmap은
  # lexxy.min.js(604KB)를 쓴다. 같은 모듈의 min 버전으로 재정의해 madmin 페이지
  # 로드를 ~313KB 가볍게 한다. preload: true(기본)는 유지 — 에디터 로드에 필요.
  Madmin.importmap.pin "lexxy", to: "lexxy.min.js" if packages["lexxy"]

  # trix는 LexxyEditorField가 madmin 리치텍스트 에디터를 대체하여 미사용.
  # gem이 defined?(::Trix)일 때 pin하므로, pin이 존재하면 preload를 꺼
  # modulepreload 다운로드를 막는다(pin 자체는 두고, import하는 곳이 없어 fetch 안 됨).
  Madmin.importmap.pin "trix", preload: false if packages["trix"]
end
