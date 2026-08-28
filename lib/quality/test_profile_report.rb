# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

module Quality
  # TestProf가 stdout에 찍은 프로파일 리포트를 GitHub Actions step summary용
  # 마크다운으로 옮긴다.
  #
  # 로그를 파싱하는 이유: TestProf는 리포트를 파일로 내보내지 않고 리포터가
  # 표준출력에 직접 찍는다(Vernier만 JSON을 남긴다). CI에서 결과를 보려면
  # 로그에서 걷어내는 수밖에 없다.
  module TestProfileReport
    # 멤버 타입: sorbet/rbi/shims/data_definitions.rbi
    Section = Data.define(:title, :body)

    # 줄 시작에 고정하지 않는다. RSpec은 진행 점(.....)을 개행 없이 찍으므로
    # 헤더가 그 뒤에 이어 붙는다.
    HEADER = /\[TEST PROF \w+\]\s*(?<title>.+)\z/

    # 리포트 블록은 다음 헤더나 EOF까지 이어지는데, 마지막 블록은 러너·SimpleCov
    # 출력과 빈 줄 없이 맞닿는다. 표 내용은 이 패턴들과 절대 겹치지 않으므로
    # 블록을 나누기 전에 통째로 걷어낸다.
    NOISE = /\A(?:\[SimpleCov\]|Coverage report generated|Line coverage:|Branch coverage:|Finished in |Run options:|# Running:|\d+ runs, |\d+ examples, |Stopped processing SimpleCov)/

    # 테스트 러너의 진행 표시(`....F...E`)는 어느 리포트에도 속하지 않는다.
    PROGRESS = /\A[.EFS*]+\z/

    # "EventProf enabled (...)" 처럼 실행 시작을 알리는 한 줄짜리 로그는 결과가
    # 아니다. 결과 블록만 남긴다.
    ENABLED = /\benabled\b/

    class << self
      #: (String log) -> Array[Section]
      def sections(log)
        lines = log.lines.map(&:chomp).reject { |line| line.match?(NOISE) || line.match?(PROGRESS) }

        blocks(lines).filter_map do |title, body|
          next if title.match?(ENABLED)

          # 표는 공백으로 열을 맞추므로 줄 단위로 깎지 않고, 앞뒤 빈 줄만 턴다.
          text = body.join("\n").gsub(/\A\n+|\n+\z/, "")

          # 본문이 없으면 "Vernier report generated: ..." 같은 한 줄 안내다.
          next if text.empty?

          Section.new(title:, body: text)
        end
      end

      #: (Hash[String, String] logs) -> String
      def to_markdown(logs)
        logs.flat_map { |runner, log| runner_markdown(runner, log) }.join("\n")
      end

      private

      # 헤더 줄에서 잘라 [제목, 본문 줄들] 짝으로 만든다. 첫 헤더 앞의 줄들은
      # 어느 블록에도 속하지 않으므로 버린다.
      #: (Array[String] lines) -> Array[[String, Array[String]]]
      def blocks(lines)
        lines.slice_before { |line| HEADER.match?(line) }.filter_map do |head, *body|
          match = HEADER.match(head)
          next unless match

          [ match[:title], body ]
        end
      end

      #: (String runner, String log) -> Array[String]
      def runner_markdown(runner, log)
        found = sections(log)
        return [ "## #{runner}", "", "프로파일 출력이 없습니다.", "" ] if found.empty?

        [ "## #{runner}", "" ] + found.flat_map do |section|
          [ "### #{section.title}", "", "```", section.body, "```", "" ]
        end
      end
    end
  end
end
