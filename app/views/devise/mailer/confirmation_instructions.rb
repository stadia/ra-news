# frozen_string_literal: true

class Views::Devise::Mailer::ConfirmationInstructions < Views::Base
  include Phlex::Rails::Helpers::T

  def initialize(resource:, confirmation_url:)
    @resource = resource
    @confirmation_url = confirmation_url
  end

  def view_template
    render Components::Mailers::Layout.new(
      eyebrow: "Account Security",
      title: t("devise.mailer.confirmation_instructions.title"),
      intro: t("devise.mailer.confirmation_instructions.message")
    ) do
      p(style: "margin:0 0 14px;color:#f8fafc;") do
        t("devise.mailer.confirmation_instructions.greeting", name: recipient_name)
      end
      p(style: "margin:0 0 24px;color:#cbd5e1;") do
        "아래 버튼을 눌러 이메일 인증을 완료해주세요. 요청하지 않으셨다면 이 메일은 무시하셔도 됩니다."
      end
      table(role: "presentation", cellpadding: "0", cellspacing: "0", width: "100%", style: "margin:0 0 24px;border-collapse:collapse;background-color:#243041;border-top:2px solid rgb(34, 197, 94);border-radius:14px;") do
        tr do
          td(style: "padding:18px 18px 10px;") do
            p(style: "margin:0 0 6px;font-size:11px;line-height:1.2;font-weight:700;letter-spacing:0.14em;text-transform:uppercase;color:#94a3b8;") { "Confirmation Link" }
            p(style: "margin:0;color:#e2e8f0;font-size:15px;line-height:1.6;") { "이 링크는 계정 활성화에 한 번 사용됩니다." }
          end
        end
      end
      p(style: "margin:0 0 24px;") do
        a(
          href: @confirmation_url,
          style: "display:inline-block;padding:12px 18px;background-color:rgb(34, 197, 94);border-radius:999px;color:#08130c;font-size:14px;font-weight:700;text-decoration:none;"
        ) do
          t("devise.mailer.confirmation_instructions.action")
        end
      end
      p(style: "margin:0;color:#94a3b8;font-size:12px;line-height:1.8;word-break:break-all;") do
        @confirmation_url
      end
    end
  end

  private

  def recipient_name
    @resource.name.presence || @resource.email
  end
end
