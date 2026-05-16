# frozen_string_literal: true

class Components::Comments::CommentReplyForm < Components::Base
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::TurboFrameTag
  include PhlexIcons

  def initialize(article:, comment:, parent_comment:, visible: false)
    @article = article
    @comment = comment
    @parent_comment = parent_comment
    @visible = visible
  end

  def view_template
    turbo_frame_tag(
      "reply_form_#{@parent_comment.id}",
      class: (@visible ? "" : "hidden"),
      data: { reply_form_target: "form" }
    ) do
      div(
        class: "p-4 lg:p-5",
        data: {
          controller: "character-count",
          character_count_max_length_value: ::Post::MAX_BODY_LENGTH.to_s
        }
      ) do
        reply_header
        reply_form_fields
      end
    end
  end

  private

  def reply_header
    h5(class: "text-xs font-semibold text-content-muted mb-3 flex items-center uppercase tracking-wide") do
      Hero::ArrowUturnLeft(variant: :outline, class: "w-3 h-3 mr-1.5 text-info-text")
      plain t("comments.comment_reply_form.title")
    end
  end

  def reply_form_fields
    return login_prompt unless view_context.user_signed_in?

    form_with(
      model: [ @article, @comment ],
      url: article_posts_path(@article),
      local: false,
      class: "space-y-3",
      data: { action: "turbo:submit-end->reply-form#close" }
    ) do |f|
      f.hidden_field :parent_id, value: @parent_comment.id

      error_messages if @comment.errors.any?
      body_field(f)
      action_buttons(f)
    end
  end

  def error_messages
    div(class: "bg-destructive/15 border border-destructive/40 text-content px-4 py-3 rounded-lg") do
      div(class: "flex items-center mb-2") do
        Hero::ExclamationCircle(variant: :mini, class: "w-5 h-5 mr-2")
        h5(class: "font-medium") { t("comments.comment_reply_form.error_heading") }
      end
      ul(class: "list-disc list-inside space-y-1 text-sm") do
        @comment.errors.each do |error|
          li { error.full_message }
        end
      end
    end
  end

  def login_prompt
    div(class: "rounded-lg border border-border-muted bg-surface px-4 py-3 text-sm text-content-secondary") do
      Hero::InformationCircle(variant: :outline, class: "w-4 h-4 inline mr-1 text-info-text")
      plain t("comments.comment_reply_form.login_prompt_before")
      link_to(t("sign_in"), new_user_session_path, class: "text-info-text hover:text-info-text-hover", data: { turbo: false })
      plain t("comments.comment_reply_form.login_prompt_after")
    end
  end

  def body_field(f)
    render RubyUI::FormField.new do
      f.text_area :body,
        rows: 3,
        class: text_area_classes(@comment.errors[:body]),
        placeholder: t("comments.comment_reply_form.body_placeholder"),
        maxlength: ::Post::MAX_BODY_LENGTH,
        data: { character_count_target: "input", action: "input->character-count#updateCount" }
      div(class: "text-xs text-content-muted text-right") do
        span(data: { character_count_target: "counter" }) { "0" }
        plain "/#{::Post::MAX_BODY_LENGTH}"
      end
      @comment.errors[:body].each do |msg|
        render RubyUI::FormFieldError.new { msg }
      end
    end
  end

  def action_buttons(f)
    div(class: "flex items-center justify-end gap-2") do
      render RubyUI::Button.new(variant: :ghost,
        class: "font-medium text-content-muted hover:text-content transition-colors hover:bg-transparent",
          data: { action: "reply-form#toggle" }) { t("comments.comment_reply_form.cancel") }
      f.submit t("comments.comment_reply_form.submit"),
        class: "inline-flex items-center px-4 py-1.5 bg-info-solid hover:bg-info-solid-hover text-brand-foreground text-xs font-medium rounded-md transition-colors duration-200"
    end
  end

  def text_input_classes(errors)
    state_classes = errors.none? ? "border-border-muted hover:border-border-strong focus:ring-state-info" : "border-destructive focus:ring-destructive"
    "w-full px-3 py-2 rounded-lg border bg-surface text-content placeholder:text-content-muted focus:border-transparent transition-all duration-200 text-sm #{state_classes}"
  end

  def text_area_classes(errors)
    state_classes = errors.none? ? "border-border-muted hover:border-border-strong focus:ring-state-info" : "border-destructive focus:ring-destructive"
    "w-full px-4 py-2 rounded-lg border bg-surface text-content placeholder:text-content-muted focus:border-transparent transition-all duration-200 resize-none text-sm #{state_classes}"
  end
end
