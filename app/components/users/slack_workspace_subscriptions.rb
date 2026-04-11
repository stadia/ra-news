# frozen_string_literal: true

class Components::Users::SlackWorkspaceSubscriptions < Components::Base
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::ButtonTo
  include PhlexIcons

  def initialize(user:)
    @user = user
  end

  def view_template
    render RubyUI::Card.new(class: "w-full max-w-2xl bg-app/40 border-border-subtle rounded-2xl overflow-hidden shadow-2xl my-6") do
      render RubyUI::CardContent.new(class: "px-6 py-8 sm:px-10") do
        div(class: "flex items-start justify-between gap-4") do
          div do
            render RubyUI::Heading.new(level: 2, class: "text-xl font-bold text-content") { "Slack 채널 구독" }
            p(class: "mt-1 text-sm text-content-muted") do
              plain "워크스페이스를 연결하고, 각 워크스페이스마다 기사 알림을 보낼 채널 하나를 선택합니다."
            end
          end

          if SlackConfig.configured?
            render RubyUI::Link.new(
              href: slack_install_path,
              class: "inline-flex items-center justify-center gap-2 rounded-xl bg-brand-solid hover:bg-brand-solid-hover text-brand-foreground font-bold text-sm transition-all active:scale-95 shadow-lg"
            ) do
              Hero::Plus(variant: :outline, class: "w-4 h-4")
              plain "워크스페이스 연결"
            end
          end
        end

        if workspaces.empty?
          p(class: "mt-6 text-sm text-content-muted") { "아직 연결된 Slack 워크스페이스가 없습니다." }
        else
          div(class: "mt-6 space-y-5") do
            workspaces.each do |workspace|
              subscription = subscriptions_by_workspace_id[workspace.id]

              div(class: "rounded-xl border border-border-strong bg-surface p-5 space-y-4") do
                div(class: "flex items-center justify-between gap-4") do
                  div do
                    h3(class: "font-semibold text-content") { workspace.team_name }
                    p(class: "text-xs text-content-muted mt-1") { workspace.team_id }
                  end

                  status_badge(workspace, subscription)
                end

                p(class: "text-xs text-content-muted") do
                  plain "채널 목록 JSON: "
                  a(
                    href: slack_workspace_channels_path(workspace, format: :json),
                    target: "_blank",
                    rel: "noopener noreferrer",
                    class: "text-link hover:text-link-hover underline"
                  ) { "조회" }
                end

                form_with(
                  url: slack_workspace_subscription_path(workspace),
                  method: subscription&.persisted? ? :patch : :post,
                  class: "space-y-4"
                ) do |form|
                  render RubyUI::FormField.new do
                    render RubyUI::FormFieldLabel.new(for: "channel_id_#{workspace.id}") { "채널 ID" }
                    form.text_field :channel_id,
                      name: "user_workspace_subscription[channel_id]",
                      id: "channel_id_#{workspace.id}",
                      value: subscription&.channel_id,
                      class: input_classes,
                      placeholder: "C0123456789"
                  end

                  render RubyUI::FormField.new do
                    render RubyUI::FormFieldLabel.new(for: "channel_name_#{workspace.id}") { "채널 이름" }
                    form.text_field :channel_name,
                      name: "user_workspace_subscription[channel_name]",
                      id: "channel_name_#{workspace.id}",
                      value: subscription&.channel_name,
                      class: input_classes,
                      placeholder: "ruby-news"
                  end

                  div(class: "flex items-center justify-end gap-3") do
                    render RubyUI::Button.new(
                      type: "submit",
                      class: "inline-flex items-center justify-center gap-2 rounded-xl bg-brand-solid hover:bg-brand-solid-hover text-brand-foreground font-bold text-sm transition-all active:scale-95 shadow-lg px-4 py-2"
                    ) do
                      Hero::Check(variant: :outline, class: "w-4 h-4")
                      plain "채널 저장"
                    end
                  end
                end

                if subscription&.persisted?
                  div(class: "flex justify-end") do
                    button_to(
                      slack_workspace_subscription_path(workspace),
                      method: :delete,
                      class: "inline-flex items-center justify-center gap-2 rounded-xl bg-surface hover:bg-surface-muted text-content font-bold text-sm border border-border-strong transition-all active:scale-95 shadow-lg px-4 py-2"
                    ) do
                      Hero::Trash(variant: :outline, class: "w-4 h-4")
                      plain "비활성화"
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  private

  attr_reader :user

  def workspaces
    @workspaces ||= SlackWorkspace.active.order(:team_name)
  end

  def subscriptions_by_workspace_id
    @subscriptions_by_workspace_id ||= user.user_workspace_subscriptions.index_by(&:slack_workspace_id)
  end

  def status_badge(workspace, subscription)
    text, classes = if subscription&.active?
      [ "채널 설정됨", "text-success bg-success/10 ring-1 ring-success/20" ]
    elsif workspace.active?
      [ "워크스페이스 연결됨", "text-content-muted bg-surface ring-1 ring-border" ]
    else
      [ "확인 필요", "text-warning bg-warning/10 ring-1 ring-warning/20" ]
    end

    span(class: "inline-flex items-center rounded-full px-2.5 py-1 text-xs font-medium #{classes}") { text }
  end

  def input_classes
    "block w-full bg-surface/50 border border-border-strong rounded-xl px-4 py-3 text-content placeholder:text-content-muted focus:outline-none focus:ring-2 focus:ring-brand/30 focus:border-brand/50 transition-all duration-200"
  end
end
