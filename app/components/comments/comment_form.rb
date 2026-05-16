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
    turbo_frame_tag("new_comment") do
      render RubyUI::Card.new(
        class: "bg-surface-muted border-border-muted p-6",
        data: {
          controller: "character-count post-form",
          character_count_max_length_value: ::Post::MAX_BODY_LENGTH.to_s,
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
    render RubyUI::FormField.new do
      render RubyUI::FormFieldLabel.new(for: :comment_body) { t("comments.comment_form.body_label") }
      f.text_area :body,
        rows: 4,
        class: text_area_classes(@comment.errors[:body]),
        placeholder: t("comments.comment_form.body_placeholder"),
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

  def text_input_classes(errors)
    state_classes = errors.none? ? "border-border-muted hover:border-border-strong focus:ring-state-info" : "border-destructive focus:ring-destructive"
    "w-full px-3 py-2 rounded-lg border bg-surface-elevated text-content placeholder:text-content-muted focus:border-transparent transition-all duration-200 #{state_classes}"
  end

  def text_area_classes(errors)
    state_classes = errors.none? ? "border-border-muted hover:border-border-strong focus:ring-state-info" : "border-destructive focus:ring-destructive"
    "w-full px-4 py-3 rounded-lg border bg-surface-elevated text-content placeholder:text-content-muted focus:border-transparent transition-all duration-200 resize-none #{state_classes}"
  end
end
