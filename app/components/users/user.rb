# frozen_string_literal: true

class Components::Users::User < Components::Base
  include Phlex::Rails::Helpers::DOMID

  def initialize(user:)
    @user = user
  end

  def view_template
    render RubyUI::Card.new(id: dom_id(@user), class: "w-full max-w-2xl bg-slate-900/40 border-slate-800 rounded-2xl overflow-hidden shadow-2xl my-6") do
      # Profile Header/Banner
      div(class: "h-24 bg-linear-to-r from-slate-800 to-slate-700/50 border-b border-slate-800")

      render RubyUI::CardContent.new(class: "px-6 pb-8 sm:px-10 sm:pb-10 pt-0") do
        # Avatar & Primary Identity
        div(class: "flex flex-col sm:flex-row items-center sm:items-end gap-6 -mt-12 mb-10") do
          render RubyUI::Avatar.new(size: :xl, class: "h-24 w-24 ring-4 ring-slate-900 bg-slate-900 shadow-xl") do
            render RubyUI::AvatarFallback.new(class: "bg-green-600 text-white text-3xl font-bold") do
              initials
            end
          end

          div(class: "text-center sm:text-left pb-1 flex-1") do
            h2(class: "text-3xl font-bold text-white tracking-tight") { @user.name }
            p(class: "text-slate-400 font-medium text-lg mt-1") { @user.email_address }
          end
        end

        # Details Grid
        div(class: "grid grid-cols-1 md:grid-cols-2 gap-x-12 gap-y-8 pt-8 border-t border-slate-800/60") do
          detail_field("이메일 주소", @user.email_address)
          detail_field("사용자 이름", @user.name)
        end
      end
    end
  end

  def badge(text)
    render RubyUI::Badge.new(variant: :slate, size: :sm) { text }
  end

  private

  def detail_field(label, value = nil, &block)
    div(class: "space-y-2") do
      span(class: "text-[10px] font-bold uppercase tracking-[0.2em] text-slate-500") { label }
      if block
        yield
      else
        p(class: "text-slate-200 font-medium text-lg") { value }
      end
    end
  end

  def initials
    (@user.name.presence || @user.email_address).first.upcase
  end
end
