# frozen_string_literal: true

class Components::Mailers::Layout < Components::Base
  def initialize(title:, intro: nil, eyebrow: nil)
    @title = title
    @intro = intro
    @eyebrow = eyebrow
  end

  def view_template(&)
    html do
      head do
        meta(charset: "utf-8")
        meta(name: "viewport", content: "width=device-width, initial-scale=1.0")
      end
      body(style: body_shell_style) do
        table(role: "presentation", cellpadding: "0", cellspacing: "0", width: "100%", style: outer_table_style) do
          tr do
            td(align: "center", style: frame_cell_style) do
              table(role: "presentation", cellpadding: "0", cellspacing: "0", width: "100%", style: card_style) do
                tr do
                  td(style: header_style) do
                    div(style: brand_wrap_style) do
                      span(style: brand_style) { "Ruby-News" }
                      span(style: brand_divider_style) { "||" }
                      span(style: brand_subtitle_style) { "루비 AI 뉴스" }
                    end
                  end
                end
                tr do
                  td(style: content_style) do
                    if @eyebrow.present?
                      span(style: eyebrow_style) { @eyebrow }
                    end
                    h1(style: title_style) { @title }
                    p(style: intro_style) { @intro } if @intro.present?
                    div(style: body_style, &) if block_given?
                  end
                end
                tr do
                  td(style: footer_wrap_style) do
                    p(style: footer_style) { "이 메일은 계정 확인을 위해 발송되었습니다." }
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

  def body_shell_style
    "margin:0;padding:0;background-color:#1b2330;"
  end

  def outer_table_style
    "width:100%;border-collapse:collapse;background-color:#1b2330;"
  end

  def frame_cell_style
    "padding:32px 16px;"
  end

  def card_style
    "max-width:600px;margin:0 auto;border-collapse:separate;background-color:#243041;border:1px solid #334155;border-radius:20px;overflow:hidden;box-shadow:0 24px 60px rgba(0,0,0,0.28);"
  end

  def header_style
    "padding:24px 28px;background-color:#111827;border-top:3px solid rgb(34, 197, 94);"
  end

  def brand_wrap_style
    "font-size:0;line-height:1;"
  end

  def brand_style
    "display:inline-block;font-size:24px;line-height:1.1;font-weight:800;color:rgb(34, 197, 94);"
  end

  def brand_divider_style
    "display:inline-block;margin:0 10px;font-size:18px;line-height:1;color:#64748b;"
  end

  def brand_subtitle_style
    "display:inline-block;font-size:16px;line-height:1.2;font-weight:600;color:#e5e7eb;"
  end

  def content_style
    "padding:32px 28px 24px;background-color:#1e293b;"
  end

  def eyebrow_style
    "display:inline-block;margin:0 0 20px;padding:6px 12px;border-radius:999px;background-color:#334155;border:1px solid rgba(148,163,184,0.18);font-size:11px;line-height:1.2;font-weight:700;letter-spacing:0.16em;text-transform:uppercase;color:rgb(74, 222, 128);"
  end

  def title_style
    "margin:0 0 14px;font-size:34px;line-height:1.18;font-weight:800;color:#f8fafc;"
  end

  def intro_style
    "margin:0 0 24px;font-size:17px;line-height:1.7;color:#cbd5e1;"
  end

  def body_style
    "font-size:15px;line-height:1.7;color:#f8fafc;"
  end

  def footer_wrap_style
    "padding:0 28px 28px;background-color:#111827;"
  end

  def footer_style
    "margin:0;padding-top:18px;border-top:1px solid rgba(148,163,184,0.18);font-size:12px;line-height:1.7;color:#94a3b8;text-align:center;"
  end
end
