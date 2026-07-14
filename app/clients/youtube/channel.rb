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

    #: () -> Array[Yt::Video]
    def videos
      # Yt::Collections::Videos는 Enumerable을 include하지 않아 to_a가 없다.
      # 대신 List 액션이 위임하는 map으로 lazy 컬렉션을 materialize하여 배열로 만든다.
      # (materialize 시점에 실제 네트워크 호출이 발생하므로 Timeout으로 감싼다.)
      Timeout.timeout(NETWORK_TIMEOUT) { channel.videos.map { |video| video } }
    end
  end
end
