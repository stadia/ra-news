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
        class: "absolute inset-0 bg-slate-950/70 backdrop-blur-sm",
        data: { action: "click->push-notifications#dismiss" }
      )

      div(class: "relative z-10 flex min-h-full items-center justify-center p-4") do
        div(class: "w-full max-w-md overflow-hidden rounded-3xl border border-slate-700 bg-slate-900/95 shadow-2xl") do
          div(class: "px-6 py-8 text-center") do
            div(class: "mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-green-500/20 text-green-300") do
              Hero::Bell(variant: :solid, class: "h-7 w-7")
            end

            h2(id: "push-notification-modal-title", class: "text-2xl font-bold text-white") { "알림 설정" }
            p(class: "mt-3 text-sm leading-6 text-slate-300") do
              plain "내 댓글에 답글이 달리면 바로 알 수 있도록"
              br
              plain "브라우저 알림을 활성화해 보세요."
            end
          end

          div(class: "border-t border-slate-700/80") do
            render RubyUI::Button.new(variant: :primary, size: :lg,
                    data: { action: "click->push-notifications#enable" },
                    class: "w-full font-semibold text-green-300 transition hover:bg-slate-800") { "설정" }
          end

          div(class: "border-t border-slate-700/80") do
            render RubyUI::Button.new(variant: :ghost, size: :lg,
                    data: { action: "click->push-notifications#dismiss" },
                    class: "w-full font-medium text-slate-300 transition hover:bg-slate-800") { "나중에 하기" }
          end
        end
      end
    end
  end
end
