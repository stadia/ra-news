# frozen_string_literal: true

class Views::Memos::Index < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo
  include PhlexIcons

  def initialize(pagy:, memos:)
    @pagy = pagy
    @memos = memos
  end

  def view_template
    content_for :title, "단문 | Ruby-News"

    div(class: "max-w-2xl mx-auto") do
      header_section
      memos_list
    end
  end

  private

  def header_section
    div(class: "flex items-center justify-between mb-8") do
      div do
        render RubyUI::Heading.new(level: 1, class: "font-bold text-white mb-1") { "단문" }
        p(class: "text-sm text-gray-400") { "#{@pagy.count}개의 단문" }
      end
      if view_context.authenticated?
        link_to new_memo_path, class: "inline-flex items-center gap-2 px-4 py-2 bg-green-600 hover:bg-green-700 text-white text-sm font-medium rounded-lg transition-colors" do
          Hero::PencilSquare(variant: :outline, class: "w-4 h-4")
          plain "새 단문 작성"
        end
      end
    end
  end

  def memos_list
    div(class: "space-y-4", id: "memos_list") do
      if @memos.any?
        @memos.each do |memo|
          render Components::Memos::MemoCard.new(memo: memo)
        end
        render Components::Pagination.new(pagy: @pagy)
      else
        empty_state
      end
    end
  end

  def empty_state
    div(class: "text-center py-16") do
      Hero::ChatBubbleOvalLeft(variant: :outline, class: "w-12 h-12 text-gray-600 mx-auto mb-4")
      p(class: "text-gray-400 text-lg") { "아직 단문이 없습니다." }
      if view_context.authenticated?
        link_to "첫 번째 단문 작성하기", new_memo_path, class: "mt-4 inline-block text-green-400 hover:text-green-300"
      end
    end
  end
end
