# typed: true
# frozen_string_literal: true

class Views::Devise::Mailer::ConfirmationInstructions < Views::Base
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
        t("devise.mailer.confirmation_instructions.greeting", recipient: recipient_name)
      end
      p(style: "margin:0 0 24px;color:#cbd5e1;") do
        t("devise.mailer.confirmation_instructions.instruction")
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
