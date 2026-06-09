# frozen_string_literal: true

class Components::Posts::LongformEditor < Components::Base
  include Phlex::Rails::Helpers::FormWith

  def initialize(post:)
    @post = post
  end

  def view_template
    form_with(model: @post, url: form_url, method: form_method, class: "space-y-5", data: form_data) do |f|
      # New (unsaved) drafts POST to #create; this hidden field lets the autosave
      # controller flip the form to PATCH #update once the draft is persisted.
      input(type: "hidden", name: "_method", value: "post", data: { longform_autosave_target: "methodField" }) unless @post.persisted?

      error_summary
      header
      title_field(f)
      body_field(f)
      footer
    end
  end

  private

  def form_url
    @post.persisted? ? view_context.longform_post_path(@post) : view_context.longform_posts_path
  end

  def form_method
    @post.persisted? ? :patch : :post
  end

  def save_url
    if @post.persisted?
      view_context.longform_post_path(@post, format: :json)
    else
      view_context.longform_posts_path(format: :json)
    end
  end

  def form_data
    {
      controller: "longform-autosave",
      action: "submit->longform-autosave#stop",
      longform_autosave_persisted_value: @post.persisted?,
      longform_autosave_initial_dirty_value: !@post.persisted? && @post.body.present?,
      longform_autosave_save_url_value: save_url,
      longform_autosave_pending_text_value: t("posts.longform.autosave_pending"),
      longform_autosave_saving_text_value: t("posts.longform.autosave_saving"),
      longform_autosave_saved_text_value: t("posts.longform.autosave_saved"),
      longform_autosave_failed_text_value: t("posts.longform.autosave_failed")
    }
  end

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
        publish_button
      end
    end
  end

  def publish_button
    if @post.persisted?
      # formmethod: :post issues a real POST; the _method=patch field then overrides
      # it so the request reaches the `patch :publish` member route.
      render RubyUI::Button.new(
        type: :submit,
        formaction: view_context.publish_longform_post_path(@post),
        formmethod: :post,
        name: "_method",
        value: "patch",
        data: { longform_autosave_target: "publishButton" },
        class: "bg-brand-solid hover:bg-brand-solid-hover text-brand-foreground"
      ) { t("posts.longform.publish") }
    else
      # Unsaved draft: submit to #create with a publish flag so the row is
      # created and published in one request. Once autosave persists the draft,
      # the autosave controller rewires this button to the publish route.
      render RubyUI::Button.new(
        type: :submit,
        formaction: view_context.longform_posts_path,
        formmethod: :post,
        name: "publish",
        value: "1",
        data: { longform_autosave_target: "publishButton" },
        class: "bg-brand-solid hover:bg-brand-solid-hover text-brand-foreground"
      ) { t("posts.longform.publish") }
    end
  end

  def title_field(f)
    f.text_field(
      :title,
      class: "w-full bg-transparent border-0 border-b border-border-muted text-3xl font-bold text-content placeholder:text-content-muted focus:ring-0 focus:border-brand",
      placeholder: t("posts.longform.title_placeholder"),
      data: { action: "input->longform-autosave#markDirty" }
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
          action: "lexxy:change->longform-autosave#markDirty input->longform-autosave#markDirty"
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
