# frozen_string_literal: true
# rbs_inline: enabled

require "timeout"

module Youtube
  class Channel
    # yt gem은 Net::HTTP.start에 타임아웃 옵션을 노출하지 않으므로 Faraday 표준 패턴 대신
    # 실제 네트워크가 발생하는 materialize 시점을 Timeout.timeout으로 감싼다.
    # 주의: Timeout.timeout은 임의 지점 인터럽트로 소켓을 정리 못 할 수 있으나, gem이
    # 소켓 레벨 타임아웃 훅을 주지 않아 차선책으로 사용한다.
    # 15초 = open(5)+read(10)에 대응하는 단일 wall-clock 예산(open/read 구분 불가).
    NETWORK_TIMEOUT = 15 #: Integer

    attr_reader :channel #: Yt::Channel

    #: (?id: String) -> Youtube::Channel
    def initialize(id: nil)
      id.nil? and raise ArgumentError, "Channel ID cannot be nil"
      @channel = Yt::Channel.new(id:)
    end

    def videos
      # yt는 lazy하므로 .to_a 시점에 네트워크 호출이 발생한다.
      Timeout.timeout(NETWORK_TIMEOUT) { channel.videos.to_a }
    end
  end
end
