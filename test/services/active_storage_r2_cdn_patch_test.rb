# frozen_string_literal: true

require "test_helper"

class ActiveStorageR2CdnPatchTest < ActiveSupport::TestCase
  setup do
    @original_cdn_host = ENV["ACTIVE_STORAGE_CDN_HOST"]
  end

  teardown do
    ENV["ACTIVE_STORAGE_CDN_HOST"] = @original_cdn_host
  end

  test "cloudflare public service는 CDN 호스트를 사용한다" do
    service = build_service(name: "cloudflare")
    ENV["ACTIVE_STORAGE_CDN_HOST"] = "https://assets.ruby-news.dev/"

    assert_equal "https://assets.ruby-news.dev/folder/blob-key", service.public_url("folder/blob-key")
  end

  test "cloudflare가 아닌 public service는 기존 public_url을 유지한다" do
    service = build_service(name: "other")
    ENV["ACTIVE_STORAGE_CDN_HOST"] = "https://assets.ruby-news.dev"

    assert_equal "https://origin.example.com/folder/blob-key", service.public_url("folder/blob-key")
  end

  test "CDN 호스트가 없으면 기존 public_url을 유지한다" do
    service = build_service(name: "cloudflare")
    ENV.delete("ACTIVE_STORAGE_CDN_HOST")

    assert_equal "https://origin.example.com/folder/blob-key", service.public_url("folder/blob-key")
  end

  private
    def build_service(name:)
      ActiveStorage::Service::S3Service.new(
        bucket: "bucket",
        access_key_id: "access-key",
        secret_access_key: "secret-key",
        endpoint: "https://example.r2.cloudflarestorage.com",
        region: "auto",
        force_path_style: true,
        public: true
      ).tap do |service|
        service.name = name
        service.define_singleton_method(:object_for) do |key|
          Struct.new(:key) do
            def public_url(**)
              "https://origin.example.com/#{key}"
            end
          end.new(key)
        end
      end
    end
end
