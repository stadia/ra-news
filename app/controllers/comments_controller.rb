class CommentsController < ApplicationController
  before_action :set_comment, only: %i[ destroy ]
  before_action :set_article, only: %i[ create ]

  # POST /comments
  def create
    @comment = @article.comments.build(comment_params)
    @comment.user = Current.user

    respond_to do |format|
      if @comment.save
        format.html { redirect_to @article, notice: "댓글이 성공적으로 작성되었습니다." }
        format.turbo_stream
      else
        @comments = @article.comments.includes(:user).order(created_at: :desc)
        format.html { redirect_to @article, alert: "댓글 작성에 실패했습니다." }
      end
    end
  end

  # DELETE /comments/1
  def destroy
    @article = @comment.article
    @comment.destroy

    respond_to do |format|
      format.html { redirect_to @article, notice: "댓글이 삭제되었습니다." }
      format.turbo_stream
    end
  end

  private

    def set_article
      @article = Article.kept.find_by!(slug: params.expect(:article_id))
    end

    def set_comment
      @comment = Comment.find(params.expect(:id))
    end

    def comment_params
      params.expect(comment: [ :body ])
    end
end
