# frozen_string_literal: true

class Components::PushNotifications::PromptModal < Components::Base
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
              svg(class: "h-7 w-7", "viewBox": "0 0 24 24", fill: "currentColor", "aria-hidden": "true") do |s|
                s.path(d: "M12 2a7 7 0 0 0-7 7v3.111l-.894 1.789A1 1 0 0 0 5 15h14a1 1 0 0 0 .894-1.447L19 12.11V9a7 7 0 0 0-7-7Zm0 20a3 3 0 0 0 2.995-2.824L15 19h-6a3 3 0 0 0 2.824 2.995L12 22Z")
              end
            end

            h2(id: "push-notification-modal-title", class: "text-2xl font-bold text-white") { "알림 설정" }
            p(class: "mt-3 text-sm leading-6 text-slate-300") do
              plain "내 댓글에 답글이 달리면 바로 알 수 있도록"
              br
              plain "브라우저 알림을 활성화해 보세요."
            end
          end

          div(class: "border-t border-slate-700/80") do
            button(
              type: "button",
              class: "w-full px-6 py-4 text-sm font-semibold text-green-300 transition hover:bg-slate-800",
              data: { action: "click->push-notifications#enable" }
            ) { "설정" }
          end

          div(class: "border-t border-slate-700/80") do
            button(
              type: "button",
              class: "w-full px-6 py-4 text-sm font-medium text-slate-300 transition hover:bg-slate-800",
              data: { action: "click->push-notifications#dismiss" }
            ) { "나중에 하기" }
          end
        end
      end
    end
  end
end
