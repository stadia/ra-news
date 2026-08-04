# typed: false
# rbs_inline: enabled

module ApplicationHelper
  def responsive_image_tag(source, options = {})
    # 반응형 이미지를 위한 헬퍼
    default_options = {
      loading: "lazy",
      class: "w-full h-auto"
    }
    image_tag(source, default_options.merge(options))
  end

  def truncate_smart(text, length: 100)
    return "" unless text

    if text.length <= length
      text
    else
      text.truncate(length, omission: "...")
    end
  end

  # app/helpers/application_helper.rb
  def nav_link_to(text, path, options = { size: :lg, variant: :ghost })
    options[:class] = "block text-content-secondary hover:text-content aria-[current=page]:text-accent-text rounded-sm transition-colors duration-150 min-h-11 items-center hover:bg-transparent"
    options["aria-current".to_sym] = "page" if current_page?(path)
    options[:href] = path
    render RubyUI::Link.new(**options) { text }
  end
end
