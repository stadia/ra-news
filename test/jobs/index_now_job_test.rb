# typed: true
# frozen_string_literal: true

require "test_helper"

class IndexNowJobTest < ActiveSupport::TestCase
  setup do
    @article = articles(:ruby_article) # slug + title_ko present → confirmed
  end

  test "confirmed 기사는 호스트마다 공개 URL로 서비스를 호출한다" do
    called = []
    fake_service = Object.new
    fake_service.define_singleton_method(:call) do |host:, urls:|
      called << { host:, urls: }
    end
    IndexNowService.stub(:new, -> { fake_service }) do
      IndexNowJob.new.perform(@article.id)
    end

    assert_equal Hosts::INDEX_NOW_HOSTS.size, called.size
    assert_equal Hosts::INDEX_NOW_HOSTS.sort, called.map { |c| c[:host] }.sort

    by_host = called.to_h { |c| [ c[:host], c ] }
    Hosts::INDEX_NOW_HOSTS.each do |host|
      url = by_host[host][:urls].first

      assert_includes url, "#{host}/articles/"
      assert_includes url, @article.slug
    end
  end

  test "unconfirmed 기사(slug 누락)는 서비스를 호출하지 않는다" do
    @article.update_columns(slug: nil)

    called = []
    fake_service = Object.new
    fake_service.define_singleton_method(:call) do |host:, urls:|
      called << { host:, urls: }
    end
    IndexNowService.stub(:new, -> { fake_service }) do
      IndexNowJob.new.perform(@article.id)
    end

    assert_empty called
  end

  test "삭제된 기사(id 조회 실패)는 서비스를 호출하지 않고 예외도 발생하지 않는다" do
    called = []
    fake_service = Object.new
    fake_service.define_singleton_method(:call) do |host:, urls:|
      called << { host:, urls: }
    end

    IndexNowService.stub(:new, -> { fake_service }) do
      assert_nothing_raised { IndexNowJob.new.perform(-999_999) }
    end
    assert_empty called
  end

  test "perform 후 캐시 잠금 키를 삭제한다" do
    lock_key = "index_now:enqueue:#{@article.id}"
    Rails.cache.write(lock_key, true, expires_in: 60.seconds)

    fake_service = Object.new
    fake_service.define_singleton_method(:call) { |host:, urls:| }
    IndexNowService.stub(:new, -> { fake_service }) do
      IndexNowJob.new.perform(@article.id)
    end

    assert_not Rails.cache.exist?(lock_key)
  end
end
