# frozen_string_literal: true

require_relative "../lib/quality/coverage_snapshot"
require "simplecov"
# 공용 설정은 프로젝트 루트의 `.simplecov`가 담당한다(자동 로드).
# command_name을 분리해 RSpec 결과와 병합되게 한다(서로 덮어쓰지 않음).
SimpleCov.command_name "Minitest"

SimpleCov.at_exit do
  result = SimpleCov.result
  result.format!
  Quality::CoverageSnapshot.persist_result!(result) if Quality::CoverageSnapshot.full_suite_run?
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
