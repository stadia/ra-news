# frozen_string_literal: true

class Components::Flash < Components::Base
  def view_template
    view_context.flash.each do |type, message|
      next if message.blank?

      render RubyUI::Alert.new(variant: alert_variant(type), id: type.to_s, class: "mb-5") do
        render RubyUI::AlertDescription.new do
          plain message_text(message)
        end
      end
    end
  end

  private

  def alert_variant(type)
    case type.to_sym
    when :notice
      :success
    when :alert
      :destructive
    when :warning
      :warning
    end
  end

  def message_text(message)
    message.is_a?(Array) ? message.join(", ") : message.to_s
  end
end
