# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PostSerializer do
  def minimal_post(overrides = {})
    Post.new(
      body: '테스트 포스트입니다.',
      **overrides
    )
  end

  it 'media_attachments를 그대로 직렬화한다' do
    post = minimal_post(
      media_attachments: [
        { 'url' => 'https://example.com/a.jpg', 'mediaType' => 'image/jpeg', 'name' => '대체 텍스트' }
      ]
    )

    json = JSON.parse(PostSerializer.new(post).serialize)

    expect(json['media_attachments']).to eq(
      [ { 'url' => 'https://example.com/a.jpg', 'mediaType' => 'image/jpeg', 'name' => '대체 텍스트' } ]
    )
  end

  it '첨부가 없으면 빈 배열을 직렬화한다' do
    post = minimal_post

    json = JSON.parse(PostSerializer.new(post).serialize)

    expect(json['media_attachments']).to eq([])
  end
end
