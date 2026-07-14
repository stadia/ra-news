# frozen_string_literal: true

require "test_helper"

class Youtube::ChannelTest < ActiveSupport::TestCase
  # Yt::Collections::Videos를 흉내낸 lazy 컬렉션.
  # 실제 yt gem처럼 Enumerable을 include하지 않아 to_a가 없고,
  # List 액션이 위임하는 each/map/first 정도만 응답한다.
  class FakeVideos
    include Enumerable

    def initialize(items)
      @items = items
    end

    # Enumerable을 쓰되 to_a는 명시적으로 제거해 회귀(NoMethodError)를 재현한다.
    undef_method :to_a

    def each(&)
      @items.each(&)
    end
  end

  test "id가 nil이면 ArgumentError를 발생시킨다" do
    assert_raises(ArgumentError) { Youtube::Channel.new(id: nil) }
  end

  test "videos는 to_a 없는 lazy 컬렉션을 배열로 materialize한다" do
    fake_video = Object.new
    channel = Youtube::Channel.new(id: "UC123")
    fake_channel = Object.new
    fake_channel.define_singleton_method(:videos) { FakeVideos.new([ fake_video ]) }

    channel.stub(:channel, fake_channel) do
      result = channel.videos

      assert_kind_of Array, result
      assert_equal [ fake_video ], result
    end
  end
end
