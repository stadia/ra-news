# typed: true
# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require_relative "../../../lib/quality/coverage_snapshot"

module Quality
  class CoverageSnapshotTest < ActiveSupport::TestCase
    test "full_suite_run?는 인자가 없으면 true를 반환한다" do
      assert CoverageSnapshot.full_suite_run?([])
    end

    test "full_suite_run?는 전체 test 디렉터리를 지정하면 true를 반환한다" do
      Dir.mktmpdir do |dir|
        root = Pathname(dir)
        FileUtils.mkdir_p(root.join("test/models"))
        FileUtils.mkdir_p(root.join("test/services"))
        File.write(root.join("test/models/article_test.rb"), "")
        File.write(root.join("test/services/content_service_test.rb"), "")

        assert CoverageSnapshot.full_suite_run?([ "test" ], root)
      end
    end

    test "full_suite_run?는 특정 테스트 파일이 있으면 false를 반환한다" do
      Dir.mktmpdir do |dir|
        root = Pathname(dir)
        FileUtils.mkdir_p(root.join("test/models"))
        FileUtils.mkdir_p(root.join("test/services"))
        File.write(root.join("test/models/article_test.rb"), "")
        File.write(root.join("test/services/content_service_test.rb"), "")

        refute CoverageSnapshot.full_suite_run?([ "test/models/article_test.rb" ], root)
      end
    end

    test "full_suite_run?는 이름 필터 옵션이 있으면 false를 반환한다" do
      refute CoverageSnapshot.full_suite_run?([ "-n", "/article/" ])
      refute CoverageSnapshot.full_suite_run?([ "--name=/article/" ])
    end

    test "full_suite_run?는 seed 옵션 값을 테스트 대상로 해석하지 않는다" do
      Dir.mktmpdir do |dir|
        root = Pathname(dir)
        FileUtils.mkdir_p(root.join("test/models"))
        File.write(root.join("test/models/article_test.rb"), "")

        assert CoverageSnapshot.full_suite_run?([ "--seed", "12345", "test/models/article_test.rb" ], root)
      end
    end

    test "preferred_path는 품질 스냅샷이 있으면 그 경로를 반환한다" do
      Dir.mktmpdir do |dir|
        root = Pathname(dir)
        FileUtils.mkdir_p(root.join("coverage"))
        File.write(root.join("coverage/.last_run.json"), "{}")
        File.write(root.join("coverage/.quality_last_run.json"), "{}")

        assert_equal root.join("coverage/.quality_last_run.json"), CoverageSnapshot.preferred_path(root)
      end
    end

    test "preferred_path는 품질 스냅샷이 없으면 기본 경로를 반환한다" do
      Dir.mktmpdir do |dir|
        root = Pathname(dir)
        FileUtils.mkdir_p(root.join("coverage"))

        assert_equal root.join("coverage/.last_run.json"), CoverageSnapshot.preferred_path(root)
      end
    end

    test "persist_result!는 SimpleCov 결과를 품질 스냅샷으로 저장한다" do
      Dir.mktmpdir do |dir|
        root = Pathname(dir)
        coverage_dir = root.join("coverage")
        FileUtils.mkdir_p(coverage_dir)

        branch_stats = Struct.new(:percent).new(51.42)
        result = Struct.new(:covered_percent, :coverage_statistics).new(70.74, { branch: branch_stats })

        CoverageSnapshot.persist_result!(result, root)

        assert_equal(
          "{\n  \"result\": {\n    \"line\": 70.74,\n    \"branch\": 51.42\n  }\n}",
          File.read(coverage_dir.join(".quality_last_run.json"))
        )
      end
    end
  end
end
