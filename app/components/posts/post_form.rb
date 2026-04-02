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
        controller: "character-count post-form",
        character_count_max_length_value: ::Post::MAX_BODY_LENGTH.to_s,
        action: "turbo:submit-end->post-form#reset"
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
        placeholder: "무슨 생각을 하고 계신가요?",
        autocomplete: "off",
        data: {
          character_count_target: "input",
          action: "lexxy:change->character-count#updateCount lexxy:initialize->character-count#updateCount"
        }
      )
    )
  end

  def form_footer(f)
    div(class: "flex items-center justify-between") do
      div(class: "text-xs text-content-muted") do
        span(data: { character_count_target: "counter" }) { "0" }
        plain "/#{::Post::MAX_BODY_LENGTH}"
      end
      f.submit "게시",
        class: "inline-flex items-center px-5 py-2 bg-info-solid hover:bg-info-solid-hover text-brand-foreground text-sm font-medium rounded-lg transition-colors duration-200 cursor-pointer"
    end
  end
end
