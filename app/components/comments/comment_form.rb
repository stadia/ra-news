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
      div(
        class: "bg-gray-700 rounded-xl p-6 border border-gray-600",
        data: {
          controller: "character-count guest-name comment-form",
          character_count_max_length_value: ::Comment::MAX_BODY_LENGTH.to_s,
          action: "turbo:submit-end->comment-form#reset"
        }
      ) do
        form_header
        comment_form_fields
      end
    end
  end

  private

  def form_header
    h4(class: "text-lg font-semibold text-gray-100 mb-4 flex items-center") do
      Hero::PencilSquare(variant: :outline, class: "w-5 h-5 mr-2 text-blue-400")
      plain "댓글 작성"
    end
  end

  def comment_form_fields
    form_with(model: [ @article, @comment ], url: article_comments_path(@article), local: false, class: "space-y-4") do |f|
      error_messages if @comment.errors.any?
      guest_fields(f) unless view_context.authenticated?
      body_field(f)
      submit_section(f)
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
    div(class: "space-y-2") do
      f.label :guest_name, "이름 또는 이메일 (필수)", class: "block text-sm font-medium text-gray-300"
      f.text_field :guest_name,
        class: "w-full px-3 py-2 rounded-lg border bg-white text-gray-900 placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200 #{@comment.errors[:guest_name].none? ? 'border-gray-600 hover:border-gray-500' : 'border-red-500 focus:ring-red-500'}",
        placeholder: "이름이나 이메일을 입력하세요",
        data: { guest_name_target: "input", action: "change->guest-name#save" }
    end

    div(class: "space-y-2") do
      f.label :guest_password, "비밀번호 (필수, 삭제 시 필요)", class: "block text-sm font-medium text-gray-300"
      f.password_field :guest_password,
        class: "w-full px-3 py-2 rounded-lg border bg-white text-gray-900 placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200 #{@comment.errors[:guest_password].none? ? 'border-gray-600 hover:border-gray-500' : 'border-red-500 focus:ring-red-500'}",
        placeholder: "최소 4자 이상의 비밀번호를 입력하세요"
      p(class: "text-xs text-gray-400") { "댓글 삭제 시 비밀번호가 필요합니다." }
    end

    div(class: "border-t border-gray-600 pt-4") do
      p(class: "text-sm text-gray-400 mb-4") do
        Hero::InformationCircle(variant: :outline, class: "w-4 h-4 inline mr-1")
        plain "이미 계정이 있으신가요? "
        link_to("로그인", new_session_path, class: "text-blue-400 hover:text-blue-300")
        plain " 후 댓글을 작성하세요."
      end
    end
  end

  def body_field(f)
    div(class: "space-y-2") do
      f.label :body, "댓글 내용", class: "block text-sm font-medium text-gray-300"
      f.text_area :body,
        rows: 4,
        class: "w-full px-4 py-3 rounded-lg border bg-white text-gray-900 placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200 resize-none #{@comment.errors[:body].none? ? 'border-gray-600 hover:border-gray-500' : 'border-red-500 focus:ring-red-500'}",
        placeholder: "댓글을 입력하세요...",
        maxlength: ::Comment::MAX_BODY_LENGTH,
        data: { character_count_target: "input", action: "input->character-count#updateCount" }
      div(class: "text-xs text-gray-400 text-right") do
        span(data: { character_count_target: "counter" }) { "0" }
        plain "/#{::Comment::MAX_BODY_LENGTH}"
      end
    end
  end

  def submit_section(f)
    div(class: "flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4") do
      div(class: "text-xs text-gray-400") do
        Hero::InformationCircle(variant: :outline, class: "w-4 h-4 inline mr-1")
        plain "정중하고 건설적인 댓글을 작성해 주세요."
      end
      render RubyUI::Button.new(
        type: "submit",
        size: :xl,
        class:
          "inline-flex items-center bg-blue-600 hover:bg-blue-700 focus:bg-blue-700 text-white font-medium rounded-lg transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:ring-offset-gray-800",
      ) { "댓글 작성" }
    end
  end
end
