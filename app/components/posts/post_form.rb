# frozen_string_literal: true

class Components::Posts::PostForm < Components::Base
  include Phlex::Rails::Helpers::FormWith
  include PhlexIcons

  def initialize(post: Post.new)
    @post = post
  end

  def view_template
    div(
      id: "post_form",
      class: "mb-6",
      data: {
        controller: "character-counter post-form",
        character_counter_max_length_value: ::Post::MAX_BODY_LENGTH.to_s,
        action: "turbo:submit-end->post-form#reset post-form:reply@window->post-form#activateReply"
      }
    ) do
      render RubyUI::Card.new(class: "bg-surface border-border-muted shadow-sm") do
        render RubyUI::CardContent.new(class: "p-4 sm:p-5") do
          form_with(
            model: @post,
            url: view_context.posts_path,
            class: "space-y-3",
            autocomplete: "off"
          ) do |f|
            error_messages if @post.errors.any?
            reply_state_banner
            f.hidden_field :parent_id, value: @post.parent_id, data: { post_form_target: "parentId" }
            body_field(f)
            form_footer(f)
          end
        end
      end
    end
  end

  private

  def error_messages
    div(class: "text-sm text-danger-text") do
      @post.errors.full_messages.each { |msg| p { msg } }
    end
  end

  def body_field(f)
    raw(
      f.lexxy_rich_textarea(
        :body,
        class: "post-composer-editor w-full text-content",
        rows: 3,
        toolbar: false,
        placeholder: t("helpers.placeholder.post.body"),
        autocomplete: "off",
        data: {
          post_form_target: "body",
          character_counter_target: "input",
          action: "lexxy:change->character-counter#update lexxy:initialize->character-counter#update"
        }
      )
    )
  end

  def reply_state_banner
    div(class: reply_banner_classes, data: { post_form_target: "replyBanner" }) do
      div(class: "flex items-center justify-between gap-3") do
        p(class: "text-sm text-content-secondary") do
          plain t("posts.post_form.replying_to")
          if reply_target_label.present?
            plain ": "
            span(class: "font-medium text-content", data: { post_form_target: "replyLabel" }) { reply_target_label }
          else
            span(class: "font-medium text-content", data: { post_form_target: "replyLabel" })
          end
        end

        render RubyUI::Button.new(
          type: :button,
          variant: :ghost,
          size: :sm,
          data: { action: "post-form#cancelReply" },
          class: "text-content-muted hover:text-content hover:bg-transparent"
        ) { t("posts.post_form.cancel") }
      end

      p(class: "mt-2 text-sm text-content-muted wrap-break-word", data: { post_form_target: "replyPreview" }) do
        plain reply_preview_text.to_s
      end
    end
  end

  def form_footer(f)
    div(class: "flex items-center justify-between") do
      div(class: "text-xs text-content-muted") do
        span(data: { character_counter_target: "counter" }) { "0" }
        plain "/#{::Post::MAX_BODY_LENGTH}"
      end
      div(class: "flex items-center gap-2") do
        # Opens the blog editor carrying the in-progress body. POSTs to #new so
        # the body travels in the request body (not the URL); #new stashes it and
        # redirects to the GET editor, which Turbo renders. The draft row is
        # created lazily on first autosave — switching to blog from an empty
        # composer never persists an empty draft.
        render RubyUI::Button.new(
          type: :submit,
          formaction: view_context.new_blog_post_path,
          formmethod: :post,
          variant: :secondary,
          class: "text-content-secondary"
        ) { t("posts.post_form.blog") }
        f.submit submit_label,
          class: "inline-flex items-center px-5 py-2 bg-info-solid hover:bg-info-solid-hover text-brand-foreground text-sm font-medium rounded-lg transition-colors duration-200 cursor-pointer"
      end
    end
  end

  def reply_banner_classes
    classes = [ "hidden rounded-lg border border-border-muted bg-surface-muted px-3 py-2" ]
    classes.delete("hidden") if @post.parent_id.present?
    classes.join(" ")
  end

  def submit_label
    @post.parent_id.present? ? t("posts.post_form.reply_submit") : t("posts.post_form.post_submit")
  end

  def reply_target_label
    return unless parent_post.present?

    parent_post.user&.name || parent_post.federails_actor&.name || parent_post.author_name
  end

  def reply_preview_text
    return unless parent_post.present?

    view_context.truncate(view_context.strip_tags(parent_post.body.to_s).squish, length: 120)
  end

  def parent_post
    return @parent_post if defined?(@parent_post)
    return @parent_post = nil if @post.parent_id.blank?

    @parent_post = Post.includes(:user, :federails_actor).find_by(id: @post.parent_id)
  end
end
