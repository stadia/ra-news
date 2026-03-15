# frozen_string_literal: true

class Views::Memos::New < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::LinkTo

  def initialize(memo:)
    @memo = memo
  end

  def view_template
    content_for :title, "새 단문 작성"

    section(class: "max-w-2xl mx-auto py-12 px-4 sm:px-6") do
      div(class: "mb-6") do
        p(class: "text-xs font-semibold tracking-[0.22em] uppercase text-emerald-300/80 mb-2") { "Memo" }
        render RubyUI::Heading.new(level: 1, class: "font-bold text-white text-3xl sm:text-4xl tracking-tight") { "새 단문 작성" }
        p(class: "mt-2 text-slate-300/80 text-sm") { "짧은 생각이나 메모를 Fediverse에 공유할 수 있습니다." }
      end

      div(class: "relative overflow-hidden rounded-2xl border border-slate-700/70 bg-slate-900/70 shadow-2xl p-5 sm:p-7") do
        render Components::Memos::MemoForm.new(memo: @memo)
      end

      div(class: "mt-5 flex items-center justify-end") do
        link_to memos_path,
          class: "inline-flex items-center justify-center rounded-xl px-4 py-2.5 border border-slate-600 bg-slate-800/80 hover:bg-slate-700 text-slate-100 font-semibold transition-all" do
          "목록으로 돌아가기"
        end
      end
    end
  end
end
