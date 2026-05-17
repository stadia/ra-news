# frozen_string_literal: true
# rbs_inline: enabled

# Locale-aware display accessors for Article.
# Returns the best available field for the current locale, with fallback.
#
# Usage:
#   article.display_title              # => title_ko (default locale)
#   article.display_title(locale: :ja) # => title_ja > title_ko > title
module LocalizedDisplay
  extend ActiveSupport::Concern

  #: (Symbol? locale) -> String
  def display_title(locale: I18n.locale)
    case locale
    when :ja then title_ja.presence || title_ko.presence || title
    else              title_ko.presence || title
    end
  end

  #: (Symbol? locale) -> Array?
  def display_summary_key(locale: I18n.locale)
    case locale
    when :ja then summary_key_ja.presence || summary_key
    else              summary_key
    end
  end

  #: (Symbol? locale) -> Hash?
  def display_summary_detail(locale: I18n.locale)
    case locale
    when :ja then summary_detail_ja.presence || summary_detail
    else              summary_detail
    end
  end

  #: (Symbol? locale) -> String?
  def display_summary_body(locale: I18n.locale)
    case locale
    when :ja then summary_body_ja.presence || summary_body
    else              summary_body
    end
  end

  # Whether to show the original (source) title below the display title.
  # :ja — true when title_ja exists and differs from what display_title returns
  # :ko — true when title_ko exists and differs from the raw title
  #: (Symbol? locale) -> bool
  def show_original_title?(locale: I18n.locale)
    case locale
    when :ja then title_ja.present? && title_ja != display_title(locale: locale)
    else              title_ko.present? && title_ko != title
    end
  end

  # First item of summary_key, or the whole string if it's a String.
  # Commonly used in card previews and meta descriptions.
  #: (Symbol? locale) -> String?
  def summary_key_preview(locale: I18n.locale)
    key = display_summary_key(locale: locale)
    case key
    when Array then key.first
    when String then key
    end
  end
end