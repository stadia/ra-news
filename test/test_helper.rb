# frozen_string_literal: true

require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch
  add_filter "/test/"
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

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

Warning[:deprecated] = true
module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Federails 엔진 픽스처 클래스 매핑 (테이블 이름에서 모델 클래스를 자동 감지할 수 없으므로)
    set_fixture_class federails_actors: Federails::Actor
    set_fixture_class federails_followings: Federails::Following

    def stub_constructor(klass, replacement)
      singleton_class = class << klass
        self
      end

      if singleton_class.instance_methods(false).include?(:new) || singleton_class.private_instance_methods(false).include?(:new)
        raise ArgumentError, "#{klass} defines its own .new; use klass.stub(:new, ...) instead"
      end

      singleton_class.define_method(:new) do |*args, **kwargs, &block|
        replacement.respond_to?(:call) ? replacement.call(*args, **kwargs, &block) : replacement
      end

      yield
    ensure
      singleton_class&.send(:remove_method, :new)
    end
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def sign_in_as(user)
    sign_in user
  end
end
