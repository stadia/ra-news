# frozen_string_literal: true

class Views::Users::Show < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include PhlexIcons

  def initialize(user:)
    @user = user
  end

  def view_template
    content_for :title, "사용자 정보"

    div(class: "max-w-2xl mx-auto py-12 px-4 sm:px-6") do
      div(class: "flex flex-col sm:flex-row sm:items-end justify-between gap-4 mb-2 px-1") do
        div do
          render RubyUI::Heading.new(level: 1, class: "text-3xl font-bold text-white tracking-tight") { "사용자 정보" }
          p(class: "mt-1 text-slate-400") { "계정의 개인 정보와 설정을 관리하세요." }
        end

        div(class: "flex items-center gap-2") do
          render RubyUI::Link.new(
            href: edit_users_path,
            class: "flex items-center justify-center gap-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-100 font-bold text-sm border border-slate-700 transition-all active:scale-95 shadow-lg shadow-black/20"
          ) do
            Hero::PencilSquare(variant: :outline, class: "w-4 h-4")
            plain "정보 수정"
          end

          render RubyUI::Link.new(
            href: password_users_path,
            class: "flex items-center justify-center gap-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-100 font-bold text-sm border border-slate-700 transition-all active:scale-95 shadow-lg shadow-black/20"
          ) do
            Hero::Key(variant: :outline, class: "w-4 h-4")
            plain "비밀번호 변경"
          end
        end
      end

      render Components::Users::User.new(user: @user)
    end
  end
end
