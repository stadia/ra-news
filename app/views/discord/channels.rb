# frozen_string_literal: true

class Views::Discord::Channels < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(guild_name:, channels:)
    @guild_name = guild_name
    @channels = channels
  end

  def view_template
    div(class: "max-w-md mx-auto mt-8 p-6") do
      render RubyUI::Heading.new(level: 1, class: "text-xl font-bold mb-4") { "#{@guild_name} — 채널 선택" }
      p(class: "text-sm text-content-muted mb-4") { "AlNews 알림을 받을 채널을 선택하세요." }

      form_with(url: discord_setup_path, method: :post, class: "space-y-2",
                data: { controller: "channel-select" }) do |form|
        form.hidden_field :channel_name, data: { "channel-select-target": "channelName" }
        @channels.each do |channel|
          label(class: "flex items-center gap-3 p-3 rounded border border-border-muted cursor-pointer") do
            form.radio_button :channel_id, channel["id"], required: true,
              data: { action: "change->channel-select#select", "channel-select-name-param": channel["name"] }
            span(class: "font-medium") { "##{channel["name"]}" }
          end
        end

        div(class: "pt-4") do
          render RubyUI::Button.new(
            type: "submit",
            variant: :primary,
            class: "w-full rounded-md bg-brand-solid hover:bg-brand-solid-hover text-brand-foreground font-medium cursor-pointer"
          ) { "연결" }
        end
      end
    end
  end
end
