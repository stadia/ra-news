# frozen_string_literal: true

class Components::Comments::CommentForm < Components::Base
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::TurboFrameTag
  include PhlexIcons

  def initialize(article:, comment:)
    @article = article
    @comment = comment
  end

  def view_template
    # id를 기사별로 스코프한다: "new_comment" 하나로 고정했다면 data-turbo-permanent가
    # 다른 기사로 넘어가도 이전 기사에서 쓰다 만 댓글 내용을 그대로 남겨버린다.
    # (post_form.rb와 동일한 이유로 permanent 처리 — turbo:before-cache에서 lexxy가
    # 에디터 DOM을 지우고 캐시하는 문제. 기사 페이지를 재방문(뒤로가기 등)할 때 같은
    # 기사라면 작성 중이던 댓글이 유지되고, 다른 기사라면 id가 달라 보존되지 않는다.)
    turbo_frame_tag("new_comment_#{@article.id}", data: { turbo_permanent: true }) do
      render RubyUI::Card.new(
        class: "bg-surface-muted border-border-muted p-6",
        data: {
          controller: "character-counter post-form",
          character_counter_max_length_value: ::Post::MAX_BODY_LENGTH.to_s,
          action: "turbo:submit-end->post-form#reset"
        }
      ) do
        form_header
        comment_form_fields
      end
    end
  end

  private

  def form_header
    h4(class: "text-lg font-semibold text-content mb-4 flex items-center") do
      Hero::PencilSquare(variant: :outline, class: "w-5 h-5 mr-2 text-info-text")
      plain t("comments.comment_form.title")
    end
  end

  def comment_form_fields
    return login_prompt unless view_context.user_signed_in?

    form_with(model: [ @article, @comment ], url: article_posts_path(@article), local: false, class: "space-y-4") do |f|
      error_messages if @comment.errors.any?
      body_field(f)
      submit_section(f)
    end
  end

  def error_messages
    div(class: "bg-destructive/15 border border-destructive/40 text-content px-4 py-3 rounded-lg") do
      div(class: "flex items-center mb-2") do
        Hero::ExclamationCircle(variant: :mini, class: "w-5 h-5 mr-2")
        h5(class: "font-medium") { t("comments.comment_form.error_heading") }
      end
      ul(class: "list-disc list-inside space-y-1 text-sm") do
        @comment.errors.each do |error|
          li { error.full_message }
        end
      end
    end
  end

  def login_prompt
    div(class: "rounded-lg border border-border-muted bg-surface px-4 py-5 text-sm text-content-secondary") do
      Hero::InformationCircle(variant: :outline, class: "w-4 h-4 inline mr-1 text-info-text")
      plain t("comments.comment_form.login_prompt_before")
      link_to(t("sign_in"), new_user_session_path, class: "text-info-text hover:text-info-text-hover", data: { turbo: false })
      plain t("comments.comment_form.login_prompt_after")
    end
  end

  def body_field(f)
    lexxy_editor_asset_tags
    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: :comment_body) { Post.human_attribute_name(:body) }
      raw(
        f.lexxy_rich_textarea(
          :body,
          class: "post-composer-editor w-full text-content",
          rows: 4,
          toolbar: false,
          placeholder: t("helpers.placeholder.comment.body"),
          autocomplete: "off",
          data: {
            character_counter_target: "input",
            action: "lexxy:change->character-counter#update lexxy:initialize->character-counter#update"
          }
        )
      )
      div(class: "text-xs text-content-muted text-right") do
        span(data: { character_counter_target: "counter" }) { "0" }
        plain "/#{::Post::MAX_BODY_LENGTH}"
      end
      @comment.errors[:body].each do |msg|
        render RubyUI::FormFieldError.new { msg }
      end
    end
  end

  def submit_section(f)
    div(class: "flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4") do
      div(class: "text-xs text-content-muted") do
        Hero::InformationCircle(variant: :outline, class: "w-4 h-4 inline mr-1")
        plain t("comments.comment_form.guideline")
      end
      render RubyUI::Button.new(
        type: "submit",
        size: :xl,
        class:
          "inline-flex items-center bg-info-solid hover:bg-info-solid-hover focus:bg-info-solid-hover text-brand-foreground font-medium rounded-lg transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-state-info focus:ring-offset-2 focus:ring-offset-surface",
      ) { t("comments.comment_form.submit") }
    end
  end
end
