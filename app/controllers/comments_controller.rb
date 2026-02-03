class CommentsController < ApplicationController
  include RateLimiting

  before_action :check_rate_limit, only: %i[ create ]
  before_action :set_comment, only: %i[ destroy verify_password ]
  before_action :set_article, only: %i[ create ]

  allow_unauthenticated_access only: %i[ create verify_password ]

  # POST /comments
  def create
    @comment = @article.comments.build(comment_params)

    # Assign user if authenticated, otherwise handle as guest
    if authenticated?
      @comment.user = Current.user
    else
      # Guest comment - process name_or_email field
      @comment.user = nil
      name_or_email = params[:comment][:guest_name]
      if name_or_email.present?
        if name_or_email.match?(URI::MailTo::EMAIL_REGEXP)
          @comment.guest_email = name_or_email
          @comment.guest_name = nil
        else
          @comment.guest_name = name_or_email
          @comment.guest_email = nil
        end
      end
    end

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

  # POST /comments/:id/verify_password
  def verify_password
    @article = @comment.article

    unless @comment.guest?
      # Not a guest comment - use regular authentication
      if authenticated? && @comment.user == Current.user
        @comment.destroy
        load_comments
        respond_to do |format|
          format.turbo_stream { render :destroy }
        end
      else
        render turbo_stream: turbo_stream.replace("delete_comment_modal_#{@comment.id}",
          html: "<div class='text-red-400 text-sm mt-2'>권한이 없습니다.</div>".html_safe
        ), status: :unauthorized
      end
      return
    end

    # Guest comment - verify password
    provided_password = params[:password]

    if @comment.authenticate_guest_password(provided_password)
      @comment.destroy
      load_comments
      respond_to do |format|
        format.turbo_stream { render :destroy }
      end
    else
      render turbo_stream: turbo_stream.replace("delete_comment_modal_#{@comment.id}",
        html: "<div class='text-red-400 text-sm mt-2'>비밀번호가 올바르지 않습니다.</div>".html_safe
      ), status: :unauthorized
    end
  end

  # DELETE /comments/1
  def destroy
    @article = @comment.article

    # Check if this is a guest comment
    if @comment.guest?
      # For guest comments, require password verification
      # This action is not called directly for guest comments
      # Instead, verify_password is used
      respond_to do |format|
        format.html { redirect_to @article, alert: "잘못된 접근입니다." }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("delete_comment_modal_#{@comment.id}",
            html: "<div class='text-red-400 text-sm mt-2'>비밀번호 확인이 필요합니다.</div>".html_safe
          ), status: :unprocessable_entity
        end
      end
      return
    end

    # Regular comment - check ownership
    if authenticated? && @comment.user == Current.user
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
      @comments = @article.comments.includes(:user).order(created_at: :desc)
    end

    def comment_params
      params.expect(comment: [ :body, :guest_email, :guest_name, :guest_password ])
    end
end
