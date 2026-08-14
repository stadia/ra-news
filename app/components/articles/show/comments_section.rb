# typed: true
# frozen_string_literal: true

# 기사 상세 하단의 댓글 헤더 + 작성 폼 + 목록.
class Components::Articles::Show::CommentsSection < Components::Base
  def initialize(article:, comments:, comment:)
    @article = article
    @comments = comments
    @comment = comment
  end

  def view_template
    render RubyUI::Card.new(class: "bg-surface overflow-hidden border-border-strong") do
      render RubyUI::CardContent.new(class: "p-4 md:p-6 lg:p-8") do
        render RubyUI::Heading.new(
          level: 2,
          class: "font-bold text-content mb-6 flex items-center",
          id: "comments_header"
        ) { render(Components::Comments::CommentHeader.new(comments: @comments)) }

        render RubyUI::Separator.new(class: "mb-4")
        div(id: "comment_form") do
          render(Components::Comments::CommentForm.new(article: @article, comment: @comment))
        end

        div(class: "space-y-4 pt-6") do
          render(Components::Comments::Comments.new(article: @article, comments: @comments))
        end
      end
    end
  end
end
