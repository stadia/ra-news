# frozen_string_literal: true

# 공용 SimpleCov 설정. `require "simplecov"` 시 SimpleCov가 프로젝트 루트에서
# 이 파일을 자동 로드한다. Minitest(test_helper)와 RSpec(spec_helper) 양쪽이
# 동일한 필터/프로파일을 공유하도록 여기 한 곳에서만 관리한다.
# 각 러너는 서로 다른 command_name을 지정해 결과가 병합되게 한다.
SimpleCov.start "rails" do
  enable_coverage :branch
  add_filter "/test/"
  add_filter "/spec/"
  add_filter "/config/"
  add_filter "/db/"
  add_filter "/lib/tasks/"
  add_filter "/vendor/"

  # UI 라이브러리 컴포넌트: 벤더 코드 성격으로 앱에서 테스트하지 않음
  add_filter "/app/components/ruby_ui/"

  # 관리자 백오피스: madmin 자동 생성 코드
  add_filter "/app/controllers/madmin/"

  # AI 에이전트/도구: LLM 호출 코드로 단위 테스트가 불가능
  add_filter "/app/agents/"
  add_filter "/app/tools/"

  # 인프라: 채널/제약조건은 프레임워크 수준
  add_filter "/app/channels/"
  add_filter "/app/constraints/"

  # 품질 관리: Rake 태스크에서만 사용
  add_filter "/lib/quality/"
end
