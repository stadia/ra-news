# frozen_string_literal: true
# rbs_inline: enabled

class Views::Oauth::Result < Views::Base
  include Phlex::Rails::Helpers::ContentFor

  def initialize(provider:, success:, channel_name: nil, error: nil)
    @provider = provider
    @success = success
    @channel_name = channel_name
    @error = error
  end

  def view_template
    provider_name = @provider == "slack" ? "Slack" : "Discord"
    title = @success ? "#{provider_name} 연결 완료" : "#{provider_name} 연결 실패"

    content_for(:title, "#{title} | AlNews")

    div(class: "max-w-lg mx-auto mt-16 px-4 space-y-6") do
      render RubyUI::Card.new do
        render RubyUI::CardHeader.new do
          div(class: "flex items-center gap-3") do
            if @success
              render PhlexIcons::Hero::CheckCircle.new(variant: :outline, class: "w-8 h-8 text-success")
            else
              render PhlexIcons::Hero::XCircle.new(variant: :outline, class: "w-8 h-8 text-destructive")
            end
            render RubyUI::Heading.new(level: 2) { title }
          end
        end

        render RubyUI::CardContent.new do
          if @success
            div(class: "space-y-2") do
              p(class: "text-content-secondary") do
                if @channel_name.present?
                  "#{@channel_name} #{@provider == "slack" ? "워크스페이스" : "서버"}가 성공적으로 연결되었습니다."
                else
                  "#{provider_name}이 성공적으로 연결되었습니다."
                end
              end
            end
          else
            div(class: "space-y-2") do
              p(class: "text-content-secondary") { "#{provider_name} 연결 중 오류가 발생했습니다." }
              if @error.present?
                p(class: "text-sm text-destructive bg-destructive/10 rounded px-3 py-2") { @error }
              end
            end
          end
        end
      end

      if @success
        render RubyUI::Card.new do
          render RubyUI::CardHeader.new do
            render RubyUI::Heading.new(level: 3) { "알림 설정 안내" }
          end

          render RubyUI::CardContent.new do
            div(class: "space-y-3 text-sm text-content-secondary") do
              p { "#{provider} Webhook이 설정되었습니다. 선택한 채널로 새 기사 알림이 자동으로 발송됩니다." }
              p { "별도의 봇 초대나 추가 설정 없이 바로 알림이 전송됩니다." }
            end
          end
        end
      end

      div(class: "text-center") do
        render RubyUI::Link.new(href: root_path) { "홈으로 돌아가기" }
      end
    end
  end
end
