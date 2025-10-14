# frozen_string_literal: true

# rbs_inline: enabled

class TwitterService < SocialMediaService
  TwitterConfig = Struct.new(:character_limit, :shortened_url_length, :formatting_buffer) do
    def max_content_length
      character_limit - shortened_url_length - formatting_buffer
    end
  end

  TWITTER_CONFIG = TwitterConfig.new(280, 23, 4) #: TwitterConfig

  private

  def platform_name #: String
    "X.com"
  end

  #: (Article article) -> void
  def post_to_platform(article)
    post_text = build_post_text(article)
    response = platform_client.post(post_text)
    logger.info "Successfully posted to #{platform_name} for article id: #{article.id} - Status: #{response}"
  end

  #: (Article article) -> String
  def build_post_text(article)
    content_data = base_content(article)
    content = "#{content_data[:title]}\n#{content_data[:summary]}"

    # 태그와 링크를 먼저 생성해서 길이 계산 (taggings_count가 가장 높은 태그 하나만)
    top_tag = article.tags.select { |it| it.is_confirmed? }.max_by(&:taggings_count)
    tags = top_tag ? "##{top_tag.name.gsub(/\s+/, '_').downcase}" : ""
    link = article_link

    # 태그와 링크를 위한 공간 확보 (공백 문자들 포함)
    reserved_space = tags.length + link.length + 3 # " " + "\n" + 여분
    available_content_length = TWITTER_CONFIG.character_limit - TWITTER_CONFIG.shortened_url_length - TWITTER_CONFIG.formatting_buffer - reserved_space

    truncated_content = content.truncate([ available_content_length, 1 ].max, omission: "...")
    "#{truncated_content} #{tags}\n#{link}"
  end

  def platform_client #: TwitterClient
    TwitterClient.new
  end
end
