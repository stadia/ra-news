# frozen_string_literal: true

# rbs_inline: enabled

module Youtube
  class Channel
    attr_reader :channel #: Yt::Channel

    #: (?id: String) -> Youtube::Channel
    def initialize(id: nil)
      id.nil? and raise ArgumentError, "Channel ID cannot be nil"
      @channel = Yt::Channel.new(id:)
    end

    def videos
      channel.videos
    end
  end
end
