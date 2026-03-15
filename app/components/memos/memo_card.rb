# frozen_string_literal: true

class Components::Memos::MemoCard < Components::Base
  include Phlex::Rails::Helpers::LinkTo
  include PhlexIcons

  def initialize(memo:)
    @memo = memo
  end

  def view_template
    div(class: "bg-gray-800 rounded-xl border border-gray-700 hover:border-gray-600 transition-all duration-200") do
      div(class: "p-5") do
        memo_header
        memo_body
        memo_footer
      end
    end
  end

  private

  def memo_header
    div(class: "flex items-center justify-between mb-3") do
      div(class: "flex items-center gap-2") do
        div(class: "w-7 h-7 bg-green-700 rounded-full flex items-center justify-center") do
          span(class: "text-white text-xs font-bold") { @memo.user.name.to_s.first.upcase }
        end
        div do
          span(class: "text-sm font-medium text-gray-300") { @memo.user.name }
          span(class: "text-xs text-gray-500 ml-2") do
            plain "· #{view_context.time_ago_in_words_korean(@memo.created_at)} 전"
          end
        end
      end
    end
  end

  def memo_body
    link_to memo_path(@memo), class: "block" do
      p(class: "text-gray-100 leading-relaxed whitespace-pre-wrap line-clamp-6 hover:text-white transition-colors") do
        plain @memo.body
      end
    end
  end

  def memo_footer
    div(class: "flex items-center gap-4 mt-4 text-xs text-gray-500") do
      link_to memo_path(@memo), class: "flex items-center gap-1 hover:text-gray-300 transition-colors" do
        Hero::ChatBubbleLeft(variant: :outline, class: "w-3.5 h-3.5")
        plain "#{@memo.comments_count}"
      end
      if @memo.federated_url.present?
        span(class: "flex items-center gap-1 text-green-600") do
          Hero::GlobeAlt(variant: :outline, class: "w-3.5 h-3.5")
          plain "연합"
        end
      end
    end
  end
end
