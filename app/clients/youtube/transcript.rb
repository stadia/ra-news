# frozen_string_literal: true

# rbs_inline: enabled

require "protobuf/message_type"

module Youtube
  class Transcript
    attr_reader :response

    def get(video_id, message = { one: "asr", two: "en" })
      typedef = MessageType
      two = get_base64_protobuf(message, typedef)

      message = { one: video_id, two: two }
      params = get_base64_protobuf(message, typedef)

      url = "https://www.youtube.com/youtubei/v1/get_transcript"
      headers = { "Content-Type" => "application/json" }
      body = {
        context: {
          client: {
            clientName: "WEB",
            clientVersion: "2.20240313"
          }
        },
        params: params
      }

      @response = Faraday.new(headers:) do
        it.request :json
        it.response :json
      end.post(url) do
        it.body = body.to_json
      end

      @response.body
    end

    def get_en(video_id)
      get(video_id, { one: "asr", two: "en" })
    end

    def get_ja(video_id)
      get(video_id, { one: "asr", two: "ja" })
    end

    def self.get(video_id)
      new.get(video_id)
    end

    def self.get_en(video_id)
      new.get_en(video_id)
    end

    def self.get_ja(video_id)
      new.get_ja(video_id)
    end

    private

    def encode_message(message, typedef)
      encoded_message = typedef.new(message)
      encoded_message.to_proto
    end

    def get_base64_protobuf(message, typedef)
      encoded_data = encode_message(message, typedef)
      Base64.encode64(encoded_data).delete("\n")
    end
  end
end
