module ApplicationHelper
  def time_ago_in_words_korean(time)
    return "알 수 없음" unless time

    seconds = Time.current - time

    case seconds
    when 0..59
      "방금"
    when 60..3599
      "#{(seconds / 60).to_i}분"
    when 3600..86399
      "#{(seconds / 3600).to_i}시간"
    when 86400..2591999
      "#{(seconds / 86400).to_i}일"
    when 2592000..31535999
      "#{(seconds / 2592000).to_i}개월"
    else
      "#{(seconds / 31536000).to_i}년"
    end
  end

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
  def nav_link_to(text, path, options = {})
    options[:class] = "nav-link block py-3 px-4 text-gray-100 hover:text-white rounded-sm md:hover:text-white md:p-0 transition-colors duration-150 min-h-[44px] flex items-center".html_safe
    options[:"aria-current"] = "page" if current_page?(path)
    link_to(text, path, options)
  end
end
