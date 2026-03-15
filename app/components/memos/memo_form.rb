# frozen_string_literal: true

class Components::Memos::MemoForm < Components::Base
  include Phlex::Rails::Helpers::FormWith
  include PhlexIcons

  def initialize(memo:)
    @memo = memo
  end

  def view_template
    form_with(model: @memo, class: "space-y-5") do |f|
      error_messages if @memo.errors.any?

      div(class: "space-y-2") do
        f.label :body, "내용", class: "block text-sm font-medium text-gray-300"
        f.text_area :body,
          rows: 6,
          maxlength: ::Memo::MAX_BODY_LENGTH,
          class: "w-full px-4 py-3 rounded-lg border bg-white text-gray-900 placeholder-gray-400 focus:ring-2 focus:ring-green-500 focus:border-transparent transition-all resize-none #{@memo.errors[:body].none? ? 'border-gray-600' : 'border-red-500'}",
          placeholder: "무슨 생각을 하고 계신가요?",
          data: {
            controller: "character-count",
            character_count_max_length_value: ::Memo::MAX_BODY_LENGTH.to_s,
            action: "input->character-count#updateCount",
            character_count_target: "input"
          }
        div(class: "flex items-center justify-between text-xs text-gray-400") do
          span { "최대 #{::Memo::MAX_BODY_LENGTH}자" }
          div do
            span(data: { character_count_target: "counter" }) { "0" }
            plain "/#{::Memo::MAX_BODY_LENGTH}"
          end
        end
      end

      div(class: "flex items-center justify-between pt-2") do
        div(class: "flex items-center gap-2 text-xs text-gray-500") do
          Hero::GlobeAlt(variant: :outline, class: "w-4 h-4 text-green-500")
          plain "Fediverse에 공유됩니다"
        end
        render RubyUI::Button.new(
          type: "submit",
          size: :lg,
          class: "bg-green-600 hover:bg-green-700 text-white font-medium rounded-lg px-6"
        ) { "작성하기" }
      end
    end
  end

  private

  def error_messages
    div(class: "bg-red-900/50 border border-red-500 text-red-200 px-4 py-3 rounded-lg") do
      h5(class: "font-medium mb-2") { "오류가 발생했습니다:" }
      ul(class: "list-disc list-inside space-y-1 text-sm") do
        @memo.errors.each do |error|
          li { error.full_message }
        end
      end
    end
  end
end
