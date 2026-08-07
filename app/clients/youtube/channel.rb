# typed: true
# frozen_string_literal: true
# rbs_inline: enabled

module Youtube
  class Channel
    #: Yt::Channel
    attr_reader :channel

    #: (?id: String?) -> void
    def initialize(id: nil)
      id.nil? and raise ArgumentError, "Channel ID cannot be nil"
      @channel = Yt::Channel.new(id:)
    end

    #: () -> Array[Yt::Video]
    def videos
      channel.videos
    end
  end
end
