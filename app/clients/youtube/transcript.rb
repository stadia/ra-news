# frozen_string_literal: true

# rbs_inline: enabled

require "protobuf/message_type"

module Youtube
  class Transcript
    attr_reader :response

    #: (String video_id, ?lang: String) -> Hash
    def get(video_id, lang: "en")
      message = { one: "asr", two: lang }
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

    #: (String video_id, ?lang: String) -> Hash
    def self.get(video_id, lang: "en")
      new.get(video_id, lang:)
    end

    private

    #: (Hash message, MessageType typedef) -> String
    def encode_message(message, typedef)
      encoded_message = typedef.new(message)
      encoded_message.to_proto
    end

    #: (Hash message, MessageType typedef) -> String
    def get_base64_protobuf(message, typedef)
      encoded_data = encode_message(message, typedef)
      Base64.encode64(encoded_data).delete("\n")
    end
  end
end
