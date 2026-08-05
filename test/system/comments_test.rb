# typed: true
# frozen_string_literal: true

require "application_system_test_case"

class CommentsTest < ApplicationSystemTestCase
  setup do
    @user = users(:john)
    @article = articles(:ruby_article)
    login_as @user, scope: :user
  end

  test "로그인 사용자가 기사에 댓글을 작성하면 목록에 노출된다" do
    visit article_path(@article)

    # 댓글 폼(#comment_form)은 turbo_frame_tag("new_comment") 안에 렌더된다.
    # 본문은 Lexxy 커스텀 에디터(.post-composer-editor)이므로 fill_lexxy 로 값을 주입한다.
    assert_text I18n.t("comments.comment_form.title")

    fill_lexxy ".post-composer-editor", "<p>시스템 테스트 댓글입니다.</p>"

    click_button I18n.t("comments.comment_form.submit")

    # posts#create 는 turbo_stream 으로 #comments_list 를 갱신한다.
    assert_text "시스템 테스트 댓글입니다."
  end

  private

  # Lexxy 커스텀 엘리먼트를 구동한다. `<lexxy-editor>` 는 form-associated 이고
  # JS `value` setter 가 폼 값(setFormValue)을 채운다. `.set`/`fill_in` 은 커스텀
  # 엘리먼트에 동작하지 않으므로 에디터가 초기화된 뒤 value 프로퍼티를 직접 설정한다.
  def fill_lexxy(selector, html)
    assert_selector "#{selector} .lexxy-editor__content", wait: 10
    execute_script(<<~JS, find(selector), html)
      const el = arguments[0];
      el.value = arguments[1];
      el.dispatchEvent(new Event("input", { bubbles: true }));
      el.dispatchEvent(new CustomEvent("lexxy:change", { bubbles: true }));
    JS
  end
end
