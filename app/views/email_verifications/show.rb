# frozen_string_literal: true

class Views::EmailVerifications::Show < Views::Base
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::FormWith

  def view_template
    content_for :title, "이메일 인증"

    div(class: "space-y-6 max-w-6xl mx-auto") do
      render RubyUI::Heading.new(level: 1, class: "font-bold") { "이메일 인증" }

      div(class: "space-y-4") do
        p(class: "text-slate-300") {
          "회원가입 시 입력하신 이메일 주소로 인증 메일을 발송했습니다."
        }
        p(class: "text-slate-300") {
          "메일함을 확인하시고 인증 링크를 클릭해주세요. 링크는 24시간 동안 유효합니다."
        }
      end

      form_with(url: resend_email_verification_path, method: :post, class: "mt-4") do |_f|
        render RubyUI::Button.new(
          type: "submit",
          variant: :outline,
          size: :lg,
          class: "rounded-md border border-slate-600 text-slate-300 hover:bg-slate-700"
        ) { "인증 메일 재발송" }
      end
    end
  end
end
