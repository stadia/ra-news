# frozen_string_literal: true

class Components::PushNotifications::PromptModal < Components::Base
  include PhlexIcons

  def view_template
    div(
      data: { push_notifications_target: "modal" },
      class: "fixed inset-0 z-50 hidden",
      role: "dialog",
      "aria-modal": "true",
      "aria-labelledby": "push-notification-modal-title"
    ) do
      div(
        class: "absolute inset-0 bg-app/70 backdrop-blur-sm",
        data: { action: "click->push-notifications#dismiss" }
      )

      div(class: "relative z-10 flex min-h-full items-center justify-center p-4") do
        div(class: "w-full max-w-md overflow-hidden rounded-3xl border border-border-strong bg-app/95 shadow-2xl") do
          div(class: "px-6 py-8 text-center") do
            div(class: "mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-brand/20 text-brand-soft") do
              Hero::Bell(variant: :solid, class: "h-7 w-7")
            end

            h2(id: "push-notification-modal-title", class: "text-2xl font-bold text-content") { "알림 설정" }
            p(class: "mt-3 text-sm leading-6 text-content-secondary") do
              plain "내 댓글에 답글이 달리면 바로 알 수 있도록"
              br
              plain "브라우저 알림을 활성화해 보세요."
            end
          end

          div(class: "border-t border-border-strong/80") do
            render RubyUI::Button.new(variant: :primary, size: :lg,
                    data: { action: "click->push-notifications#enable" },
                    class: "w-full font-semibold text-brand-soft transition hover:bg-surface") { "설정" }
          end

          div(class: "border-t border-border-strong/80") do
            render RubyUI::Button.new(variant: :ghost, size: :lg,
                    data: { action: "click->push-notifications#dismiss" },
                    class: "w-full font-medium text-content-secondary transition hover:bg-surface") { "나중에 하기" }
          end
        end
      end
    end
  end
end
