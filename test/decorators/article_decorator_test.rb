# frozen_string_literal: true

require "test_helper"

class ArticleDecoratorTest < ActiveSupport::TestCase
  setup do
    @article = articles(:ruby_article)
  end

  test "display_title returns title_ko for ko locale" do
    decorator = @article.decorate
    assert_equal @article.title_ko, decorator.display_title(locale: :ko)
  end

  test "display_title falls back to title when title_ko is nil" do
    @article.update_columns(title_ko: nil)
    decorator = @article.decorate
    assert_equal @article.title, decorator.display_title(locale: :ko)
  end

  test "display_title returns title_ja for ja locale when present" do
    @article.update_columns(title_ja: "日本語タイトル")
    decorator = @article.decorate
    assert_equal "日本語タイトル", decorator.display_title(locale: :ja)
  end

  test "display_title falls back to title_ko when title_ja is nil" do
    @article.update_columns(title_ja: nil)
    decorator = @article.decorate
    assert_equal @article.title_ko, decorator.display_title(locale: :ja)
  end

  test "display_summary_key returns summary_key_ja for ja locale" do
    @article.update_columns(summary_key_ja: [ "要約1", "要約2" ])
    decorator = @article.decorate
    assert_equal [ "要約1", "要約2" ], decorator.display_summary_key(locale: :ja)
  end

  test "display_summary_key falls back to ko when ja is nil" do
    @article.update_columns(summary_key_ja: nil)
    decorator = @article.decorate
    expected = @article.summary_key
    assert_equal expected, decorator.display_summary_key(locale: :ja)
  end

  test "show_original_title returns true for ko when title_ko differs from title" do
    # ruby_article fixture has different title and title_ko
    decorator = @article.decorate
    assert decorator.show_original_title?(locale: :ko)
  end

  test "show_original_title returns false for ko when title_ko matches title" do
    @article.update_columns(title_ko: @article.title)
    decorator = @article.decorate
    assert_not decorator.show_original_title?(locale: :ko)
  end

  test "show_original_title returns false for ja when title_ja is nil" do
    @article.update_columns(title_ja: nil)
    decorator = @article.decorate
    assert_not decorator.show_original_title?(locale: :ja)
  end

  test "delegates model methods through decorator" do
    decorator = @article.decorate
    assert_equal @article.host, decorator.host
    assert_equal @article.id, decorator.id
    assert_equal @article.slug, decorator.slug
  end

  test "display_summary_detail returns ja version when present" do
    @article.update_columns(summary_detail_ja: { "introduction" => "日本語の導入", "conclusion" => "日本語の結論" })
    decorator = @article.decorate
    result = decorator.display_summary_detail(locale: :ja)
    assert_equal "日本語の導入", result["introduction"]
  end

  test "display_summary_body returns ja version when present" do
    @article.update_columns(summary_body_ja: "日本語の本文")
    decorator = @article.decorate
    assert_equal "日本語の本文", decorator.display_summary_body(locale: :ja)
  end

  test "display_summary_body falls back to ko when ja is nil" do
    @article.update_columns(summary_body_ja: nil, summary_body: "한국어 본문")
    decorator = @article.decorate
    assert_equal "한국어 본문", decorator.display_summary_body(locale: :ja)
  end
end