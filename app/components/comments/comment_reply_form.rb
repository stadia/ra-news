# frozen_string_literal: true

class Components::Comments::CommentReplyForm < Components::Base
  include Phlex::Rails::Helpers::FormWith
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
          controller: "character-count guest-name",
          character_count_max_length_value: ::Comment::MAX_BODY_LENGTH.to_s
        }
      ) do
        reply_header
        reply_form_fields
      end
    end
  end

  private

  def reply_header
    h5(class: "text-xs font-semibold text-gray-400 mb-3 flex items-center uppercase tracking-wide") do
      Hero::ArrowUturnLeft(variant: :outline, class: "w-3 h-3 mr-1.5 text-blue-400")
      plain "답글 작성"
    end
  end

  def reply_form_fields
    form_with(
      model: [ @article, @comment ],
      url: article_comments_path(@article),
      local: false,
      class: "space-y-3",
      data: { action: "turbo:submit-end->reply-form#close" }
    ) do |f|
      f.hidden_field :parent_id, value: @parent_comment.id

      error_messages if @comment.errors.any?
      guest_fields(f) unless view_context.authenticated?
      body_field(f)
      action_buttons(f)
    end
  end

  def error_messages
    div(class: "bg-red-900 bg-opacity-50 border border-red-500 text-red-200 px-4 py-3 rounded-lg") do
      div(class: "flex items-center mb-2") do
        Hero::ExclamationCircle(variant: :mini, class: "w-5 h-5 mr-2")
        h5(class: "font-medium") { "오류가 발생했습니다:" }
      end
      ul(class: "list-disc list-inside space-y-1 text-sm") do
        @comment.errors.each do |error|
          li { error.full_message }
        end
      end
    end
  end

  def guest_fields(f)
    div(class: "grid gap-3 sm:grid-cols-2") do
      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: :comment_guest_name) { "이름 (필수)" }
        f.text_field :guest_name,
          class: "w-full px-3 py-2 rounded-lg border bg-gray-700 text-white placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200 text-sm #{@comment.errors[:guest_name].none? ? 'border-gray-600 hover:border-gray-500' : 'border-red-500 focus:ring-red-500'}",
          placeholder: "이름을 입력하세요",
          data: { guest_name_target: "input", action: "change->guest-name#save" }
        @comment.errors[:guest_name].each do |msg|
          render RubyUI::FormFieldError.new { msg }
        end
      end

      render RubyUI::FormField.new do
        render RubyUI::FormFieldLabel.new(for: :comment_guest_password) { "비밀번호 (필수)" }
        f.password_field :guest_password,
          class: "w-full px-3 py-2 rounded-lg border bg-gray-700 text-white placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200 text-sm #{@comment.errors[:guest_password].none? ? 'border-gray-600 hover:border-gray-500' : 'border-red-500 focus:ring-red-500'}",
          placeholder: "최소 4자 이상"
        @comment.errors[:guest_password].each do |msg|
          render RubyUI::FormFieldError.new { msg }
        end
      end
    end
  end

  def body_field(f)
    render RubyUI::FormField.new do
      f.text_area :body,
        rows: 3,
        class: "w-full px-4 py-2 rounded-lg border bg-gray-700 text-white placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200 resize-none text-sm #{@comment.errors[:body].none? ? 'border-gray-600 hover:border-gray-500' : 'border-red-500 focus:ring-red-500'}",
        placeholder: "답글을 입력하세요...",
        maxlength: ::Comment::MAX_BODY_LENGTH,
        data: { character_count_target: "input", action: "input->character-count#updateCount" }
      div(class: "text-xs text-gray-500 text-right") do
        span(data: { character_count_target: "counter" }) { "0" }
        plain "/#{::Comment::MAX_BODY_LENGTH}"
      end
      @comment.errors[:body].each do |msg|
        render RubyUI::FormFieldError.new { msg }
      end
    end
  end

  def action_buttons(f)
    div(class: "flex items-center justify-end gap-2") do
      render RubyUI::Button.new(variant: :ghost,
        class: "font-medium text-gray-400 hover:text-gray-200 transition-colors hover:bg-transparent",
          data: { action: "reply-form#toggle" }) { "취소" }
      f.submit "답글 작성",
        class: "inline-flex items-center px-4 py-1.5 bg-blue-600 hover:bg-blue-700 text-white text-xs font-medium rounded-md transition-colors duration-200"
    end
  end
end
