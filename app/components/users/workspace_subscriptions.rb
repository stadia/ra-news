# frozen_string_literal: true

class Components::Users::WorkspaceSubscriptions < Components::Base
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
              plain "워크스페이스를 연결하면 Slack이 설치 시점에 선택한 채널로 기사 알림을 보냅니다."
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
              div(class: "rounded-xl border border-border-strong bg-surface p-5 space-y-4") do
                div(class: "flex items-center justify-between gap-4") do
                  div do
                    h3(class: "font-semibold text-content") { workspace.team_name }
                    p(class: "text-xs text-content-muted mt-1") { workspace.team_id }
                  end

                  status_badge(workspace)
                end

                render RubyUI::FormField.new do
                  render RubyUI::FormFieldLabel.new { "연결된 채널" }
                  div(class: input_classes) do
                    plain "##{workspace.channel_name}"
                  end
                end

                p(class: "text-xs text-content-muted") do
                  plain "설치 시 Slack에서 선택한 채널이 고정됩니다. 채널을 바꾸려면 Slack 앱을 다시 설치하거나 워크스페이스 설정을 갱신해야 합니다."
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
    @workspaces ||= SlackWorkspace.delivery_ready.order(:team_name)
  end

  def status_badge(workspace)
    text, classes = if workspace.active?
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
