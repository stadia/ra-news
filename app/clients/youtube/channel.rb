# frozen_string_literal: true
# rbs_inline: enabled

require "timeout"

module Youtube
  class Channel
    # yt gem은 Net::HTTP.start에 타임아웃 옵션을 노출하지 않으므로 Faraday 표준 패턴 대신
    # 실제 네트워크가 발생하는 materialize 시점을 Timeout.timeout으로 감싼다.
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
