# frozen_string_literal: true

require "test_helper"
require_relative "../../../lib/quality/test_profile_report"

module Quality
  class TestProfileReportTest < ActiveSupport::TestCase
    MINITEST_LOG = <<~LOG
      Run options: --seed 20215

      # Running:

      ...
      Finished in 2.931045s, 132.0348 runs/s, 422.0338 assertions/s.
      387 runs, 1237 assertions, 0 failures, 0 errors, 0 skips
      [TEST PROF INFO] EventProf results for sql.active_record

      Total time: 00:00.073 of 00:02.929 (2.5%)
      Total events: 176

      Top 5 slowest suites (by time):

      TagTest (./test/models/tag_test.rb) – 00:00.073 (176 / 32) of 00:00.830 (8.82%)

      [TEST PROF INFO] TagProf report for type

                 type          time   total  %total   %time           avg

               models     00:02.863     387  100.00  100.00     00:00.007
      Coverage report generated for Minitest, RSpec to coverage/index.html
      Line coverage: 2051 / 8283 (24.76%)
      Branch coverage: 404 / 2361 (17.11%)
    LOG

    test "리포트 블록의 제목을 섹션으로 뽑는다" do
      sections = TestProfileReport.sections(MINITEST_LOG)

      assert_equal [ "EventProf results for sql.active_record", "TagProf report for type" ],
        sections.map(&:title)
    end

    test "블록 본문에 표 내용을 담는다" do
      event_prof = TestProfileReport.sections(MINITEST_LOG).first

      assert_includes event_prof.body, "Total time: 00:00.073 of 00:02.929 (2.5%)"
      assert_includes event_prof.body, "TagTest (./test/models/tag_test.rb)"
    end

    # TagProf 블록은 SimpleCov 출력과 맞닿아 있어 종료 지점이 빈 줄로 구분되지
    # 않는다. 이 노이즈가 섞이면 요약이 엉뚱한 숫자를 보여준다.
    test "SimpleCov 출력은 본문에서 제외한다" do
      tag_prof = TestProfileReport.sections(MINITEST_LOG).last

      assert_includes tag_prof.body, "models     00:02.863"
      refute_includes tag_prof.body, "Coverage report generated"
      refute_includes tag_prof.body, "Line coverage:"
    end

    test "테스트 러너 자체 출력은 본문에서 제외한다" do
      body = TestProfileReport.sections(MINITEST_LOG).first.body

      refute_includes body, "387 runs, 1237 assertions"
      refute_includes body, "Finished in 2.931045s"
    end

    # RSpec은 진행 점(.....)을 개행 없이 찍으므로 헤더가 줄 맨 앞에 오지 않는다.
    # 줄 시작에 고정해 찾으면 RSpec 쪽 블록이 통째로 사라진다.
    test "진행 점 뒤에 붙은 헤더도 찾는다" do
      log = <<~LOG
        .....[TEST PROF INFO] TagProf report for type

                   type          time   total  %total   %time           avg

                request     00:02.908      47   68.12   84.22     00:00.061
      LOG

      sections = TestProfileReport.sections(log)

      assert_equal [ "TagProf report for type" ], sections.map(&:title)
      assert_includes sections.first.body, "request     00:02.908"
    end

    # 표는 공백으로 열을 맞춘다. 줄 단위로 공백을 깎으면 헤더만 왼쪽으로
    # 밀려 열이 어긋난다.
    test "표의 들여쓰기를 보존한다" do
      body = TestProfileReport.sections(MINITEST_LOG).last.body

      assert_includes body, "           type          time"
      assert_includes body, "         models     00:02.863"
    end

    # "Vernier report generated: ..." 같은 한 줄 안내는 표가 아니다. 섹션으로
    # 잡으면 본문 없는 빈 제목만 요약에 남는다.
    test "본문 없는 한 줄 안내는 섹션으로 잡지 않는다" do
      log = <<~LOG
        [TEST PROF INFO] Vernier report generated: tmp/test_prof/vernier-report-wall-total.json
      LOG

      assert_empty TestProfileReport.sections(log)
    end

    test "진행 표시 문자만 있는 줄은 본문에서 제외한다" do
      log = <<~LOG
        [TEST PROF INFO] TagProf report for type
        .........F...E...
                   type          time
      LOG

      body = TestProfileReport.sections(log).first.body

      refute_includes body, "........."
      assert_includes body, "type          time"
    end

    test "프로파일 출력이 없으면 섹션도 없다" do
      assert_empty TestProfileReport.sections("1001 runs, 0 failures\n")
    end

    test "마크다운은 러너 이름을 제목으로, 각 블록을 코드 펜스로 낸다" do
      markdown = TestProfileReport.to_markdown("minitest" => MINITEST_LOG)

      assert_includes markdown, "## minitest"
      assert_includes markdown, "### EventProf results for sql.active_record"
      assert_includes markdown, "```\n"
      assert_includes markdown, "models     00:02.863"
    end

    test "마크다운은 러너를 넘긴 순서대로 낸다" do
      markdown = TestProfileReport.to_markdown("minitest" => MINITEST_LOG, "rspec" => MINITEST_LOG)

      assert_operator markdown.index("## minitest"), :<, markdown.index("## rspec")
    end

    # 프로파일러가 조용히 죽어도 잡은 초록으로 끝난다. 요약이 비어 있으면
    # "느려지지 않았다"가 아니라 "계측이 안 됐다"는 뜻이므로 구분해서 말해야 한다.
    test "프로파일 출력이 없는 러너는 그 사실을 명시한다" do
      markdown = TestProfileReport.to_markdown("rspec" => "69 examples, 0 failures\n")

      assert_includes markdown, "## rspec"
      assert_includes markdown, "프로파일 출력이 없습니다"
    end
  end
end
