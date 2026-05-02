# frozen_string_literal: true

require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/db/"
  add_filter "/lib/tasks/"
  add_filter "/vendor/"
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
require "mutant/minitest/coverage"

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

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def sign_in_as(user)
    sign_in user
  end
end
