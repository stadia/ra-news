# frozen_string_literal: true

# 공용 SimpleCov 설정. `require "simplecov"` 시 SimpleCov가 프로젝트 루트에서
# 이 파일을 자동 로드한다. Minitest(test_helper)와 RSpec(spec_helper) 양쪽이
# 동일한 필터/프로파일을 공유하도록 여기 한 곳에서만 관리한다.
# 각 러너는 서로 다른 command_name을 지정해 결과가 병합되게 한다.
# 커버리지 시작(SimpleCov.start "rails")은 test_helper/spec_helper에서 호출한다 —
# SimpleCov 2.0부터 .simplecov에서 start를 직접 호출하는 것이 deprecated.
SimpleCov.configure do
  enable_coverage :branch
  skip "/test/"
  skip "/spec/"
  skip "/config/"
  skip "/db/"
  skip "/lib/tasks/"
  skip "/vendor/"

  # UI 라이브러리 컴포넌트: 벤더 코드 성격으로 앱에서 테스트하지 않음
  skip "/app/components/ruby_ui/"

  # 관리자 백오피스: madmin 자동 생성 코드
  skip "/app/controllers/madmin/"

  # AI 에이전트/도구: LLM 호출 코드로 단위 테스트가 불가능
  skip "/app/agents/"
  skip "/app/tools/"

  # 인프라: 채널/제약조건은 프레임워크 수준
  skip "/app/channels/"
  skip "/app/constraints/"

  # 품질 관리: Rake 태스크에서만 사용
  skip "/lib/quality/"
end
