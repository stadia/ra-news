# frozen_string_literal: true

class Components::Posts::LongformEditor < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(post:)
    @post = post
  end

  def view_template
    form_with(
      model: @post,
      url: view_context.longform_post_path(@post),
      method: :patch,
      class: "space-y-5",
      data: {
        controller: "longform-autosave",
        action: "submit->longform-autosave#cancelPending",
        longform_autosave_url_value: view_context.longform_post_path(@post, format: :json),
        longform_autosave_pending_text_value: t("posts.longform.autosave_pending"),
        longform_autosave_saving_text_value: t("posts.longform.autosave_saving"),
        longform_autosave_saved_text_value: t("posts.longform.autosave_saved"),
        longform_autosave_failed_text_value: t("posts.longform.autosave_failed")
      }
    ) do |f|
      error_summary
      header
      title_field(f)
      body_field(f)
      footer
    end
  end

  private

  def error_summary
    return unless @post.errors.any?

    div(class: "rounded-lg border border-danger-solid/20 bg-danger-solid/10 p-4 text-sm text-danger-text") do
      ul(class: "list-disc list-inside space-y-1") do
        @post.errors.full_messages.each { |msg| li { msg } }
      end
    end
  end

  def header
    div(class: "flex items-center justify-between gap-3") do
      p(class: "text-sm text-content-muted", data: { longform_autosave_target: "status" }) do
        t("posts.longform.autosave_idle")
      end

      div(class: "flex items-center gap-2") do
        render RubyUI::Button.new(type: :submit, variant: :secondary) { t("posts.longform.preview") }
        # formmethod: :post issues a real POST; the _method=patch field then overrides
        # it so the request reaches the `patch :publish` member route.
        render RubyUI::Button.new(
          type: :submit,
          formaction: view_context.publish_longform_post_path(@post),
          formmethod: :post,
          name: "_method",
          value: "patch",
          class: "bg-brand-solid hover:bg-brand-solid-hover text-brand-foreground"
        ) { t("posts.longform.publish") }
      end
    end
  end

  def title_field(f)
    f.text_field(
      :title,
      class: "w-full bg-transparent border-0 border-b border-border-muted text-3xl font-bold text-content placeholder:text-content-muted focus:ring-0 focus:border-brand",
      placeholder: t("posts.longform.title_placeholder"),
      data: { action: "input->longform-autosave#schedule" }
    )
  end

  def body_field(f)
    raw(
      f.lexxy_rich_textarea(
        :body,
        class: "post-composer-editor w-full min-h-[520px] text-content",
        rows: 18,
        toolbar: true,
        placeholder: t("posts.longform.body_placeholder"),
        autocomplete: "off",
        data: {
          action: "lexxy:change->longform-autosave#schedule input->longform-autosave#schedule"
        }
      )
    )
  end

  def footer
    div(class: "flex flex-wrap items-center justify-between gap-3 border-t border-border-subtle pt-4 text-sm text-content-muted") do
      span { @post.tag_list.any? ? @post.tag_list.join(", ") : t("posts.longform.no_tags") }
      span { @post.published? ? t("posts.longform.status_published") : t("posts.longform.status_draft") }
    end
  end
end
