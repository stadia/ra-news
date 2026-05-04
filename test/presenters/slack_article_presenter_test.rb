# frozen_string_literal: true

require "test_helper"

class SlackArticlePresenterTest < ActiveSupport::TestCase
  test "summary fallback은 article base_content와 일치한다" do
    article = articles(:site_only_article)
    presenter = SlackArticlePresenter.new(article)

    assert_includes presenter.text, "새로운 Ruby 관련 글이 올라왔습니다."
  end

  test "mrkdwn 특수 문자를 escape한다" do
    article = articles(:ruby_article).dup
    article.title_ko = "제목 <b>& 테스트"
    article.summary_key = "요약 <태그> & 내용"
    article.slug = "escaped-slack-article"

    presenter = SlackArticlePresenter.new(article)

    assert_includes presenter.text, "제목 &lt;b&gt;&amp; 테스트"
    assert_includes presenter.text, "요약 &lt;태그&gt; &amp; 내용"
    block_text = presenter.blocks.first.dig(:text, :text)

    assert_includes block_text, "*<"
    assert_includes block_text, "|제목 &lt;b&gt;&amp; 테스트>*"
    assert_includes block_text, "요약 &lt;태그&gt; &amp; 내용"
  end
end
