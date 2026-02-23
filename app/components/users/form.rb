# frozen_string_literal: true

class Components::Users::Form < Components::Base
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::Pluralize
  include Phlex::Rails::Helpers::DOMID

  def initialize(user:)
    @user = user
  end

  def view_template
    form_with(model: @user, class: "contents", url: users_path, method: @user.persisted? ? :put : :post) do |form|
      div(class: "w-full max-w-2xl bg-slate-900/40 border border-slate-800 rounded-2xl overflow-hidden shadow-2xl my-6") do
        # Decorative Header
        div(class: "h-24 bg-gradient-to-r from-slate-800 to-slate-700/50 border-b border-slate-800")

        div(class: "px-6 pb-8 sm:px-10 sm:pb-10") do
          # Avatar & Primary Identity Section (Visual only)
          div(class: "flex flex-col sm:flex-row items-center sm:items-end gap-6 -mt-12 mb-10") do
            render RubyUI::Avatar.new(size: :xl, class: "h-24 w-24 ring-4 ring-slate-900 bg-slate-900 shadow-xl") do
              render RubyUI::AvatarFallback.new(class: "bg-green-600 text-white text-3xl font-bold") do
                initials
              end
            end

            div(class: "text-center sm:text-left pb-1 flex-1") do
              h2(class: "text-3xl font-bold text-white tracking-tight") { @user.persisted? ? "정보 수정" : "회원 가입" }
              p(class: "text-slate-400 font-medium text-lg mt-1") { @user.email_address_was || "새로운 시작" }
            end
          end

          # Error Messages
          if @user.errors.any?
            div(id: "error_explanation", class: "mb-8 p-4 bg-red-500/10 border border-red-500/20 rounded-xl text-red-400") do
              h2(class: "font-bold mb-2 flex items-center gap-2") do
                svg(xmlns: "http://www.w3.org/2000/svg", width: "18", height: "18", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round", stroke_linejoin: "round") do |s|
                  s.circle(cx: "12", cy: "12", r: "10")
                  s.line(x1: "12", y1: "8", x2: "12", y2: "12")
                  s.line(x1: "12", y1: "16", x2: "12.01", y2: "16")
                end
                plain pluralize(@user.errors.count, "error") + " prohibited this user from being saved:"
              end
              ul(class: "list-disc ml-6 space-y-1 text-sm") do
                @user.errors.each { |error| li { error.full_message } }
              end
            end
          end

          # Form Fields Grid
          div(class: "grid grid-cols-1 md:grid-cols-2 gap-x-12 gap-y-8 pt-8 border-t border-slate-800/60") do
            form_field(form, :email_address, "이메일 주소") { form.email_field :email_address, class: input_classes(@user.errors[:email_address]) }
            form_field(form, :name, "사용자 이름") { form.text_field :name, class: input_classes(@user.errors[:name]) }
            form_field(form, :password, "비밀번호") { form.password_field :password, class: input_classes(@user.errors[:password]), placeholder: "••••••••" }
            form_field(form, :password_confirmation, "비밀번호 확인") { form.password_field :password_confirmation, class: input_classes(@user.errors[:password_confirmation]), placeholder: "••••••••" }
          end

          # Submit Button
          div(class: "mt-10 pt-8 border-t border-slate-800/60 flex justify-end") do
            render RubyUI::Button.new(
              type: "submit",
              class: "group relative flex items-center justify-center gap-2 py-3 px-8 rounded-xl bg-green-600 hover:bg-green-500 text-white font-bold text-lg transition-all active:scale-95 shadow-lg shadow-green-900/20"
            ) do
              plain @user.persisted? ? "변경사항 저장" : "가입하기"
              svg(xmlns: "http://www.w3.org/2000/svg", width: "20", height: "20", viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.5", stroke_linecap: "round", stroke_linejoin: "round", class: "transition-transform group-hover:translate-x-1") do |s|
                s.path(d: "M5 12h14")
                s.path(d: "m12 5 7 7-7 7")
              end
            end
          end
        end
      end
    end
  end

  private

  def form_field(form, attribute, label, &block)
    div(class: "space-y-2") do
      form.label attribute, class: "text-[10px] font-bold uppercase tracking-[0.2em] text-slate-500" do
        plain label
      end
      yield
    end
  end

  def input_classes(errors)
    base_classes = "block w-full bg-slate-800/50 border rounded-xl px-4 py-3 text-slate-100 placeholder-slate-500 focus:outline-none focus:ring-2 transition-all duration-200"
    error_classes = errors.any? ? "border-red-500/50 focus:ring-red-500/30" : "border-slate-700 focus:ring-green-500/30 focus:border-green-500/50"
    "#{base_classes} #{error_classes}"
  end

  def initials
    (@user.name.presence || @user.email_address.presence || "U").first.upcase
  end
end
