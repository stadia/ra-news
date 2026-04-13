# frozen_string_literal: true

class Components::Layout < Components::Base
  include Phlex::Rails::Layout
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ImageURL

  def view_template
    doctype
    html(lang: I18n.locale, class: "dark") do
      head do
        render_theme_init_script
        render_analytics_scripts
        render_meta_tags
        render_rss_link
        csrf_meta_tags
        csp_meta_tag
        yield(:head)
        render_pwa_and_icons
        render_google_fonts
        stylesheet_link_tag :app, data_turbo_track: "reload"
        stylesheet_link_tag "lexxy", data_turbo_track: "reload"
        javascript_importmap_tags
        render_schema_org
      end

      body(
        class: "bg-app text-content-secondary min-h-screen flex flex-col",
        data: {
          controller: "page-loader",
          action: [
            "turbo:before-visit@window->page-loader#beforeTurboVisit",
            "turbo:load@window->page-loader#afterTurboLoad"
          ].join(" ")
        }
      ) do
        render_skip_link
        render_loading_indicator
        render_navigation
        render_main { yield }
        render_footer
      end
    end
  end

  private

  def render_theme_init_script
    script do
      raw(<<~JS.html_safe)
        (function(){
          var d=document.documentElement;
          if(localStorage.theme==='light'){d.classList.remove('dark');d.classList.add('light')}
        })();
      JS
    end
  end

  def render_analytics_scripts
    script(async: true, src: "https://www.googletagmanager.com/gtag/js?id=G-56PSNXG7QG")
    script do
      raw(<<~JS.html_safe)
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', 'G-56PSNXG7QG');
      JS
    end

    script(type: "text/javascript") do
      raw(<<~JS.html_safe)
        (function(c,l,a,r,i,t,y){
            c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
            t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;
            y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);
        })(window, document, "clarity", "script", "u4rt68vefo");
      JS
    end
  end

  def render_meta_tags
    meta(name: "viewport", content: "width=device-width,initial-scale=1,viewport-fit=cover")
    meta(name: "apple-mobile-web-app-capable", content: "yes")
    meta(name: "mobile-web-app-capable", content: "yes")
    meta(name: "apple-mobile-web-app-status-bar-style", content: "black-translucent")
    meta(name: "slack-app-id", content: "A0AS9BX8B7U")

    vc = view_context
    vc.set_meta_tags canonical: "https://ruby-news.kr#{vc.request.path}"
    page_title = content_for(:title).presence || "Ruby-News | 루비 AI 뉴스"
    page_desc = vc.instance_variable_get(:@page_description) || "최신 Ruby, Rails 관련 뉴스와 트렌드를 한곳에서 만나보세요"

    raw vc.display_meta_tags(
      title: page_title,
      description: page_desc,
      og: {
        title: page_title,
        description: page_desc,
        site_name: "Ruby-News | 루비 AI 뉴스",
        image: image_url("og_main.png"),
        type: vc.instance_variable_get(:@og_type) || "website",
        url: "https://ruby-news.kr#{vc.request.path}",
        locale: "ko_KR"
      },
      article: vc.instance_variable_get(:@og_article),
      twitter: {
        card: "summary_large_image",
        site: "@rubynewskr",
        title: page_title,
        description: page_desc,
        image: image_url("og_main.png")
      }
    )
  end

  def render_rss_link
    link(
      rel: "alternate",
      type: "application/rss+xml",
      title: "Ruby-News RSS 피드",
      href: "/rss"
    )
  end

  def render_pwa_and_icons
    link(rel: "manifest", href: pwa_manifest_path(format: :json))
    link(rel: "icon", href: "/icon.png", type: "image/png")
    link(rel: "icon", href: "/icon.svg", type: "image/svg+xml")
    link(rel: "apple-touch-icon", href: "/apple-touch-icon.png")
  end

  def render_google_fonts
    link(rel: "preconnect", href: "https://fonts.googleapis.com")
    link(rel: "preconnect", href: "https://fonts.gstatic.com", crossorigin: true)
    link(
      rel: "preload",
      href: "https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700&display=swap",
      as: "style"
    )
    link(
      rel: "stylesheet",
      href: "https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700&display=swap"
    )
  end

  def render_schema_org
    vc = view_context
    web_site = vc.instance_variable_get(:@web_site)
    news_media = vc.instance_variable_get(:@news_media_organization)
    raw(web_site.to_s) if web_site
    raw(news_media.to_s) if news_media
  end

  def render_skip_link
    a(
      href: "#main-content",
      class: "sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:px-4 focus:py-2 focus:bg-brand-solid focus:text-brand-foreground focus:rounded-lg focus:shadow-lg"
    ) { "본문으로 건너뛰기" }
  end

  def render_loading_indicator
    div(
      data: { page_loader_target: "loader" },
      class: "fixed inset-0 bg-app/75 z-50 hidden items-center justify-center"
    ) do
      div(class: "flex flex-col items-center space-y-4") do
        div(class: "animate-spin rounded-full h-12 w-12 border-4 border-brand border-t-transparent shadow-lg shadow-brand/50")
        div(class: "text-content font-medium") { "로딩 중..." }
      end
    end
  end

  def render_navigation
    nav(
      class: "bg-surface border-b border-border-strong border-t-4 border-t-brand",
      aria_label: "주 네비게이션"
    ) do
      div(class: "max-w-[1400px] flex flex-wrap md:flex-nowrap items-center justify-between mx-auto p-4") do
        link_to root_path, class: "flex items-center space-x-3 rtl:space-x-reverse group" do
          span(class: "self-center text-2xl font-semibold whitespace-nowrap text-content group-hover:text-link-hover transition-colors duration-200") do
            plain "Ruby-News || "
            span(class: "text-accent-text") { "루비 AI 뉴스" }
          end
        end

        render_mobile_menu_toggle
        render_nav_menu
      end
    end
  end

  def render_mobile_menu_toggle
    input(type: "checkbox", id: "mobile-menu-toggle", class: "mobile-menu-toggle peer")
    label(
      for: "mobile-menu-toggle",
      class: "inline-flex items-center p-2 w-11 h-11 justify-center text-sm text-content rounded-lg md:hidden hover:bg-surface-muted focus:outline-none focus:ring-2 focus:ring-brand focus:ring-offset-2 focus:ring-offset-surface cursor-pointer",
      aria_label: "메뉴 열기/닫기"
    ) do
      span(class: "sr-only") { "Open main menu" }
      render PhlexIcons::Hero::Bars3.new(variant: :outline, class: "w-5 h-5")
    end
  end

  def render_nav_menu
    vc = view_context
    div(
      class: "items-center justify-between w-full md:flex md:w-auto md:order-1 hidden peer-checked:block transition-all duration-300 ease-in-out md:transition-none",
      id: "navbar-search"
    ) do
      ul(class: "flex flex-col p-4 md:p-0 mt-4 font-medium border border-border-strong rounded-lg bg-surface-muted md:space-x-8 rtl:space-x-reverse md:flex-row md:mt-0 md:border-0 md:bg-surface animate-in slide-in-from-top-2 fade-in duration-200 md:animate-none") do
        li { raw vc.nav_link_to("홈", root_path) }
        li { raw vc.nav_link_to("지난 글", articles_path) }
        li { raw vc.nav_link_to("그 밖의 뉴스", others_path) }
        li(class: "flex items-center") { render_search_form }

        if vc.user_signed_in?
          li { raw vc.nav_link_to("글 등록", new_article_path) }
          li { raw vc.nav_link_to(vc.current_user.username ||vc.current_user.name, user_profile_path(vc.current_user)) }
        end

        li do
          if vc.user_signed_in?
            raw vc.nav_link_to("로그아웃", destroy_user_session_path)
          else
            raw vc.nav_link_to("로그인", new_user_session_path)
          end
        end

        li(class: "flex items-center") do
          ThemeToggle do |toggle|
            SetLightMode do
              Button(variant: :ghost, icon: true) do
                svg(
                  xmlns: "http://www.w3.org/2000/svg",
                  viewbox: "0 0 24 24",
                  fill: "currentColor",
                  class: "w-4 h-4"
                ) do |s|
                  s.path(
                    d:
                      "M12 2.25a.75.75 0 01.75.75v2.25a.75.75 0 01-1.5 0V3a.75.75 0 01.75-.75zM7.5 12a4.5 4.5 0 119 0 4.5 4.5 0 01-9 0zM18.894 6.166a.75.75 0 00-1.06-1.06l-1.591 1.59a.75.75 0 101.06 1.061l1.591-1.59zM21.75 12a.75.75 0 01-.75.75h-2.25a.75.75 0 010-1.5H21a.75.75 0 01.75.75zM17.834 18.894a.75.75 0 001.06-1.06l-1.59-1.591a.75.75 0 10-1.061 1.06l1.59 1.591zM12 18a.75.75 0 01.75.75V21a.75.75 0 01-1.5 0v-2.25A.75.75 0 0112 18zM7.758 17.303a.75.75 0 00-1.061-1.06l-1.591 1.59a.75.75 0 001.06 1.061l1.591-1.59zM6 12a.75.75 0 01-.75.75H3a.75.75 0 010-1.5h2.25A.75.75 0 016 12zM6.697 7.757a.75.75 0 001.06-1.06l-1.59-1.591a.75.75 0 00-1.061 1.06l1.59 1.591z"
                  )
                end
              end
            end
            SetDarkMode do
              Button(variant: :ghost, icon: true) do
                svg(
                  xmlns: "http://www.w3.org/2000/svg",
                  viewbox: "0 0 24 24",
                  fill: "currentColor",
                  class: "w-4 h-4"
                ) do |s|
                  s.path(
                    fill_rule: "evenodd",
                    d:
                      "M9.528 1.718a.75.75 0 01.162.819A8.97 8.97 0 009 6a9 9 0 009 9 8.97 8.97 0 003.463-.69.75.75 0 01.981.98 10.503 10.503 0 01-9.694 6.46c-5.799 0-10.5-4.701-10.5-10.5 0-4.368 2.667-8.112 6.46-9.694a.75.75 0 01.818.162z",
                    clip_rule: "evenodd"
                  )
                end
              end
            end
          end
        end
      end
    end
  end

  def render_search_form
    form_with(
      url: articles_path,
      method: :get,
      local: true,
      html: {
        role: "search",
        aria_label: "기사 검색",
        class: "flex items-center space-x-2"
      }
    ) do |form|
      raw form.text_field(
        :search,
        placeholder: "검색...",
        value: view_context.params[:search],
        class: "px-3 py-2 text-sm text-content bg-surface-muted border border-border-muted rounded-lg focus:outline-none focus:ring-2 focus:ring-brand focus:border-transparent w-40 md:w-48 transition-all duration-200 placeholder:text-content-muted"
      )
      render Button.new(
        type: "submit",
        variant: :primary,
        size: :lg,
        class: "font-medium bg-brand-solid rounded-lg border border-brand-solid hover:bg-brand-solid-hover text-brand-foreground focus:ring-2 focus:outline-none focus:ring-brand focus:ring-offset-2 focus:ring-offset-surface transition-all duration-150 min-h-11 cursor-pointer"
      ) { "검색" }
    end
  end

  def render_main
    vc = view_context
    main(id: "main-content", class: "container mx-auto px-4 py-8 grow") do
      if vc.user_signed_in? && WebPushConfig.configured?
        div(
          data: {
            controller: "push-notifications",
            push_notifications_public_key_value: WebPushConfig.public_key,
            push_notifications_subscription_url_value: push_subscription_path,
            push_notifications_service_worker_path_value: pwa_service_worker_path(format: :js),
            push_notifications_cooldown_hours_value: "1"
          }
        ) do
          render Components::PushNotifications::PromptModal.new
        end
      end

      render Components::Flash.new
      yield
    end
  end

  def render_footer
    footer(class: "bg-surface text-content-secondary rounded-lg shadow-sm m-4 border border-border-strong border-t-2 border-t-brand") do
      div(class: "w-full mx-auto max-w-7xl p-4 md:flex md:items-center md:justify-between") do
        span(class: "text-sm text-content-secondary sm:text-center") do
          plain "© 2025 "
          a(
            href: "https://ruby-news.kr/",
            class: "hover:underline hover:text-content transition-colors duration-200"
          ) { "Ruby-News || 루비 AI 뉴스" }
          plain ". All Rights Reserved."
        end

        ul(class: "flex flex-wrap items-center mt-3 text-sm font-medium text-content-secondary sm:mt-0 gap-4") do
          li { render_mastodon_link }
          li { render_twitter_link }
          li { render_slack_link }
          li { render_rss_footer_link }
        end
      end
    end
  end

  def render_mastodon_link
    a(
      rel: "me",
      href: "https://ruby.social/@news_kr",
      target: "_blank",
      class: "hover:underline hover:text-content flex items-center gap-1"
    ) do
      svg(class: "w-5 h-5", fill: "currentColor", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg") do |s|
        s.path(
          d: "M23.268 5.313c-.35-2.578-2.617-4.61-5.304-5.004C17.51.242 15.792 0 11.813 0h-.03c-3.98 0-4.835.242-5.288.309C3.882.692 1.496 2.518.917 5.127.64 6.412.61 7.837.661 9.143c.074 1.874.088 3.745.26 5.611.118 1.24.325 2.47.62 3.68.55 2.237 2.777 4.098 4.96 4.857 2.336.792 4.849.923 7.256.38.265-.061.527-.132.786-.213.585-.184 1.27-.39 1.774-.753a.057.057 0 0 0 .023-.043v-1.809a.052.052 0 0 0-.02-.041.053.053 0 0 0-.046-.01 20.282 20.282 0 0 1-4.709.545c-2.73 0-3.463-1.284-3.674-1.818a5.593 5.593 0 0 1-.319-1.433.056.056 0 0 1 .017-.043.051.051 0 0 1 .043-.017c1.513.359 3.072.538 4.657.546 1.828 0 2.298-.081 3.09-.143 1.897-.149 3.566-.867 3.772-1.531.334-1.076.61-3.495.61-3.495 0-.732-.005-1.603-.05-2.447-.041-.832-.126-1.62-.333-2.377z"
        )
      end
      plain " Mastodon"
    end
  end

  def render_twitter_link
    a(
      href: "https://x.com/rubynewskr",
      target: "_blank",
      rel: "noopener noreferrer",
      class: "hover:underline hover:text-content flex items-center gap-1"
    ) do
      svg(class: "w-5 h-5", fill: "currentColor", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg") do |s|
        s.path(
          d: "M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"
        )
      end
      plain " Twitter/X"
    end
  end

  def render_rss_footer_link
    a(
      href: rss_path,
      target: "_blank",
      rel: "noopener noreferrer",
      class: "hover:underline hover:text-content flex items-center gap-1"
    ) do
      render PhlexIcons::Hero::Rss.new(variant: :outline, class: "w-5 h-5")
      plain " RSS 피드"
    end
  end

  def render_slack_link
    a(
      href: "https://slack.com/oauth/v2/authorize?client_id=8355153845137.10893405283266&scope=incoming-webhook&user_scope=",
      target: "_blank",
      rel: "noopener noreferrer",
      class: "hover:underline hover:text-content flex items-center gap-1"
    ) do
      svg(class: "w-5 h-5", fill: "currentColor", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg") do |s|
        s.path(
          d: "M5.042 15.165a2.528 2.528 0 0 1-2.52 2.523A2.528 2.528 0 0 1 0 15.165a2.527 2.527 0 0 1 2.522-2.52h2.52v2.52zm1.271 0a2.527 2.527 0 0 1 2.521-2.52 2.527 2.527 0 0 1 2.521 2.52v6.313A2.528 2.528 0 0 1 8.834 24a2.528 2.528 0 0 1-2.521-2.522v-6.313zM8.834 5.042a2.528 2.528 0 0 1-2.521-2.52A2.528 2.528 0 0 1 8.834 0a2.528 2.528 0 0 1 2.521 2.522v2.52H8.834zm0 1.271a2.528 2.528 0 0 1 2.521 2.521 2.528 2.528 0 0 1-2.521 2.521H2.522A2.528 2.528 0 0 1 0 8.834a2.528 2.528 0 0 1 2.522-2.521h6.312zM18.956 8.834a2.528 2.528 0 0 1 2.522-2.521A2.528 2.528 0 0 1 24 8.834a2.528 2.528 0 0 1-2.522 2.521h-2.522V8.834zm-1.27 0a2.528 2.528 0 0 1-2.523 2.521 2.527 2.527 0 0 1-2.52-2.521V2.522A2.527 2.527 0 0 1 15.163 0a2.528 2.528 0 0 1 2.523 2.522v6.312zM15.163 18.956a2.528 2.528 0 0 1 2.523 2.522A2.528 2.528 0 0 1 15.163 24a2.527 2.527 0 0 1-2.52-2.522v-2.522h2.52zm0-1.27a2.527 2.527 0 0 1-2.52-2.523 2.527 2.527 0 0 1 2.52-2.52h6.315A2.528 2.528 0 0 1 24 15.163a2.528 2.528 0 0 1-2.522 2.523h-6.315z"
        )
      end
      plain " Slack 추가"
    end
  end
end
