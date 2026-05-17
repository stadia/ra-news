# frozen_string_literal: true
# rbs_inline: enabled

class ArticleDecorator < ApplicationDecorator
  delegate_all

  # ── Locale-aware display accessors ──────────────────────────────────
  # Returns the best available title for the current locale.
  # :ja → title_ja > title_ko > title
  # :ko (default) → title_ko > title

  #: (Symbol? locale) -> String
  def display_title(locale: I18n.locale)
    case locale
    when :ja then object.title_ja.presence || object.title_ko.presence || object.title
    else              object.title_ko.presence || object.title
    end
  end

  #: (Symbol? locale) -> Array?
  def display_summary_key(locale: I18n.locale)
    case locale
    when :ja then object.summary_key_ja.presence || object.summary_key
    else              object.summary_key
    end
  end

  #: (Symbol? locale) -> Hash?
  def display_summary_detail(locale: I18n.locale)
    case locale
    when :ja then object.summary_detail_ja.presence || object.summary_detail
    else              object.summary_detail
    end
  end

  #: (Symbol? locale) -> String?
  def display_summary_body(locale: I18n.locale)
    case locale
    when :ja then object.summary_body_ja.presence || object.summary_body
    else              object.summary_body
    end
  end

  # Whether to show the original (source) title below the display title.
  #: (Symbol? locale) -> bool
  def show_original_title?(locale: I18n.locale)
    case locale
    when :ja then object.title_ja.present? && object.title_ja != display_title(locale: locale)
    else              object.title_ko.present? && object.title_ko != object.title
    end
  end
end