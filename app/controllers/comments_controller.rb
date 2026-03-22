class CommentsController < ApplicationController
  include RateLimiting

  before_action :check_rate_limit, only: %i[ create ]
  before_action :set_comment, only: %i[ destroy ]
  before_action :set_article, only: %i[ create ]
  before_action :require_authentication, only: %i[ create destroy ]

  # POST /comments
  def create
    @comment = @article.comments.build(comment_params)
    @comment.user = Current.user

    respond_to do |format|
      if @comment.save
        load_comments
        format.html { redirect_to @article, notice: "댓글이 성공적으로 작성되었습니다." }
        format.turbo_stream
      else
        load_comments
        format.html { redirect_to @article, alert: "댓글 작성에 실패했습니다." }
        format.turbo_stream { render :create, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  def destroy
    @article = @comment.article

    if @comment.user == Current.user
      @comment.destroy
      load_comments
      respond_to do |format|
        format.html { redirect_to @article, notice: "댓글이 삭제되었습니다." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @article, alert: "권한이 없습니다." }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("comment_#{@comment.id}", partial: "comments/comment", locals: { comment: @comment }), status: :unauthorized }
      end
    end
  end

  private

    def set_article
      @article = Article.kept.find_by_slug(params.expect(:article_id)) || Article.kept.find_by(id: params.expect(:article_id))
      raise ActiveRecord::RecordNotFound if @article.nil?
    end

    def set_comment
      @comment = Comment.find(params.expect(:id))
    end

    def load_comments
      @comments = @article.comments.includes(:user)
    end

    def comment_params
      params.expect(comment: [ :body, :parent_id ])
    end
end
