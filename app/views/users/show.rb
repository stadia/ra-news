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
      div(class: "mb-2 px-1") do
        render RubyUI::Heading.new(level: 1, class: "text-3xl font-bold text-content tracking-tight") { "사용자 정보" }
        p(class: "mt-1 text-content-muted") { "계정의 개인 정보와 설정을 관리하세요." }
      end

      render Components::Users::User.new(user: @user)

      div(class: "flex items-center gap-2 mt-4 px-1") do
        render RubyUI::Link.new(
          href: edit_users_path,
          class: "flex items-center justify-center gap-2 rounded-xl bg-surface hover:bg-surface-muted text-content font-bold text-sm border border-border-strong transition-all active:scale-95 shadow-lg"
        ) do
          Hero::PencilSquare(variant: :outline, class: "w-4 h-4")
          plain "정보 수정"
        end

        render RubyUI::Link.new(
          href: password_users_path,
          class: "flex items-center justify-center gap-2 rounded-xl bg-surface hover:bg-surface-muted text-content font-bold text-sm border border-border-strong transition-all active:scale-95 shadow-lg"
        ) do
          Hero::Key(variant: :outline, class: "w-4 h-4")
          plain "비밀번호 변경"
        end
      end
    end
  end
end
